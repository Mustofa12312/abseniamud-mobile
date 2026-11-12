class AttendanceTodayModel {
  final String status; // NOT_CHECKED_IN, CHECKED_IN, CHECKED_OUT, HOLIDAY, ON_LEAVE
  final String? attendanceStatus; // HADIR, TERLAMBAT, IZIN, SAKIT, CUTI
  final String? leaveType;
  final String? holidayName;
  final String? expectedCheckoutTime;
  final String? checkInAt;
  final String? checkOutAt;
  final String? location;
  final int? distance;
  final int? accuracy;

  AttendanceTodayModel({
    required this.status,
    this.attendanceStatus,
    this.leaveType,
    this.holidayName,
    this.expectedCheckoutTime,
    this.checkInAt,
    this.checkOutAt,
    this.location,
    this.distance,
    this.accuracy,
  });

  bool get isNotCheckedIn => status == 'NOT_CHECKED_IN';
  bool get isCheckedIn => status == 'CHECKED_IN';
  bool get isCheckedOut => status == 'CHECKED_OUT';
  bool get isHoliday => status == 'HOLIDAY';
  bool get isOnLeave => status == 'ON_LEAVE';

  /// Parses configured checkout time (HH:mm or HH:mm:ss), defaulting to 16:00.
  ({int hour, int minute}) get resolvedCheckoutTime {
    final raw = expectedCheckoutTime?.trim() ?? '';
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)').firstMatch(raw);
    if (match != null) {
      final h = int.tryParse(match.group(1) ?? '');
      final m = int.tryParse(match.group(2) ?? '');
      if (h != null && m != null) {
        return (hour: h, minute: m);
      }
    }
    return (hour: 16, minute: 0);
  }

  String get formattedCheckoutTime {
    final t = resolvedCheckoutTime;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    final d = double.tryParse(value.toString());
    return d?.round();
  }

  factory AttendanceTodayModel.fromJson(Map<String, dynamic> json) {
    return AttendanceTodayModel(
      status: json['status'] ?? 'NOT_CHECKED_IN',
      attendanceStatus: json['attendance_status'] as String?,
      leaveType: json['leave_type'] as String?,
      holidayName: json['holiday_name'] as String?,
      expectedCheckoutTime: json['expected_checkout_time'] as String?,
      checkInAt: json['check_in_at'] as String?,
      checkOutAt: json['check_out_at'] as String?,
      location: json['location'] as String?,
      distance: _toIntNullable(json['distance']),
      accuracy: _toIntNullable(json['accuracy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'attendance_status': attendanceStatus,
      'leave_type': leaveType,
      'holiday_name': holidayName,
      'expected_checkout_time': expectedCheckoutTime,
      'check_in_at': checkInAt,
      'check_out_at': checkOutAt,
      'location': location,
      'distance': distance,
      'accuracy': accuracy,
    };
  }
}
