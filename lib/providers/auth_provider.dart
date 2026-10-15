import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/device/device_info_service.dart';
import '../core/navigation/navigation_service.dart';
import '../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  final DeviceInfoService _deviceInfo = DeviceInfoService();

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  AuthProvider() {
    _apiClient.onSessionExpired = () {
      logout(expired: true);
      NavigationService.navigateToLogin(reason: 'Sesi Anda telah berakhir. Silakan login kembali.');
    };
  }

  /// Check existing session on app startup
  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Try fetching fresh profile from /me
      final response = await _apiClient.get(ApiConstants.me);
      if (response != null && response['success'] == true && response['data'] is Map) {
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
        await _storage.saveUser(_currentUser!.toJson());
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Check cached user as fallback if offline
      final cachedUser = await _storage.getUser();
      if (cachedUser != null) {
        _currentUser = UserModel.fromJson(cachedUser);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Login with email/username and password
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure device info is initialized
      final deviceMeta = await _deviceInfo.init();

      final payload = {
        'email': email.trim(),
        'password': password,
        'device_name': deviceMeta.displayName,
      };

      final response = await _apiClient.post(ApiConstants.login, data: payload);

      if (response != null && response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final token = data['token']?.toString() ?? '';
        final userData = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : <String, dynamic>{};

        await _storage.saveToken(token);
        _currentUser = UserModel.fromJson(userData);
        await _storage.saveUser(_currentUser!.toJson());

        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        throw ApiException(message: response?['message'] ?? 'Login gagal. Periksa akun Anda.');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal melakukan login: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout({bool expired = false}) async {
    if (!expired) {
      try {
        await _apiClient.post(ApiConstants.logout);
      } catch (_) {}
    }

    await _storage.clearSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    if (expired) {
      _errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else {
      _errorMessage = null;
    }
    notifyListeners();
  }



  /// Update user contact information (phone, address)
  Future<Map<String, dynamic>> updateContact({String? phone, String? address}) async {
    try {
      final payload = {
        'phone': ?phone,
        'address': ?address,
      };

      final response = await _apiClient.put(ApiConstants.me, data: payload);
      if (response != null && response['success'] == true) {
        // Refresh profile
        await checkAuth();
        return {'success': true, 'message': response['message'] ?? 'Profil berhasil diperbarui.'};
      }
      return {'success': false, 'message': response?['message'] ?? 'Gagal memperbarui profil.'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kendala: ${e.toString()}'};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final payload = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      };

      final response = await _apiClient.put(ApiConstants.me, data: payload);
      if (response != null && response['success'] == true) {
        return {'success': true, 'message': response['message'] ?? 'Kata sandi berhasil diubah.'};
      }
      return {'success': false, 'message': response?['message'] ?? 'Gagal mengubah kata sandi.'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kendala: ${e.toString()}'};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
