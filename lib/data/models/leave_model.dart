class LeaveModel {
  final int id;
  final String type; // Izin, Sakit, Cuti
  final String startDate;
  final String endDate;
  final String reason;
  final String? documentPath;
  final String status; // PENDING, APPROVED, REJECTED
  final String? adminNotes;
  final String createdAt;

  LeaveModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentPath,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? 'Izin',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      reason: json['reason'] ?? '',
      documentPath: json['document_path']?.toString(),
      status: json['status'] ?? 'PENDING',
      adminNotes: json['admin_notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'document_path': documentPath,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt,
    };
  }
}
