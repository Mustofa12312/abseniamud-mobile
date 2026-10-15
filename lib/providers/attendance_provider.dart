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
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.attendanceToday);
      if (response != null && response['success'] == true && response['data'] != null) {
        _todayStatus = AttendanceTodayModel.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    _isLoadingToday = false;
    notifyListeners();
  }

  /// Get campus locations
  Future<List<CampusLocationModel>> fetchCampusLocations() async {
    try {
      final response = await _apiClient.get(ApiConstants.locations);
      if (response != null && response['data'] != null) {
        final list = response['data'] as List;
        _campusLocations = list
            .map((item) => CampusLocationModel.fromJson(item as Map<String, dynamic>))
            .where((loc) => loc.isActive)
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Fallback default IAIMU campus if network error
      if (_campusLocations.isEmpty) {
        _campusLocations = [
          CampusLocationModel(
            id: 1,
            name: 'Gedung Utama IAIMU',
            latitude: -7.166316,
            longitude: 113.483162,
            radius: 75.0,
            maxAccuracy: 50.0,
            isActive: true,
          )
        ];
        notifyListeners();
      }
    }
    return _campusLocations;
  }

  /// Get attendance history
  Future<void> fetchHistory({int? month, int? year}) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final Map<String, dynamic> query = {};
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;

      final response = await _apiClient.get(
        ApiConstants.attendanceHistory,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response != null && response['data'] != null) {
        final list = response['data'] as List;
        _historyList = list
            .map((item) => AttendanceHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

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

      if (response != null && response['data'] != null) {
        _summary = AttendanceSummaryModel.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    _isLoadingSummary = false;
    notifyListeners();
  }

  /// Get campus announcements
  Future<void> fetchAnnouncements() async {
    try {
      final response = await _apiClient.get(ApiConstants.announcements);
      if (response != null && response['data'] != null) {
        final list = response['data'] as List;
        _announcements = list
            .map((item) => AnnouncementModel.fromJson(item as Map<String, dynamic>))
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
  }) async {
    _isSubmitting = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
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
