import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String symbol, {String locale = 'es'}) {
    final formatter = NumberFormat('#,##0.00', locale);
    return '$symbol ${formatter.format(amount)}';
  }

  static String compact(double amount, String symbol, {String locale = 'es'}) {
    if (amount >= 1000) {
      final formatter = NumberFormat('#,##0.0', locale);
      return '$symbol ${formatter.format(amount / 1000)}k';
    }
    return format(amount, symbol, locale: locale);
  }
}
