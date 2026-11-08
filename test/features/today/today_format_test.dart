import 'package:borj/features/today/presentation/today_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatClock', () {
    expect(formatClock(DateTime(2026, 1, 1, 14, 30)), '۱۴:۳۰');
    expect(formatClock(DateTime(2026, 1, 1, 9, 5)), '۹:۰۵');
    expect(formatClock(DateTime(2026, 1, 1, 0, 0)), '۰:۰۰');
  });
}
