import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smartphone_rounded, size: 16, color: AppColors.brand700),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Perangkat: ${meta.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brand200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: AppColors.brand600),
                  SizedBox(width: 4),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Subtle Security Theme
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.brand500.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brand400.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.brand300, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Keamanan Perangkat',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Device Binding & Integrity Check',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.brand400.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircleAvatar(radius: 3, backgroundColor: AppColors.brand400),
                      SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.brand200,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detail rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                _buildRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Model Perangkat',
                  value: '${meta.manufacturer} ${meta.model}',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRow(
                  icon: Icons.android_rounded,
                  label: 'Sistem Operasi',
                  value: '${meta.osVersion} (API ${meta.sdkInt})',
                  badgeText: 'Android',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildFingerprintRow(
                  context: context,
                  label: 'Device Fingerprint',
                  fingerprint: meta.deviceFingerprint,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRow(
                  icon: Icons.verified_user_rounded,
                  label: 'Status Perangkat',
                  value: meta.isPhysicalDevice ? 'Perangkat Fisik Asli' : 'Emulator / Virtual',
                  badgeColor: meta.isPhysicalDevice ? AppColors.brand50 : const Color(0xFFFEF3C7),
                  badgeTextColor: meta.isPhysicalDevice ? AppColors.brand800 : const Color(0xFFB45309),
                  badgeBorder: meta.isPhysicalDevice ? AppColors.brand200 : const Color(0xFFFDE68A),
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRow(
                  icon: Icons.terminal_rounded,
                  label: 'Versi Aplikasi',
                  value: 'v${meta.appVersion} (${meta.buildNumber})',
                  badgeText: 'Release',
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
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? badgeBorder,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        if (badgeText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (badgeColor != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeBorder ?? Colors.transparent),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: badgeTextColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ] else ...[
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFingerprintRow({
    required BuildContext context,
    required String label,
    required String fingerprint,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.fingerprint_rounded, size: 16, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Clipboard.setData(ClipboardData(text: fingerprint));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Device Fingerprint disalin ke clipboard'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF0F172A),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fingerprint.length > 14
                      ? '${fingerprint.substring(0, 14)}...'
                      : fingerprint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
