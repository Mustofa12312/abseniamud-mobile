class ApiConstants {
  // Production IAIMU Attendance API Base URL
  static const String defaultBaseUrl = 'https://api.iaimiftahululum.com/api';

  // Storage Keys
  static const String keyToken = 'iaimu_auth_token';
  static const String keyUser = 'iaimu_cached_user';
  static const String keyBaseUrl = 'iaimu_custom_base_url';
  static const String keyDeviceId = 'iaimu_device_fingerprint';

  // API Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // Attendance Endpoints
  static const String attendanceToday = '/attendance/today';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceSummary = '/attendance/summary';
  static const String corrections = '/attendance/corrections';

  // Schedules, Locations, Leaves, Announcements
  static const String schedules = '/schedules';
  static const String locations = '/locations';
  static const String leaves = '/leaves';
  static const String announcements = '/announcements';

  // Networking Defaults
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
