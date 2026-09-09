import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  static String formatDateTime(DateTime dt) => DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);
  static String formatShortDate(DateTime date) => DateFormat('dd/MM').format(date);
  static String formatMonth(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String formatCurrency(double amount, {String currency = 'INR'}) {
    if (currency == 'INR') {
      final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
      return formatter.format(amount);
    }
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }

  static String formatPercentage(double value) => '${value.toStringAsFixed(1)}%';

  static String formatNumber(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
