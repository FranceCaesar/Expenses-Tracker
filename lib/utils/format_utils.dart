import 'package:intl/intl.dart';

/// Centralized number formatting utilities
class FormatUtils {
  /// Format currency amount with proper locale and symbol
  static String formatCurrency(
    double amount, {
    required String currencySymbol,
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formatted = formatter.format(amount);
    return '$currencySymbol$formatted';
  }

  /// Format number with thousand separators
  static String formatNumber(
    double number, {
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat(
      '#,##0.${'0' * decimalDigits}',
      'en_US',
    );
    return formatter.format(number);
  }

  /// Format number without decimal places
  static String formatWholeNumber(double number) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(number);
  }

  /// Format percentage
  static String formatPercentage(
    double percentage, {
    int decimalDigits = 1,
  }) {
    final formatter = NumberFormat(
      '#,##0.${'0' * decimalDigits}',
      'en_US',
    );
    return '${formatter.format(percentage)}%';
  }

  /// Format large numbers with K, M, B suffix (e.g., 1.5K, 2.3M)
  static String formatCompactNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }

  /// Format date in readable format
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    final formatter = DateFormat(format);
    return formatter.format(date);
  }

  /// Format date with time
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'MMM dd, yyyy hh:mm a',
  }) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  /// Format time in 12-hour format
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  /// Parse string to double with error handling
  static double parseAmount(String value) {
    try {
      return double.parse(value.replaceAll(',', ''));
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if amount is valid
  static bool isValidAmount(String value) {
    try {
      final amount = double.parse(value);
      return amount > 0;
    } catch (e) {
      return false;
    }
  }
}
