import 'package:borj/core/formatting/persian_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integers group with U+066C', () {
    expect(formatPersianInteger(0), '۰');
    expect(formatPersianInteger(999), '۹۹۹');
    expect(formatPersianInteger(1000), '۱٬۰۰۰');
    expect(formatPersianInteger(154400000), '۱۵۴٬۴۰۰٬۰۰۰');
    expect(formatPersianInteger(-12400), '-۱۲٬۴۰۰');
  });

  test('percent uses U+066A', () {
    expect(formatPersianPercent(0.7), '۷۰٪');
    expect(formatPersianPercent(0.004), '۰٪');
    expect(formatPersianPercent(1), '۱۰۰٪');
  });
}
