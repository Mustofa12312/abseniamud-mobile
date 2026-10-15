import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label = status;

    switch (status.toUpperCase()) {
      case 'HADIR':
      case 'APPROVED':
      case 'VALID':
        bgColor = AppColors.brand100;
        textColor = AppColors.brand800;
        icon = Icons.check_circle_rounded;
        label = status == 'APPROVED' ? 'Disetujui' : 'Hadir';
        break;

      case 'TERLAMBAT':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        icon = Icons.access_time_filled_rounded;
        label = 'Terlambat';
        break;

      case 'IZIN':
      case 'SAKIT':
      case 'CUTI':
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0369A1);
        icon = Icons.info_rounded;
        break;

      case 'TIDAK_HADIR':
      case 'ALPHA':
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        icon = Icons.cancel_rounded;
        label = status == 'REJECTED' ? 'Ditolak' : 'Tidak Hadir';
        break;

      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        icon = Icons.hourglass_top_rounded;
        label = 'Menunggu';
        break;

      case 'NOT_CHECKED_IN':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        icon = Icons.radio_button_unchecked_rounded;
        label = 'Belum Check-in';
        break;

      case 'CHECKED_IN':
        bgColor = AppColors.brand100;
        textColor = AppColors.brand800;
        icon = Icons.login_rounded;
        label = 'Sudah Check-in';
        break;

      case 'CHECKED_OUT':
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF3730A3);
        icon = Icons.task_alt_rounded;
        label = 'Selesai (Check-out)';
        break;

      case 'HOLIDAY':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.event_busy_rounded;
        label = 'Hari Libur';
        break;

      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = AppColors.textSecondaryLight;
        icon = Icons.circle;
        label = status;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
