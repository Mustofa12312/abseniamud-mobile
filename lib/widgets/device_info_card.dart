import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/device/device_info_service.dart';

class DeviceInfoCard extends StatelessWidget {
  final DeviceMetadata? metadata;
  final bool isCompact;

  const DeviceInfoCard({
    super.key,
    this.metadata,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (metadata == null) {
      return const SizedBox.shrink();
    }

    final meta = metadata!;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.smartphone_rounded, size: 18, color: AppColors.brand700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Perangkat Terdeteksi: ${meta.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brand100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand800,
                ),
              ),
            )
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.brand700, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Identitas Perangkat Terdeteksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Model Perangkat',
                  value: '${meta.manufacturer} ${meta.model}',
                ),
                const Divider(height: 18),
                _buildRow(
                  icon: Icons.android_rounded,
                  label: 'Sistem Operasi',
                  value: '${meta.osVersion} (API ${meta.sdkInt})',
                ),
                const Divider(height: 18),
                _buildRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'Device Fingerprint',
                  value: meta.deviceFingerprint,
                  isMonospace: true,
                ),
                const Divider(height: 18),
                _buildRow(
                  icon: Icons.verified_rounded,
                  label: 'Status Perangkat',
                  value: meta.isPhysicalDevice ? 'Perangkat Fisik Asli' : 'Emulator/Simulator',
                  valueColor: meta.isPhysicalDevice ? AppColors.brand700 : AppColors.accent600,
                ),
                const Divider(height: 18),
                _buildRow(
                  icon: Icons.app_settings_alt_rounded,
                  label: 'Versi Aplikasi',
                  value: 'IAIMU Mobile v${meta.appVersion} (${meta.buildNumber})',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryLight,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
