import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Map<String, List<ScheduleItem>> _schedulesByDay = {
    'Senin': [],
    'Selasa': [],
    'Rabu': [],
    'Kamis': [],
    'Jumat': [],
    'Sabtu': [],
    'Minggu': [],
  };

  Map<String, List<ScheduleItem>> get schedulesByDay => _schedulesByDay;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch schedules grouped by day
  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.schedules);
      if (response != null && response['data'] is Map) {
        final data = response['data'] as Map;
        final Map<String, List<ScheduleItem>> grouped = {};

        data.forEach((day, list) {
          final dayStr = day.toString();
          if (list is List) {
            grouped[dayStr] = list
                .whereType<Map>()
                .map((item) => ScheduleItem.fromJson(Map<String, dynamic>.from(item)))
                .toList();
          } else {
            grouped[dayStr] = [];
          }
        });

        _schedulesByDay = grouped;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Get schedules for today's day name in Indonesian
  List<ScheduleItem> getSchedulesForDay(String dayName) {
    return _schedulesByDay[dayName] ?? [];
  }
}
