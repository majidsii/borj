import 'package:borj/core/money/money.dart';

const String _groupSeparator = '٬'; // ٬
const String _percentSign = '٪'; // ٪

/// 12400 → '۱۲٬۴۰۰'; -5 → '-۵'.
String formatPersianInteger(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.insert(0, digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  final text = Money.toPersianDigits(groups.join(_groupSeparator));
  return negative ? '-$text' : text;
}

/// 0.7 → '۷۰٪'.
String formatPersianPercent(double fraction) =>
    '${formatPersianInteger((fraction * 100).round())}$_percentSign';
