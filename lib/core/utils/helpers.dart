import 'package:intl/intl.dart';

/// Currency formatting utilities
class CurrencyUtils {
  CurrencyUtils._();

  static const Map<String, String> currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'SGD': 'S\$',
  };

  /// Format amount with Indian locale (₹1,23,456.78)
  static String formatAmount(double amount, {String currency = 'INR'}) {
    final symbol = currencySymbols[currency] ?? currency;
    if (currency == 'INR') {
      return '$symbol${_formatIndian(amount)}';
    }
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format with Indian numbering system (1,23,456.78)
  static String _formatIndian(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    if (intPart.length <= 3) {
      return '${isNegative ? "-" : ""}$intPart.$decPart';
    }

    final lastThree = intPart.substring(intPart.length - 3);
    final remaining = intPart.substring(0, intPart.length - 3);
    final formatted = StringBuffer();

    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        formatted.write(',');
      }
      formatted.write(remaining[i]);
    }

    return '${isNegative ? "-" : ""}$formatted,$lastThree.$decPart';
  }
}

/// Date formatting helpers
class DateUtils2 {
  DateUtils2._();

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(date).inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat('dd MMM').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
