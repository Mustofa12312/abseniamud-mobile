import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationSecurityResult {
  final bool isSuccess;
  final Position? position;
  final bool isMockLocation;
  final String? errorMessage;
  final String? mockReason;
  final double? distanceInMeters;
  final bool isWithinRadius;
  final bool isAccuracyValid;

  LocationSecurityResult({
    required this.isSuccess,
    this.position,
    this.isMockLocation = false,
    this.errorMessage,
    this.mockReason,
    this.distanceInMeters,
    this.isWithinRadius = false,
    this.isAccuracyValid = false,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Default campus location (IAIMU Gedung A) if offline/fallback
  static const double defaultCampusLat = -7.166316;
  static const double defaultCampusLng = 113.483162;
  static const double defaultCampusRadius = 75.0; // meters
  static const double defaultMaxAccuracy = 50.0; // meters

  /// Check whether GPS service is enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open device system location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open application permissions settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get current position with strict anti-mock location checks
  Future<LocationSecurityResult> getCurrentPositionSecure({
    double targetLat = defaultCampusLat,
    double targetLng = defaultCampusLng,
    double targetRadius = defaultCampusRadius,
    double maxAccuracy = defaultMaxAccuracy,
  }) async {
    // 1. Check if location service is on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationSecurityResult(
        isSuccess: false,
        errorMessage: 'Layanan lokasi (GPS) belum diaktifkan. Mohon aktifkan GPS perangkat Anda.',
      );
    }

    // 2. Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationSecurityResult(
          isSuccess: false,
          errorMessage: 'Izin akses lokasi ditolak. Aplikasi membutuhkan lokasi untuk presensi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationSecurityResult(
        isSuccess: false,
        errorMessage: 'Izin lokasi ditolak permanen. Silakan buka Pengaturan aplikasi untuk mengizinkan akses lokasi.',
      );
    }

    // 3. Fetch position with High Accuracy
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 12),
        ),
      );

      // 4. ANTI-MOCK LOCATION DETECTION (Fake GPS check)
      // Check 1: Android native isMocked flag
      bool isMock = position.isMocked;
      String? mockReason;

      if (isMock) {
        mockReason = 'Sistem mendeteksi penggunaan Mock Location Provider / Fake GPS pada perangkat Anda.';
      }

      // Check 2: Suspicious accuracy anomalies (e.g. 0.0 or sub-millimeter fixed values common in mock apps)
      if (!isMock && position.accuracy == 0.0) {
        isMock = true;
        mockReason = 'Akurasi GPS tidak wajar (0.0 meter), terindikasi hasil injeksi aplikasi pemalsu lokasi.';
      }

      // If mock location is detected, immediately return security warning
      if (isMock) {
        return LocationSecurityResult(
          isSuccess: false,
          position: position,
          isMockLocation: true,
          mockReason: mockReason,
          errorMessage: 'PERINGATAN: Lokasi palsu (Mock Location / Fake GPS) terdeteksi!\n'
              'Presensi dibatalkan demi keamanan dan integritas data kampus IAIMU.',
        );
      }

      // 5. Calculate Distance to campus target geofence
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      final isWithinRadius = distance <= targetRadius;
      final isAccuracyValid = position.accuracy <= maxAccuracy;

      return LocationSecurityResult(
        isSuccess: true,
        position: position,
        isMockLocation: false,
        distanceInMeters: distance,
        isWithinRadius: isWithinRadius,
        isAccuracyValid: isAccuracyValid,
      );
    } catch (e) {
      return LocationSecurityResult(
        isSuccess: false,
        errorMessage: 'Gagal mengambil koordinat GPS: ${e.toString()}',
      );
    }
  }

  /// Calculate distance between two coordinates in meters using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * 1000 meters; R = 6371 km
  }
}
