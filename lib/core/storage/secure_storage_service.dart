import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Auth Token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: ApiConstants.keyToken, value: token);
    // Backup to shared prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyToken, token);
  }

  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: ApiConstants.keyToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.keyToken);
  }

  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: ApiConstants.keyToken);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyToken);
  }

  // Cached User Data
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final jsonStr = jsonEncode(userData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyUser, jsonStr);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(ApiConstants.keyUser);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyUser);
  }

  // Custom Base URL
  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyBaseUrl, url.trim());
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(ApiConstants.keyBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return ApiConstants.defaultBaseUrl;
  }

  // Device ID / Fingerprint
  Future<void> saveDeviceId(String deviceId) async {
    await _secureStorage.write(key: ApiConstants.keyDeviceId, value: deviceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyDeviceId, deviceId);
  }

  Future<String?> getDeviceId() async {
    try {
      final id = await _secureStorage.read(key: ApiConstants.keyDeviceId);
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.keyDeviceId);
  }

  // Clear Session
  Future<void> clearSession() async {
    await deleteToken();
    await deleteUser();
  }
}
