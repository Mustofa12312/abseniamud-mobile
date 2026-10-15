class AttendanceCorrectionModel {
  final int id;
  final String date;
  final String rawDate;
  final String type;
  final String reason;
  final String status;
  final String createdAt;

  AttendanceCorrectionModel({
    required this.id,
    required this.date,
    required this.rawDate,
    required this.type,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory AttendanceCorrectionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'] ?? '-',
      rawDate: json['raw_date'] ?? '',
      type: json['type'] ?? 'Lupa Presensi',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
    );
  }
}
