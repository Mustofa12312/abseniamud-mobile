class CampusLocationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final double maxAccuracy;
  final bool isActive;

  CampusLocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.maxAccuracy,
    this.isActive = true,
  });

  factory CampusLocationModel.fromJson(Map<String, dynamic> json) {
    return CampusLocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Gedung Kampus',
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude'].toString()) ?? -7.166316,
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude'].toString()) ?? 113.483162,
      radius: json['radius'] is num
          ? (json['radius'] as num).toDouble()
          : double.tryParse(json['radius'].toString()) ?? 75.0,
      maxAccuracy: json['max_accuracy'] is num
          ? (json['max_accuracy'] as num).toDouble()
          : double.tryParse(json['max_accuracy'].toString()) ?? 50.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusLocationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
