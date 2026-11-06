import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_of_day.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local values validate and keep stable storage identity', () {
    final local = RecurrenceLocalDateTime(
      year: 1405,
      month: 5,
      day: 14,
      hour: 9,
      minute: 7,
    );

    expect(local.storageKey, '1405-05-14T09:07');
    expect(RecurrenceTimeOfDay(hour: 9, minute: 7).toString(), '09:07');
    expect(
      () => RecurrenceLocalDateTime(year: 1405, month: 13, day: 1),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => RecurrenceTimeOfDay(hour: 24, minute: 0),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('end and timezone models reject ambiguous invalid state', () {
    final untilUtc = DateTime.utc(2026, 8, 5, 12);

    expect(RecurrenceEnd.until(untilUtc).untilUtc, untilUtc);
    expect(RecurrenceEnd.afterCount(4).count, 4);
    expect(
      RecurrenceTimeZone.fixed(' Asia/Tehran ').fixedTimeZoneId,
      'Asia/Tehran',
    );
    expect(
      const RecurrenceTimeZone.floating().resolveTimeZoneId(
        ' Europe/Amsterdam ',
      ),
      'Europe/Amsterdam',
    );

    expect(
      () => RecurrenceEnd.until(DateTime(2026, 8, 5)),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => RecurrenceEnd.afterCount(0),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => RecurrenceTimeZone.fixed(' '),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('frequency factories require canonical selector sets', () {
    final anchor = RecurrenceLocalDateTime(
      year: 2026,
      month: 8,
      day: 3,
      hour: 9,
    );

    final weekly = RecurrenceRule.weekly(
      anchorLocalDateTime: anchor,
      weeklyDays: const <RecurrenceWeekday>{
        RecurrenceWeekday.monday,
        RecurrenceWeekday.wednesday,
      },
      interval: 2,
    );
    final monthly = RecurrenceRule.monthly(
      anchorLocalDateTime: anchor,
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(5),
        const RecurrenceMonthSelector.lastDay(),
      ],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.clampToLastDay,
    );
    final yearly = RecurrenceRule.yearly(
      anchorLocalDateTime: anchor,
      annualDates: <RecurrenceAnnualDate>[
        RecurrenceAnnualDate(month: 2, day: 29),
      ],
    );

    expect(weekly.interval, 2);
    expect(weekly.weeklyDays, hasLength(2));
    expect(monthly.monthlySelectors, hasLength(2));
    expect(
      monthly.invalidDatePolicy,
      RecurrenceInvalidDatePolicy.clampToLastDay,
    );
    expect(yearly.annualDates.single.day, 29);

    expect(
      () => RecurrenceRule.weekly(
        anchorLocalDateTime: anchor,
        weeklyDays: const <RecurrenceWeekday>{},
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => RecurrenceRule.monthly(
        anchorLocalDateTime: anchor,
        monthlySelectors: const <RecurrenceMonthSelector>[],
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('exceptions keep original identity and validate move targets', () {
    final original = RecurrenceLocalDateTime(
      year: 2026,
      month: 8,
      day: 5,
      hour: 9,
    );
    final moved = original.copyWith(day: 6);

    expect(
      RecurrenceException.skip(originalLocalDateTime: original).action,
      RecurrenceExceptionAction.skip,
    );
    expect(
      RecurrenceException.cancel(originalLocalDateTime: original).action,
      RecurrenceExceptionAction.cancel,
    );
    expect(
      RecurrenceException.move(
        originalLocalDateTime: original,
        movedToLocalDateTime: moved,
      ).movedToLocalDateTime,
      moved,
    );
    expect(
      () => RecurrenceException.move(
        originalLocalDateTime: original,
        movedToLocalDateTime: original,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
