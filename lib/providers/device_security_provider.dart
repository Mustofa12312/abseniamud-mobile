import 'package:flutter/material.dart';
import '../core/device/device_info_service.dart';
import '../core/location/location_service.dart';
import '../data/models/campus_location_model.dart';

class DeviceSecurityProvider extends ChangeNotifier {
  final DeviceInfoService _deviceService = DeviceInfoService();
  final LocationService _locationService = LocationService();

  DeviceMetadata? _deviceMetadata;
  DeviceMetadata? get deviceMetadata => _deviceMetadata;

  LocationSecurityResult? _lastLocationResult;
  LocationSecurityResult? get lastLocationResult => _lastLocationResult;

  bool _isScanningLocation = false;
  bool get isScanningLocation => _isScanningLocation;

  String? _locationStatusMessage;
  String? get locationStatusMessage => _locationStatusMessage;

  CampusLocationModel? _selectedCampus;
  CampusLocationModel? get selectedCampus => _selectedCampus;

  List<CampusLocationModel> _campusLocations = [];
  List<CampusLocationModel> get campusLocations => _campusLocations;

  bool get isMockDetected => _lastLocationResult?.isMockLocation ?? false;
  String? get mockReason => _lastLocationResult?.mockReason;

  bool get isGpsReady =>
      _lastLocationResult != null &&
      _lastLocationResult!.isSuccess &&
      !_lastLocationResult!.isMockLocation &&
      _lastLocationResult!.position != null;

  bool get isWithinGeofence => _lastLocationResult?.isWithinRadius ?? false;
  bool get isAccuracyValid => _lastLocationResult?.isAccuracyValid ?? false;

  /// Initialize Device Detection
  Future<void> initDevice() async {
    _deviceMetadata = await _deviceService.init();
    notifyListeners();
  }

  /// Set available campus locations
  void setCampusLocations(List<CampusLocationModel> locations) {
    _campusLocations = locations;
    if (_campusLocations.isNotEmpty && _selectedCampus == null) {
      _selectedCampus = _campusLocations.first;
    }
    notifyListeners();
  }

  /// Change selected campus building
  void selectCampus(CampusLocationModel campus) {
    _selectedCampus = campus;
    notifyListeners();
    // Re-verify distance with newly selected campus
    refreshLocation();
  }

  /// Refresh GPS and perform Anti-Fake Location Security Check
  Future<LocationSecurityResult> refreshLocation() async {
    _isScanningLocation = true;
    _locationStatusMessage = 'Memindai sinyal GPS dan memeriksa integritas perangkat...';
    notifyListeners();

    final targetLat = _selectedCampus?.latitude ?? LocationService.defaultCampusLat;
    final targetLng = _selectedCampus?.longitude ?? LocationService.defaultCampusLng;
    final targetRadius = _selectedCampus?.radius ?? LocationService.defaultCampusRadius;
    final maxAccuracy = _selectedCampus?.maxAccuracy ?? LocationService.defaultMaxAccuracy;

    final result = await _locationService.getCurrentPositionSecure(
      targetLat: targetLat,
      targetLng: targetLng,
      targetRadius: targetRadius,
      maxAccuracy: maxAccuracy,
    );

    _lastLocationResult = result;
    _isScanningLocation = false;

    if (result.isMockLocation) {
      _locationStatusMessage = 'PERINGATAN: Mock Location / Fake GPS terdeteksi!';
    } else if (!result.isSuccess) {
      _locationStatusMessage = result.errorMessage ?? 'Gagal memperoleh lokasi.';
    } else {
      if (result.isWithinRadius) {
        _locationStatusMessage = 'Lokasi Valid! Anda berada di area kampus (${result.distanceInMeters?.toStringAsFixed(0)}m).';
      } else {
        _locationStatusMessage = 'Di luar area kampus (${result.distanceInMeters?.toStringAsFixed(0)}m dari ${_selectedCampus?.name ?? 'Kampus'}).';
      }
    }

    notifyListeners();
    return result;
  }
}
