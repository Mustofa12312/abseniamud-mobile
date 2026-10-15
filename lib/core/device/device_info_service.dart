import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../storage/secure_storage_service.dart';

class DeviceMetadata {
  final String model;
  final String brand;
  final String manufacturer;
  final String osVersion;
  final int sdkInt;
  final String buildId;
  final bool isPhysicalDevice;
  final String deviceFingerprint;
  final String appVersion;
  final String buildNumber;
  final String displayName;

  DeviceMetadata({
    required this.model,
    required this.brand,
    required this.manufacturer,
    required this.osVersion,
    required this.sdkInt,
    required this.buildId,
    required this.isPhysicalDevice,
    required this.deviceFingerprint,
    required this.appVersion,
    required this.buildNumber,
    required this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'brand': brand,
      'manufacturer': manufacturer,
      'os_version': osVersion,
      'sdk_int': sdkInt,
      'build_id': buildId,
      'is_physical_device': isPhysicalDevice,
      'device_fingerprint': deviceFingerprint,
      'app_version': appVersion,
      'build_number': buildNumber,
      'display_name': displayName,
    };
  }
}

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorageService _storage = SecureStorageService();

  DeviceMetadata? _cachedMetadata;
  DeviceMetadata? get cachedMetadata => _cachedMetadata;

  Future<DeviceMetadata> init() async {
    if (_cachedMetadata != null) return _cachedMetadata!;

    String model = 'Unknown';
    String brand = 'Unknown';
    String manufacturer = 'Unknown';
    String osVersion = 'Unknown';
    int sdkInt = 0;
    String buildId = 'Unknown';
    bool isPhysicalDevice = true;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        model = androidInfo.model;
        brand = androidInfo.brand;
        manufacturer = androidInfo.manufacturer;
        osVersion = 'Android ${androidInfo.version.release}';
        sdkInt = androidInfo.version.sdkInt;
        buildId = androidInfo.id;
        isPhysicalDevice = androidInfo.isPhysicalDevice;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        model = linuxInfo.name;
        manufacturer = 'Linux Desktop';
        brand = linuxInfo.id;
        osVersion = linuxInfo.version ?? 'Linux';
        buildId = linuxInfo.buildId ?? '1';
        isPhysicalDevice = true;
      }
    } catch (_) {}

    // Retrieve or generate persistent unique device fingerprint
    String? fingerprint = await _storage.getDeviceId();
    if (fingerprint == null || fingerprint.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rawSeed = '$manufacturer-$model-$buildId-$now';
      // Create a deterministic hash/id
      fingerprint = 'IAIMU-${rawSeed.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}';
      await _storage.saveDeviceId(fingerprint);
    }

    // App Version
    String appVersion = '1.0.0';
    String buildNumber = '1';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = pkg.version;
      buildNumber = pkg.buildNumber;
    } catch (_) {}

    // Formatted display name for login and server
    String displayName = '$manufacturer $model ($osVersion)';
    if (displayName.trim().isEmpty || displayName.contains('Unknown')) {
      displayName = 'Android Device ($fingerprint)';
    }

    _cachedMetadata = DeviceMetadata(
      model: model,
      brand: brand,
      manufacturer: manufacturer,
      osVersion: osVersion,
      sdkInt: sdkInt,
      buildId: buildId,
      isPhysicalDevice: isPhysicalDevice,
      deviceFingerprint: fingerprint,
      appVersion: appVersion,
      buildNumber: buildNumber,
      displayName: displayName,
    );

    return _cachedMetadata!;
  }

  // Get user-agent string for headers
  String getUserAgent() {
    final meta = _cachedMetadata;
    if (meta == null) return 'IAIMU-Android/1.0';
    return 'IAIMU-Android/${meta.appVersion} (${meta.manufacturer}; ${meta.model}; ${meta.osVersion}; ID:${meta.deviceFingerprint})';
  }
}
