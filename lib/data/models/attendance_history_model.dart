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

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'] ?? '-',
      rawDate: json['raw_date'] ?? '',
      checkIn: json['checkIn'] ?? '-',
      checkOut: json['checkOut'] ?? '-',
      location: json['location'] ?? '-',
      distance: json['distance'] is int
          ? json['distance']
          : (json['distance'] != null ? int.tryParse(json['distance'].toString()) : null),
      status: json['status'] ?? 'HADIR',
    );
  }
}
