import 'package:borj/core/date_time/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDate', () {
    test('round trips ISO date without local timezone conversion', () {
      final date = LocalDate.parseIso('2026-07-26');

      expect(date.toIso(), '2026-07-26');
      expect(date.toUtcStart(), DateTime.utc(2026, 7, 26));
    });

    test('rejects invalid Gregorian dates', () {
      expect(() => LocalDate.parseIso('2026-02-30'), throwsArgumentError);
      expect(() => LocalDate.parseIso('26-7-6'), throwsFormatException);
    });

    test('adds days using UTC calendar arithmetic', () {
      final date = LocalDate.parseIso('2026-12-31');

      expect(date.addDays(1).toIso(), '2027-01-01');
    });
  });
}
