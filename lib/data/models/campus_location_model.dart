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
    final rawLat = json['lat'] ?? json['latitude'];
    final rawLng = json['lng'] ?? json['longitude'];
    final rawAccuracy = json['accuracy'] ?? json['max_accuracy'];
    final rawRadius = json['radius'];

    return CampusLocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Gedung Kampus',
      latitude: rawLat is num
          ? rawLat.toDouble()
          : double.tryParse(rawLat?.toString() ?? '') ?? -7.166316,
      longitude: rawLng is num
          ? rawLng.toDouble()
          : double.tryParse(rawLng?.toString() ?? '') ?? 113.483162,
      radius: rawRadius is num
          ? rawRadius.toDouble()
          : double.tryParse(rawRadius?.toString() ?? '') ?? 75.0,
      maxAccuracy: rawAccuracy is num
          ? rawAccuracy.toDouble()
          : double.tryParse(rawAccuracy?.toString() ?? '') ?? 50.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'max_accuracy': maxAccuracy,
      'is_active': isActive,
    };
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
