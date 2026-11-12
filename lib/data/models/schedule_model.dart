class ScheduleItem {
  final int id;
  final int? academicYearId;
  final String courseName;
  final String? courseCode;
  final String? facultyName;
  final int? semester;
  final int? sks;
  final String roomName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.id,
    this.academicYearId,
    required this.courseName,
    this.courseCode,
    this.facultyName,
    this.semester,
    this.sks,
    required this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().trim());
  }

  static String? _toNonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String get programStudyAndSemesterLabel {
    final faculty = facultyName?.trim();
    final hasFaculty = faculty != null && faculty.isNotEmpty;
    final hasSemester = semester != null && semester! > 0;
    if (hasFaculty && hasSemester) {
      return '$faculty • Semester $semester';
    }
    if (hasFaculty) return faculty;
    if (hasSemester) return 'Semester $semester';
    return 'Program Studi belum diatur';
  }

  String? get courseMetaLabel {
    final parts = <String>[];
    if (courseCode != null && courseCode!.trim().isNotEmpty) {
      parts.add(courseCode!.trim());
    }
    if (sks != null && sks! > 0) {
      parts.add('$sks SKS');
    }
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      academicYearId: _toIntNullable(json['academic_year_id']),
      courseName: _toNonEmptyString(json['course_name']) ?? 'Mata Kuliah',
      courseCode: _toNonEmptyString(json['course_code']),
      facultyName: _toNonEmptyString(json['faculty_name']),
      semester: _toIntNullable(json['semester']),
      sks: _toIntNullable(json['sks']),
      roomName: _toNonEmptyString(json['room_name']) ?? 'Ruang Kelas',
      dayOfWeek: _toNonEmptyString(json['day_of_week']) ?? 'Senin',
      startTime: _toNonEmptyString(json['start_time']) ?? '08:00',
      endTime: _toNonEmptyString(json['end_time']) ?? '10:00',
    );
  }
}
