import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ۱۳ آبان ۱۴۰۵, Wednesday (a wall-clock value; the zone does not matter).
  final wed = DateTime(2026, 11, 4, 14, 30);

  test('short: weekday + Jalali day + month', () {
    expect(PersianDateLabel.short(wed), 'چهارشنبه ۱۳ آبان');
  });

  test('gregorianShort: Persian weekday, Gregorian day and month name', () {
    expect(PersianDateLabel.gregorianShort(wed), 'چهارشنبه، ۴ نوامبر');
  });

  test('jalaliLong: day month year', () {
    expect(PersianDateLabel.jalaliLong(wed), '۱۳ آبان ۱۴۰۵');
  });
}
