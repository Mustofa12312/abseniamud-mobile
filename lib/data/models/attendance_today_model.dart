class AttendanceTodayModel {
  final String status; // NOT_CHECKED_IN, CHECKED_IN, CHECKED_OUT, HOLIDAY
  final String? attendanceStatus; // HADIR, TERLAMBAT
  final String? checkInAt;
  final String? checkOutAt;
  final String? location;
  final int? distance;
  final int? accuracy;

  AttendanceTodayModel({
    required this.status,
    this.attendanceStatus,
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

  factory AttendanceTodayModel.fromJson(Map<String, dynamic> json) {
    return AttendanceTodayModel(
      status: json['status'] ?? 'NOT_CHECKED_IN',
      attendanceStatus: json['attendance_status'] as String?,
      checkInAt: json['check_in_at'] as String?,
      checkOutAt: json['check_out_at'] as String?,
      location: json['location'] as String?,
      distance: json['distance'] is int
          ? json['distance']
          : (json['distance'] != null ? int.tryParse(json['distance'].toString()) : null),
      accuracy: json['accuracy'] is int
          ? json['accuracy']
          : (json['accuracy'] != null ? int.tryParse(json['accuracy'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'attendance_status': attendanceStatus,
      'check_in_at': checkInAt,
      'check_out_at': checkOutAt,
      'location': location,
      'distance': distance,
      'accuracy': accuracy,
    };
  }
}
