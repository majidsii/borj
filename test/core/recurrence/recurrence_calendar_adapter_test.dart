import 'package:borj/core/recurrence/gregorian_recurrence_calendar.dart';
import 'package:borj/core/recurrence/jalali_recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gregorian adapter handles leap days and month shifts', () {
    const adapter = GregorianRecurrenceCalendar();
    final leapDay = RecurrenceLocalDateTime(
      year: 2024,
      month: 2,
      day: 29,
      hour: 8,
    );

    expect(adapter.isValidDate(year: 2024, month: 2, day: 29), isTrue);
    expect(adapter.isValidDate(year: 2026, month: 2, day: 29), isFalse);
    expect(adapter.addDays(leapDay, 1).storageKey, '2024-03-01T08:00');
    expect(adapter.shiftMonth(year: 2026, month: 1, delta: 14).year, 2027);
    expect(adapter.shiftMonth(year: 2026, month: 1, delta: 14).month, 3);
  });

  test(
    'Jalali adapter crosses month and year boundaries deterministically',
    () {
      const adapter = JalaliRecurrenceCalendar();
      final endOfShahrivar = RecurrenceLocalDateTime(
        year: 1405,
        month: 6,
        day: 31,
        hour: 10,
        minute: 15,
      );

      expect(adapter.addDays(endOfShahrivar, 1).storageKey, '1405-07-01T10:15');
      expect(adapter.daysInMonth(year: 1405, month: 6), 31);
      expect(adapter.daysInMonth(year: 1405, month: 7), 30);

      final gregorian = adapter.toGregorianCivil(endOfShahrivar);
      expect(adapter.fromGregorianCivil(gregorian), endOfShahrivar);
    },
  );

  test('Jalali leap year crosses Esfand into Farvardin', () {
    const adapter = JalaliRecurrenceCalendar();
    final leapEnd = RecurrenceLocalDateTime(
      year: 1399,
      month: 12,
      day: 30,
      hour: 23,
      minute: 45,
    );

    expect(adapter.daysInMonth(year: 1399, month: 12), 30);
    expect(adapter.daysInMonth(year: 1400, month: 12), 29);
    expect(adapter.addDays(leapEnd, 1).storageKey, '1400-01-01T23:45');
  });
}
