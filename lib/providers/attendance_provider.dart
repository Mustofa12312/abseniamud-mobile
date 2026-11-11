import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/attendance_today_model.dart';
import '../data/models/attendance_history_model.dart';
import '../data/models/attendance_summary_model.dart';
import '../data/models/campus_location_model.dart';
import '../data/models/announcement_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // Today Status
  AttendanceTodayModel? _todayStatus;
  AttendanceTodayModel? get todayStatus => _todayStatus;
  bool _isLoadingToday = false;
  bool get isLoadingToday => _isLoadingToday;

  // Campus Locations
  List<CampusLocationModel> _campusLocations = [];
  List<CampusLocationModel> get campusLocations => _campusLocations;
  String? _locationsError;
  String? get locationsError => _locationsError;

  // Today / History errors
  String? _todayError;
  String? get todayError => _todayError;
  String? _historyError;
  String? get historyError => _historyError;

  // History
  List<AttendanceHistoryItem> _historyList = [];
  List<AttendanceHistoryItem> get historyList => _historyList;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  // Summary
  AttendanceSummaryModel _summary = AttendanceSummaryModel.empty();
  AttendanceSummaryModel get summary => _summary;
  bool _isLoadingSummary = false;
  bool get isLoadingSummary => _isLoadingSummary;

  // Announcements
  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  // Action status (check-in / check-out in progress)
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _actionMessage;
  String? get actionMessage => _actionMessage;

  /// Clears user-specific cached attendance state (used on logout/account switch).
  void clear() {
    _todayStatus = null;
    _campusLocations = [];
    _historyList = [];
    _summary = AttendanceSummaryModel.empty();
    _announcements = [];
    _locationsError = null;
    _todayError = null;
    _historyError = null;
    _actionMessage = null;
    _isLoadingToday = false;
    _isLoadingHistory = false;
    _isLoadingSummary = false;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Fetch all initial dashboard data
  Future<void> refreshDashboard() async {
    await Future.wait([
      fetchTodayStatus(),
      fetchCampusLocations(),
      fetchSummary(),
      fetchAnnouncements(),
    ]);
  }

  /// Get today's attendance status
  Future<void> fetchTodayStatus() async {
    _isLoadingToday = true;
    _todayError = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.attendanceToday);
      if (response != null && response['success'] == true && response['data'] is Map) {
        _todayStatus = AttendanceTodayModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
      } else if (response != null && response['message'] != null) {
        _todayError = response['message'].toString();
      }
    } on ApiException catch (e) {
      _todayError = e.message;
    } catch (_) {
      _todayError = 'Gagal memuat status presensi hari ini.';
    }

    _isLoadingToday = false;
    notifyListeners();
  }

  /// Get campus locations
  Future<List<CampusLocationModel>> fetchCampusLocations() async {
    _locationsError = null;
    try {
      final response = await _apiClient.get(ApiConstants.locations);
      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        _campusLocations = list
            .whereType<Map>()
            .map((item) => CampusLocationModel.fromJson(Map<String, dynamic>.from(item)))
            .where((loc) => loc.isActive)
            .toList();
        notifyListeners();
      }
    } on ApiException catch (e) {
      _locationsError = e.message;
      notifyListeners();
    } catch (_) {
      _locationsError = 'Gagal memuat titik koordinat kampus dari server.';
      notifyListeners();
    }
    return _campusLocations;
  }

  /// Get attendance history
  Future<void> fetchHistory({int? month, int? year}) async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      final Map<String, dynamic> query = {
        'per_page': 50,
      };
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;

      final response = await _apiClient.get(
        ApiConstants.attendanceHistory,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        _historyList = list
            .whereType<Map>()
            .map((item) => AttendanceHistoryItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } on ApiException catch (e) {
      _historyError = e.message;
    } catch (_) {
      _historyError = 'Gagal memuat riwayat presensi.';
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Get monthly summary
  Future<void> fetchSummary({int? month, int? year}) async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      final Map<String, dynamic> query = {};
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;

      final response = await _apiClient.get(
        ApiConstants.attendanceSummary,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response != null && response['data'] is Map) {
        _summary = AttendanceSummaryModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
      }
    } catch (_) {}

    _isLoadingSummary = false;
    notifyListeners();
  }

  /// Get campus announcements
  Future<void> fetchAnnouncements() async {
    try {
      final response = await _apiClient.get(ApiConstants.announcements);
      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        _announcements = list
            .whereType<Map>()
            .map((item) => AnnouncementModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Check-in request to Laravel API
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    int? locationId,
  }) async {
    _isSubmitting = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'location_id': ?locationId,
      };

      final response = await _apiClient.post(ApiConstants.checkIn, data: payload);

      _isSubmitting = false;
      if (response != null && response['success'] == true) {
        await fetchTodayStatus();
        await fetchSummary();
        return {
          'success': true,
          'message': response['message'] ?? 'Check-in berhasil tercatat!',
          'data': response['data'],
        };
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': response?['message'] ?? 'Gagal melakukan check-in.',
        };
      }
    } on ApiException catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kendala: ${e.toString()}'};
    }
  }

  /// Check-out request to Laravel API
  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required double accuracy,
    int? locationId,
  }) async {
    _isSubmitting = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'location_id': ?locationId,
      };

      final response = await _apiClient.post(ApiConstants.checkOut, data: payload);

      _isSubmitting = false;
      if (response != null && response['success'] == true) {
        await fetchTodayStatus();
        await fetchSummary();
        return {
          'success': true,
          'message': response['message'] ?? 'Check-out berhasil dicatat. Terima kasih!',
          'data': response['data'],
        };
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': response?['message'] ?? 'Gagal melakukan check-out.',
        };
      }
    } on ApiException catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kendala: ${e.toString()}'};
    }
  }
}
