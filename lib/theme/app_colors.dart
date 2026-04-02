import 'package:flutter/material.dart';

/// Centralized color palette for the entire application
/// Edit colors here and they update everywhere automatically
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Background & Surface
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textLighter = Color(0xFFD1D5DB);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Success States
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoLight = Color(0xFFDEF0FF);

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color gray = Color(0xFFF3F4F6);
  static const Color darkGray = Color(0xFFD1D5DB);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Currency-specific colors (for exchange rates)
  static const Color currencyBadge = Color(0xFFF0F4FF);
  static const Color currencyBadgeText = Color(0xFF4338CA);

  // Shadows
  static Color shadowColor = Colors.black.withValues(alpha: 0.08);
  static Color shadowColorLight = Colors.black.withValues(alpha: 0.04);
  static Color shadowColorDark = Colors.black.withValues(alpha: 0.12);

  // Opacity helpers
  static Color getBorder(double opacity) => Colors.grey.withValues(alpha: opacity);
  static Color getShadow(double opacity) => Colors.black.withValues(alpha: opacity);
}
