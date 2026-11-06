import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_engine.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_occurrence.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  const engine = RecurrenceEngine();

  test('daily interval and after-count produce deterministic UTC order', () {
    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 1, 9),
      interval: 2,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 8, 1),
      rangeEndUtc: DateTime.utc(2026, 8, 10),
      floatingTimeZoneId: 'Europe/Amsterdam',
    );

    expect(result.map((item) => item.instantUtc).toList(), <DateTime>[
      DateTime.utc(2026, 8, 1, 9),
      DateTime.utc(2026, 8, 3, 9),
      DateTime.utc(2026, 8, 5, 9),
    ]);
    expect(result.map((item) => item.sequence), <int>[1, 2, 3]);
  });

  test('weekly rules support multiple weekdays and week intervals', () {
    final rule = RecurrenceRule.weekly(
      anchorLocalDateTime: _local(2026, 8, 3, 9),
      weeklyDays: const <RecurrenceWeekday>{
        RecurrenceWeekday.monday,
        RecurrenceWeekday.wednesday,
      },
      interval: 2,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(4),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 8, 1),
      rangeEndUtc: DateTime.utc(2026, 8, 30),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(
      result.map((item) => item.originalLocalDateTime.storageKey),
      <String>[
        '2026-08-03T09:00',
        '2026-08-05T09:00',
        '2026-08-17T09:00',
        '2026-08-19T09:00',
      ],
    );
  });

  test('monthly invalid dates can skip periods', () {
    final rule = RecurrenceRule.monthly(
      anchorLocalDateTime: _local(2026, 1, 31, 8),
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(31),
      ],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 1, 1),
      rangeEndUtc: DateTime.utc(2026, 7, 1),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(
      result.map((item) => item.originalLocalDateTime.storageKey),
      <String>['2026-01-31T08:00', '2026-03-31T08:00', '2026-05-31T08:00'],
    );
  });

  test('monthly invalid dates can clamp and duplicate selectors collapse', () {
    final rule = RecurrenceRule.monthly(
      anchorLocalDateTime: _local(2026, 1, 31, 8),
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(31),
        const RecurrenceMonthSelector.lastDay(),
      ],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.clampToLastDay,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 1, 1),
      rangeEndUtc: DateTime.utc(2026, 4, 1),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(
      result.map((item) => item.originalLocalDateTime.storageKey),
      <String>['2026-01-31T08:00', '2026-02-28T08:00', '2026-03-31T08:00'],
    );
  });

  test('monthly and yearly intervals skip inactive periods', () {
    final monthly = RecurrenceRule.monthly(
      anchorLocalDateTime: _local(2026, 1, 15, 8),
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(15),
      ],
      interval: 2,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );
    final yearly = RecurrenceRule.yearly(
      anchorLocalDateTime: _local(2026, 1, 1, 8),
      annualDates: <RecurrenceAnnualDate>[
        RecurrenceAnnualDate(month: 1, day: 1),
      ],
      interval: 2,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );

    final monthlyResult = engine.expand(
      rule: monthly,
      rangeStartUtc: DateTime.utc(2026),
      rangeEndUtc: DateTime.utc(2027),
      floatingTimeZoneId: 'Etc/UTC',
    );
    final yearlyResult = engine.expand(
      rule: yearly,
      rangeStartUtc: DateTime.utc(2026),
      rangeEndUtc: DateTime.utc(2032),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(
      monthlyResult.map((item) => item.originalLocalDateTime.storageKey),
      <String>['2026-01-15T08:00', '2026-03-15T08:00', '2026-05-15T08:00'],
    );
    expect(
      yearlyResult.map((item) => item.originalLocalDateTime.storageKey),
      <String>['2026-01-01T08:00', '2028-01-01T08:00', '2030-01-01T08:00'],
    );
  });

  test('impossible active periods terminate at the requested range', () {
    final monthly = RecurrenceRule.monthly(
      anchorLocalDateTime: _local(2026, 2, 1, 8),
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(31),
      ],
      interval: 12,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
    );
    final yearly = RecurrenceRule.yearly(
      anchorLocalDateTime: _local(2026, 1, 1, 8),
      annualDates: <RecurrenceAnnualDate>[
        RecurrenceAnnualDate(month: 4, day: 31),
      ],
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
    );

    expect(
      engine.expand(
        rule: monthly,
        rangeStartUtc: DateTime.utc(2026),
        rangeEndUtc: DateTime.utc(2030),
        floatingTimeZoneId: 'Etc/UTC',
      ),
      isEmpty,
    );
    expect(
      engine.expand(
        rule: yearly,
        rangeStartUtc: DateTime.utc(2026),
        rangeEndUtc: DateTime.utc(2030),
        floatingTimeZoneId: 'Etc/UTC',
      ),
      isEmpty,
    );
  });

  test('yearly leap dates skip invalid years', () {
    final rule = RecurrenceRule.yearly(
      anchorLocalDateTime: _local(2024, 2, 29, 10),
      annualDates: <RecurrenceAnnualDate>[
        RecurrenceAnnualDate(month: 2, day: 29),
      ],
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(2),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2024),
      rangeEndUtc: DateTime.utc(2030),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(result.map((item) => item.instantUtc), <DateTime>[
      DateTime.utc(2024, 2, 29, 10),
      DateTime.utc(2028, 2, 29, 10),
    ]);
  });

  test('Jalali daily recurrence crosses month boundary', () {
    final anchor = RecurrenceLocalDateTime(
      year: 1405,
      month: 6,
      day: 31,
      hour: 9,
    );
    final endGregorian = Jalali(1405, 7, 3).toDateTime();

    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: anchor,
      calendar: RecurrenceCalendar.jalali,
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 1, 1),
      rangeEndUtc: DateTime.utc(
        endGregorian.year,
        endGregorian.month,
        endGregorian.day,
        23,
      ),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(
      result.map((item) => item.originalLocalDateTime.storageKey),
      <String>['1405-06-31T09:00', '1405-07-01T09:00', '1405-07-02T09:00'],
    );
  });

  test('fixed and floating timezone modes resolve independently', () {
    final fixed = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 5, 9),
      timeZone: RecurrenceTimeZone.fixed('Asia/Tehran'),
      end: RecurrenceEnd.afterCount(1),
    );
    final floating = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 5, 9),
      end: RecurrenceEnd.afterCount(1),
    );

    final fixedResult = engine.expand(
      rule: fixed,
      rangeStartUtc: DateTime.utc(2026, 8, 5),
      rangeEndUtc: DateTime.utc(2026, 8, 6),
      floatingTimeZoneId: 'Europe/Amsterdam',
    );
    final floatingAmsterdam = engine.expand(
      rule: floating,
      rangeStartUtc: DateTime.utc(2026, 8, 5),
      rangeEndUtc: DateTime.utc(2026, 8, 6),
      floatingTimeZoneId: 'Europe/Amsterdam',
    );
    final floatingTehran = engine.expand(
      rule: floating,
      rangeStartUtc: DateTime.utc(2026, 8, 5),
      rangeEndUtc: DateTime.utc(2026, 8, 6),
      floatingTimeZoneId: 'Asia/Tehran',
    );

    expect(fixedResult.single.instantUtc, DateTime.utc(2026, 8, 5, 5, 30));
    expect(floatingAmsterdam.single.instantUtc, DateTime.utc(2026, 8, 5, 7));
    expect(floatingTehran.single.instantUtc, DateTime.utc(2026, 8, 5, 5, 30));
    expect(fixedResult.single.timeZoneId, 'Asia/Tehran');
    expect(floatingAmsterdam.single.timeZoneId, 'Europe/Amsterdam');
    expect(floatingTehran.single.timeZoneId, 'Asia/Tehran');
  });

  test('until is inclusive and expansion ranges are half-open', () {
    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 1, 9),
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.until(DateTime.utc(2026, 8, 3, 9)),
    );

    final inclusive = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 8, 1, 9),
      rangeEndUtc: DateTime.utc(2026, 8, 4),
      floatingTimeZoneId: 'Etc/UTC',
    );
    final halfOpen = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 8, 1, 9),
      rangeEndUtc: DateTime.utc(2026, 8, 3, 9),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(inclusive.map((item) => item.sequence), <int>[1, 2, 3]);
    expect(halfOpen.map((item) => item.sequence), <int>[1, 2]);
  });

  test('skip cancel and move exceptions preserve original sequence', () {
    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 1, 9),
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(4),
    );

    final result = engine.expand(
      rule: rule,
      rangeStartUtc: DateTime.utc(2026, 8, 1),
      rangeEndUtc: DateTime.utc(2026, 8, 8),
      floatingTimeZoneId: 'Etc/UTC',
      exceptions: <RecurrenceException>[
        RecurrenceException.skip(originalLocalDateTime: _local(2026, 8, 2, 9)),
        RecurrenceException.cancel(
          originalLocalDateTime: _local(2026, 8, 3, 9),
        ),
        RecurrenceException.move(
          originalLocalDateTime: _local(2026, 8, 4, 9),
          movedToLocalDateTime: _local(2026, 8, 6, 11),
        ),
      ],
    );

    expect(result.map((item) => item.status), <RecurrenceOccurrenceStatus>[
      RecurrenceOccurrenceStatus.scheduled,
      RecurrenceOccurrenceStatus.skipped,
      RecurrenceOccurrenceStatus.canceled,
      RecurrenceOccurrenceStatus.moved,
    ]);
    expect(result.last.sequence, 4);
    expect(result.last.instantUtc, DateTime.utc(2026, 8, 6, 11));
    expect(result.last.originalLocalDateTime.storageKey, '2026-08-04T09:00');
    expect(result.last.effectiveLocalDateTime.storageKey, '2026-08-06T11:00');
  });

  test('duplicate exceptions fail and safety limit bounds open series', () {
    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 1, 9),
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
    );
    final original = _local(2026, 8, 2, 9);

    expect(
      () => engine.expand(
        rule: rule,
        rangeStartUtc: DateTime.utc(2026, 8, 1),
        rangeEndUtc: DateTime.utc(2026, 8, 10),
        floatingTimeZoneId: 'Etc/UTC',
        exceptions: <RecurrenceException>[
          RecurrenceException.skip(originalLocalDateTime: original),
          RecurrenceException.cancel(originalLocalDateTime: original),
        ],
      ),
      throwsA(isA<ValidationFailure>()),
    );

    expect(
      () => engine.expand(
        rule: rule,
        rangeStartUtc: DateTime.utc(2026, 8, 1),
        rangeEndUtc: DateTime.utc(2026, 8, 10),
        floatingTimeZoneId: 'Etc/UTC',
        maximumOccurrences: 2,
      ),
      throwsStateError,
    );
  });

  test('same inputs produce equal restart-safe output', () {
    final rule = RecurrenceRule.weekly(
      anchorLocalDateTime: _local(2026, 8, 3, 9),
      weeklyDays: const <RecurrenceWeekday>{
        RecurrenceWeekday.monday,
        RecurrenceWeekday.friday,
      },
      timeZone: RecurrenceTimeZone.fixed('Europe/Amsterdam'),
      end: RecurrenceEnd.afterCount(5),
    );

    List<RecurrenceOccurrence> run() {
      return engine.expand(
        rule: rule,
        rangeStartUtc: DateTime.utc(2026, 8, 1),
        rangeEndUtc: DateTime.utc(2026, 9, 1),
        floatingTimeZoneId: 'Asia/Tehran',
      );
    }

    expect(run(), run());
  });
}

RecurrenceLocalDateTime _local(
  int year,
  int month,
  int day,
  int hour, [
  int minute = 0,
]) {
  return RecurrenceLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
  );
}
