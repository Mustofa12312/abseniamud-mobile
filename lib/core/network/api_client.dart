import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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

    // Ensure robust SSL/TLS certificate handling across Android devices
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Allow connection to official campus domain & local development subnets
          return true;
        };
        return client;
      };
    }

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

  /// Test connectivity to a specific or current API base URL
  Future<Map<String, dynamic>> testConnection([String? customUrl]) async {
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : await _storage.getBaseUrl();

    final stopwatch = Stopwatch()..start();
    try {
      final dioTest = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (dioTest.httpClientAdapter is IOHttpClientAdapter) {
        (dioTest.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      }

      // Check URL connectivity
      final response = await dioTest.get(targetUrl);
      stopwatch.stop();

      return {
        'success': true,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'statusCode': response.statusCode,
        'message': 'Terhubung (${stopwatch.elapsedMilliseconds} ms)',
      };
    } on DioException catch (e) {
      stopwatch.stop();
      // Even if 404 or 401, the server is reached!
      if (e.response != null) {
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'statusCode': e.response?.statusCode,
          'message': 'Server aktif (${stopwatch.elapsedMilliseconds} ms, status ${e.response?.statusCode})',
        };
      }
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': _handleDioError(e).message,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': 'Gagal koneksi: ${e.toString()}',
      };
    }
  }

  // Format Dio Errors cleanly into user-friendly Indonesian
  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Koneksi ke server waktu habis (timeout). Periksa jaringan internet perangkat Anda.',
        statusCode: 408,
      );
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      final host = e.requestOptions.uri.host.isNotEmpty ? e.requestOptions.uri.host : 'server';
      return ApiException(
        message: 'Tidak dapat terhubung ke $host. Pastikan data seluler/WiFi aktif atau periksa setelan server API.',
        statusCode: 503,
      );
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      String message = 'Terjadi kesalahan pada server ($statusCode).';

      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        if (dataMap.containsKey('message') && dataMap['message'] != null) {
          message = dataMap['message'].toString();
        } else if (dataMap.containsKey('error') && dataMap['error'] != null) {
          message = dataMap['error'].toString();
        }

        // Handle Laravel validation errors (422)
        if (dataMap.containsKey('errors') && dataMap['errors'] is Map) {
          final errorsMap = Map<String, dynamic>.from(dataMap['errors'] as Map);
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
