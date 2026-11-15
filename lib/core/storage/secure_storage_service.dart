import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  // In-memory session fallback when user chooses not to persist login across restarts
  String? _sessionToken;
  Map<String, dynamic>? _sessionUser;

  // Auth Token
  Future<void> saveToken(String token, {bool persist = true}) async {
    _sessionToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyToken);
    if (persist) {
      await _secureStorage.write(key: ApiConstants.keyToken, value: token);
    } else {
      try {
        await _secureStorage.delete(key: ApiConstants.keyToken);
      } catch (_) {}
    }
  }

  Future<String?> getToken() async {
    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      return _sessionToken;
    }
    try {
      final token = await _secureStorage.read(key: ApiConstants.keyToken);
      if (token != null && token.isNotEmpty) {
        _sessionToken = token;
        return token;
      }
    } catch (_) {}
    // Migration fallback: check legacy shared preferences once, migrate & delete
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(ApiConstants.keyToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      _sessionToken = legacyToken;
      await _secureStorage.write(key: ApiConstants.keyToken, value: legacyToken);
      await prefs.remove(ApiConstants.keyToken);
      return legacyToken;
    }
    return null;
  }

  Future<void> deleteToken() async {
    _sessionToken = null;
    try {
      await _secureStorage.delete(key: ApiConstants.keyToken);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyToken);
  }

  // Cached User Data
  Future<void> saveUser(Map<String, dynamic> userData, {bool persist = true}) async {
    _sessionUser = Map<String, dynamic>.from(userData);
    final prefs = await SharedPreferences.getInstance();
    if (persist) {
      final jsonStr = jsonEncode(userData);
      await prefs.setString(ApiConstants.keyUser, jsonStr);
    } else {
      await prefs.remove(ApiConstants.keyUser);
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    if (_sessionUser != null) {
      return Map<String, dynamic>.from(_sessionUser!);
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(ApiConstants.keyUser);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          _sessionUser = map;
          return map;
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    _sessionUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyUser);
  }

  // Remembered Login Identifier (email/username only, never password)
  Future<void> saveRememberedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = email?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(ApiConstants.keyRememberedEmail);
    } else {
      await prefs.setString(ApiConstants.keyRememberedEmail, trimmed);
    }
  }

  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(ApiConstants.keyRememberedEmail);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return null;
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

  // Bound Account (Strict 1:1 Hardware Lockdown)
  Future<void> saveBoundAccount({required String email, String? name}) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      await _secureStorage.write(key: ApiConstants.keyBoundEmail, value: cleanEmail);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyBoundEmail, cleanEmail);
    if (name != null && name.trim().isNotEmpty) {
      try {
        await _secureStorage.write(key: ApiConstants.keyBoundName, value: name.trim());
      } catch (_) {}
      await prefs.setString(ApiConstants.keyBoundName, name.trim());
    }
  }

  Future<String?> getBoundAccountEmail() async {
    try {
      final email = await _secureStorage.read(key: ApiConstants.keyBoundEmail);
      if (email != null && email.trim().isNotEmpty) return email.trim().toLowerCase();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(ApiConstants.keyBoundEmail);
    return email?.trim().toLowerCase();
  }

  Future<String?> getBoundAccountName() async {
    try {
      final name = await _secureStorage.read(key: ApiConstants.keyBoundName);
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.keyBoundName);
  }

  Future<void> clearBoundAccount() async {
    try {
      await _secureStorage.delete(key: ApiConstants.keyBoundEmail);
      await _secureStorage.delete(key: ApiConstants.keyBoundName);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyBoundEmail);
    await prefs.remove(ApiConstants.keyBoundName);
  }

  // Clear Session
  Future<void> clearSession() async {
    await deleteToken();
    await deleteUser();
  }
}
