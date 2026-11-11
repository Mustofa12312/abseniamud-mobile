import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../device/device_info_service.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  bool _isInitialized = false;
  bool _isHandlingSessionExpired = false;

  final SecureStorageService _storage = SecureStorageService();
  final DeviceInfoService _deviceInfo = DeviceInfoService();

  Function()? onSessionExpired;

  Dio get _client {
    if (!_isInitialized) {
      init();
    }
    return _dio;
  }

  /// Checks whether [host] points to a local loopback or RFC-1918 private network address.
  static bool isLocalOrPrivateHost(String host) {
    final normalized = host.trim().toLowerCase().replaceAll('[', '').replaceAll(']', '');
    if (normalized.isEmpty) return false;
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1' ||
        normalized == '10.0.2.2' ||
        normalized == '10.0.3.2' ||
        normalized.endsWith('.local') ||
        normalized.endsWith('.test')) {
      return true;
    }

    final parts = normalized.split('.');
    if (parts.length == 4) {
      final octets = parts.map(int.tryParse).toList();
      if (octets.every((o) => o != null && o >= 0 && o <= 255)) {
        final a = octets[0]!;
        final b = octets[1]!;
        if (a == 10 || a == 127) return true;
        if (a == 192 && b == 168) return true;
        if (a == 172 && b >= 16 && b <= 31) return true;
      }
    }
    return false;
  }

  /// Never bypass TLS certificate validation in release builds or for public hosts.
  static bool shouldAllowBadCertificate(String host, {bool isDebug = kDebugMode}) {
    if (!isDebug) return false;
    return isLocalOrPrivateHost(host);
  }

  /// Removes trailing slashes and surrounding whitespace from a server URL.
  static String normalizeServerUrl(String rawUrl) {
    return rawUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Validates server endpoint format and transport security policy.
  static String? validateServerUrl(String rawUrl, {bool isDebug = kDebugMode}) {
    final normalized = normalizeServerUrl(rawUrl);
    if (normalized.isEmpty) {
      return 'URL server tidak boleh kosong.';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Format URL tidak valid. Gunakan awalan https:// (misal https://api.iaimiftahululum.com/api).';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return 'Protokol URL harus https:// atau http://.';
    }
    if (!isDebug && scheme != 'https') {
      return 'Pada aplikasi rilis, endpoint server wajib menggunakan HTTPS terenkripsi.';
    }
    return null;
  }

  void resetSessionExpiredGuard() {
    _isHandlingSessionExpired = false;
  }

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

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

    // Only allow self-signed certificates for local/private hosts in debug builds
    if (kDebugMode && _dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          return shouldAllowBadCertificate(host);
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
            options.baseUrl = normalizeServerUrl(customUrl);
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
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final path = e.requestOptions.path;
          final isLoginRequest = path == ApiConstants.login || path.endsWith('/auth/login');

          // Handle 401 Unauthorized once across concurrent requests
          if (statusCode == 401 && !isLoginRequest && !_isHandlingSessionExpired) {
            _isHandlingSessionExpired = true;
            await _storage.clearSession();
            onSessionExpired?.call();
          }
          return handler.next(e);
        },
      ),
    );
  }

  // GET Request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _client.get(path, queryParameters: queryParameters);
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
      final response = await _client.post(path, data: data);
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
      final response = await _client.put(path, data: data);
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
      final response = await _client.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Terjadi kesalahan sistem: ${e.toString()}');
    }
  }

  /// Test connectivity to a specific or current API base URL
  Future<Map<String, dynamic>> testConnection([String? customUrl]) async {
    final targetUrl = normalizeServerUrl(
      (customUrl != null && customUrl.trim().isNotEmpty)
          ? customUrl
          : await _storage.getBaseUrl(),
    );

    final urlError = validateServerUrl(targetUrl);
    if (urlError != null) {
      return {
        'success': false,
        'latencyMs': 0,
        'message': urlError,
      };
    }

    final stopwatch = Stopwatch()..start();
    final dioTest = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      if (kDebugMode && dioTest.httpClientAdapter is IOHttpClientAdapter) {
        (dioTest.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => shouldAllowBadCertificate(host);
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
    } finally {
      dioTest.close();
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
