import 'package:intl/intl.dart';

class Formatters {
  static String money(num value, {String currency = 'USD'}) {
    return NumberFormat.simpleCurrency(name: currency).format(value);
  }

  static String shortDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String fullDate(DateTime date) {
    return DateFormat.yMMMMEEEEd().format(date);
  }

  static String percent(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }
}
