import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MockLocationWarning extends StatelessWidget {
  final bool isMockDetected;
  final String? reason;
  final VoidCallback? onRefresh;

  const MockLocationWarning({
    super.key,
    required this.isMockDetected,
    this.reason,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isMockDetected) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.securityAlertBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.securityAlertBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.securityAlertText,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'LOKASI PALSU (FAKE GPS) TERDETEKSI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.securityAlertText,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Presensi Ditolak & Diblokir Otomatis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reason ??
                  'Sistem keamanan IAIMU mendeteksi adanya aplikasi Mock Location atau manipulasi koordinat GPS pada perangkat Anda. Silakan nonaktifkan Fake GPS untuk melanjutkan.',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF7F1D1D),
                height: 1.4,
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.securityAlertText),
                  label: const Text(
                    'Pindai Ulang Lokasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.securityAlertText,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.securityAlertBorder),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      );
    }

    // Clean verified GPS state
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.securitySafeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.securitySafeBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.brand700,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Keamanan GPS Terverifikasi: Koordinat Asli Perangkat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.securitySafeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
