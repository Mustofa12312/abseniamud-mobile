import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../device/device_info_service.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();
  final DeviceInfoService _deviceInfo = DeviceInfoService();

  Function()? onSessionExpired;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.defaultBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Request & Response Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic Base URL check
          final customUrl = await _storage.getBaseUrl();
          if (customUrl.isNotEmpty) {
            options.baseUrl = customUrl;
          }

          // Attach Bearer Token if present
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach Device Metadata headers
          final meta = _deviceInfo.cachedMetadata;
          if (meta != null) {
            options.headers['User-Agent'] = _deviceInfo.getUserAgent();
            options.headers['X-Device-Id'] = meta.deviceFingerprint;
            options.headers['X-Device-Model'] = meta.model;
            options.headers['X-Device-Brand'] = meta.brand;
            options.headers['X-Device-Manufacturer'] = meta.manufacturer;
            options.headers['X-Device-OS'] = meta.osVersion;
            options.headers['X-Device-Physical'] = meta.isPhysicalDevice.toString();
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle 401 Unauthorized
          if (e.response?.statusCode == 401) {
            _storage.clearSession();
            if (onSessionExpired != null) {
              onSessionExpired!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // GET Request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Terjadi kesalahan sistem: ${e.toString()}');
    }
  }

  // POST Request
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Terjadi kesalahan sistem: ${e.toString()}');
    }
  }

  // PUT Request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Terjadi kesalahan sistem: ${e.toString()}');
    }
  }

  // DELETE Request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Terjadi kesalahan sistem: ${e.toString()}');
    }
  }

  // Format Dio Errors cleanly into user-friendly Indonesian
  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Koneksi ke server waktu habis (timeout). Periksa jaringan internet Anda.',
        statusCode: 408,
      );
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return ApiException(
        message: 'Tidak dapat terhubung ke server https://api.iaimiftahululum.com. Pastikan koneksi internet aktif.',
        statusCode: 503,
      );
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      String message = 'Terjadi kesalahan pada server ($statusCode).';

      if (data is Map<String, dynamic>) {
        if (data.containsKey('message') && data['message'] != null) {
          message = data['message'].toString();
        } else if (data.containsKey('error') && data['error'] != null) {
          message = data['error'].toString();
        }

        // Handle Laravel validation errors (422)
        if (data.containsKey('errors') && data['errors'] is Map) {
          final errorsMap = data['errors'] as Map<String, dynamic>;
          final firstKey = errorsMap.keys.firstOrNull;
          if (firstKey != null) {
            final firstErrorList = errorsMap[firstKey];
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              message = firstErrorList.first.toString();
            }
          }
          return ApiException(
            message: message,
            statusCode: statusCode,
            errors: errorsMap,
          );
        }
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
      );
    }

    return ApiException(message: 'Gagal terhubung: ${e.message ?? 'Unknown error'}');
  }
}
