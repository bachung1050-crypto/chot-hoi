import 'package:intl/intl.dart';

abstract final class Formatters {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('vi_VN');

  /// 8990000 -> "8.990.000đ"
  static String price(int value) => '${_decimal.format(value)}đ';

  /// 1852 -> "1.852"
  static String count(int value) => _decimal.format(value);

  /// 2100 -> "2.1k", 8900 -> "8.9k"
  static String compact(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    final text = thousands >= 100
        ? thousands.round().toString()
        : thousands.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '${text}k';
  }

  /// 25000000 -> "25 triệu", 2350000 -> "2,35 triệu"
  static String millions(int value) {
    final millions = value / 1000000;
    final text = millions == millions.roundToDouble()
        ? millions.round().toString()
        : millions.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll('.', ',');
    return '$text triệu';
  }

  /// 25000000 -> "25tr"
  static String shortMillions(int value) {
    final millions = value / 1000000;
    final text = millions == millions.roundToDouble()
        ? millions.round().toString()
        : millions.toStringAsFixed(1).replaceAll('.', ',');
    return '${text}tr';
  }

  static String percentDiff(int price, int base) {
    if (base <= 0) return '';
    final diff = ((price - base) / base * 100).round();
    return diff <= 0 ? '' : '+$diff%';
  }

  static String dayMonth(DateTime date) => DateFormat('dd/MM').format(date);
}
