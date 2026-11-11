class AttendanceTodayModel {
  final String status; // NOT_CHECKED_IN, CHECKED_IN, CHECKED_OUT, HOLIDAY, ON_LEAVE
  final String? attendanceStatus; // HADIR, TERLAMBAT, IZIN, SAKIT, CUTI
  final String? leaveType;
  final String? holidayName;
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
      'check_in_at': checkInAt,
      'check_out_at': checkOutAt,
      'location': location,
      'distance': distance,
      'accuracy': accuracy,
    };
  }
}
