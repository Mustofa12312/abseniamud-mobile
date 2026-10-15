class ScheduleItem {
  final int id;
  final String courseName;
  final String roomName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.id,
    required this.courseName,
    required this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      courseName: json['course_name'] ?? 'Mata Kuliah',
      roomName: json['room_name'] ?? 'Ruang Kelas',
      dayOfWeek: json['day_of_week'] ?? 'Senin',
      startTime: json['start_time'] ?? '08:00',
      endTime: json['end_time'] ?? '10:00',
    );
  }
}
