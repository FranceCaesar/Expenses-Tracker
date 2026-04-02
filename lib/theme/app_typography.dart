import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Typography system for consistent text styling
/// Edit text styles here and they apply everywhere automatically
class AppTypography {
  static const String fontFamily = 'Roboto';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0,
  );

  // Body Styles
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
    letterSpacing: 0.2,
  );

  // Button Style
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Caption/Small Text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    letterSpacing: 0.3,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    letterSpacing: 0.2,
  );

  // Label Styles
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
    letterSpacing: 0.5,
  );

  // Amount/Number Styles (for currency display)
  static const TextStyle amountLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.2,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0,
  );

  // Exchange Rate Style
  static const TextStyle exchangeRateLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
    letterSpacing: 0.3,
  );

  static const TextStyle exchangeRateValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.2,
  );

  // Category/Badge Style
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.currencyBadgeText,
    letterSpacing: 0.3,
  );

  // Status Text
  static const TextStyle statusSuccess = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
    letterSpacing: 0.2,
  );

  static const TextStyle statusError = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
    letterSpacing: 0.2,
  );

  static const TextStyle statusWarning = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.warning,
    letterSpacing: 0.2,
  );
}
