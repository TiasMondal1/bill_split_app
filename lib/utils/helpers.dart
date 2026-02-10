import 'package:intl/intl.dart';

class Helpers {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static double roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static int getColorForPerson(String name, List<int> availableColors) {
    // Deterministic color assignment based on name
    final hash = name.hashCode;
    return availableColors[hash.abs() % availableColors.length];
  }
}
