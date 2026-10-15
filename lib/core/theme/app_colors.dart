import 'package:flutter/material.dart';

class AppColors {
  // Brand Emerald Green Palette
  static const Color brand50 = Color(0xFFF0FDF4);
  static const Color brand100 = Color(0xFFDCFCE7);
  static const Color brand200 = Color(0xFFBBF7D0);
  static const Color brand300 = Color(0xFF86EFAC);
  static const Color brand400 = Color(0xFF4ADE80);
  static const Color brand500 = Color(0xFF22C55E);
  static const Color brand600 = Color(0xFF16A34A); // Primary Brand
  static const Color brand700 = Color(0xFF15803D);
  static const Color brand800 = Color(0xFF166534);
  static const Color brand900 = Color(0xFF14532D);
  static const Color brand950 = Color(0xFF052E16);

  // Accent Amber
  static const Color accent400 = Color(0xFFFBBF24);
  static const Color accent500 = Color(0xFFF59E0B);
  static const Color accent600 = Color(0xFFD97706);

  // Status Colors
  static const Color statusHadir = Color(0xFF16A34A);
  static const Color statusTerlambat = Color(0xFFF97316);
  static const Color statusIzin = Color(0xFF0284C7);
  static const Color statusAlpha = Color(0xFFDC2626);
  static const Color statusHoliday = Color(0xFF64748B);

  // Neutrals / Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF141F32);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Security / Warning (Mock Location & Alerts)
  static const Color securityAlertBg = Color(0xFFFEF2F2);
  static const Color securityAlertBorder = Color(0xFFFCA5A5);
  static const Color securityAlertText = Color(0xFF991B1B);

  static const Color securitySafeBg = Color(0xFFF0FDF4);
  static const Color securitySafeBorder = Color(0xFF86EFAC);
  static const Color securitySafeText = Color(0xFF166534);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF052E16), Color(0xFF14532D), Color(0xFF15803D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
