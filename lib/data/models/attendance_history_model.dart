class AttendanceHistoryItem {
  final int id;
  final String date;
  final String rawDate;
  final String checkIn;
  final String checkOut;
  final String location;
  final int? distance;
  final String status;

  AttendanceHistoryItem({
    required this.id,
    required this.date,
    required this.rawDate,
    required this.checkIn,
    required this.checkOut,
    required this.location,
    this.distance,
    required this.status,
  });

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    final d = double.tryParse(value.toString());
    return d?.round();
  }

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'] ?? '-',
      rawDate: json['raw_date'] ?? '',
      checkIn: json['checkIn'] ?? json['check_in'] ?? '-',
      checkOut: json['checkOut'] ?? json['check_out'] ?? '-',
      location: json['location'] ?? '-',
      distance: _toIntNullable(json['distance']),
      status: json['status'] ?? 'HADIR',
    );
  }
}
