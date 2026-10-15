class LecturerInfo {
  final int? id;
  final String? nidn;
  final String? nip;
  final String? phone;

  LecturerInfo({
    this.id,
    this.nidn,
    this.nip,
    this.phone,
  });

  factory LecturerInfo.fromJson(Map<String, dynamic> json) {
    return LecturerInfo(
      id: json['id'] as int?,
      nidn: json['nidn']?.toString(),
      nip: json['nip']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nidn': nidn,
      'nip': nip,
      'phone': phone,
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final int? roleId;
  final String? roleName;
  final String? attendanceType;
  final LecturerInfo? lecturer;
  final Map<String, dynamic>? staffProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.roleId,
    this.roleName,
    this.attendanceType,
    this.lecturer,
    this.staffProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleId: json['role_id'] as int?,
      roleName: json['role'] is String
          ? json['role']
          : (json['role'] is Map ? json['role']['name'] : null),
      attendanceType: json['attendance_type'] as String?,
      lecturer: json['lecturer'] != null && json['lecturer'] is Map<String, dynamic>
          ? LecturerInfo.fromJson(json['lecturer'] as Map<String, dynamic>)
          : null,
      staffProfile: json['staff_profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role_id': roleId,
      'role': roleName,
      'attendance_type': attendanceType,
      'lecturer': lecturer?.toJson(),
      'staff_profile': staffProfile,
    };
  }
}
