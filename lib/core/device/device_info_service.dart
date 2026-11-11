import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
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

  /// Generates a stable SHA-256 device fingerprint from deterministic hardware/vendor attributes.
  @visibleForTesting
  static String buildDeterministicFingerprint({
    required String platform,
    required String manufacturer,
    required String brand,
    required String model,
    required String hardwareId,
  }) {
    final normalizedSeed = [
      platform.trim().toLowerCase(),
      manufacturer.trim().toLowerCase(),
      brand.trim().toLowerCase(),
      model.trim().toLowerCase(),
      hardwareId.trim().toLowerCase(),
    ].join('|');

    final digest = sha256.convert(utf8.encode(normalizedSeed)).toString();
    return 'IAIMU-${digest.substring(0, 16).toUpperCase()}';
  }

  Future<DeviceMetadata> init() async {
    if (_cachedMetadata != null) return _cachedMetadata!;

    String platformName = 'unknown';
    String model = 'Unknown';
    String brand = 'Unknown';
    String manufacturer = 'Unknown';
    String osVersion = 'Unknown';
    int sdkInt = 0;
    String buildId = 'Unknown';
    String hardwareSeed = 'Unknown';
    bool isPhysicalDevice = true;

    try {
      if (Platform.isAndroid) {
        platformName = 'android';
        final androidInfo = await _deviceInfo.androidInfo;
        model = androidInfo.model;
        brand = androidInfo.brand;
        manufacturer = androidInfo.manufacturer;
        osVersion = 'Android ${androidInfo.version.release}';
        sdkInt = androidInfo.version.sdkInt;
        buildId = androidInfo.id;
        isPhysicalDevice = androidInfo.isPhysicalDevice;
        hardwareSeed = [
          androidInfo.hardware,
          androidInfo.board,
          androidInfo.device,
          androidInfo.product,
          androidInfo.id,
        ].join(':');
      } else if (Platform.isIOS) {
        platformName = 'ios';
        final iosInfo = await _deviceInfo.iosInfo;
        model = iosInfo.modelName.isNotEmpty ? iosInfo.modelName : iosInfo.utsname.machine;
        brand = 'Apple';
        manufacturer = 'Apple';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        buildId = iosInfo.identifierForVendor ?? iosInfo.utsname.machine;
        hardwareSeed = iosInfo.identifierForVendor ?? '${iosInfo.utsname.machine}:${iosInfo.model}';
        isPhysicalDevice = iosInfo.isPhysicalDevice;
      } else if (Platform.isLinux) {
        platformName = 'linux';
        final linuxInfo = await _deviceInfo.linuxInfo;
        model = linuxInfo.name;
        manufacturer = 'Linux Desktop';
        brand = linuxInfo.id;
        osVersion = linuxInfo.version ?? 'Linux';
        buildId = linuxInfo.machineId ?? linuxInfo.buildId ?? '1';
        hardwareSeed = linuxInfo.machineId ?? buildId;
        isPhysicalDevice = true;
      }
    } catch (_) {}

    // Retrieve existing persisted device fingerprint or compute deterministic SHA-256 fingerprint
    String? fingerprint = await _storage.getDeviceId();
    if (fingerprint == null || fingerprint.isEmpty) {
      fingerprint = buildDeterministicFingerprint(
        platform: platformName,
        manufacturer: manufacturer,
        brand: brand,
        model: model,
        hardwareId: hardwareSeed,
      );
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
      final fallbackLabel = Platform.isIOS ? 'iOS Device' : 'Mobile Device';
      displayName = '$fallbackLabel ($fingerprint)';
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
    final prefix = Platform.isIOS ? 'IAIMU-iOS' : 'IAIMU-Android';
    if (meta == null) return '$prefix/1.0';
    return '$prefix/${meta.appVersion} (${meta.manufacturer}; ${meta.model}; ${meta.osVersion}; ID:${meta.deviceFingerprint})';
  }
}
