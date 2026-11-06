import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/data/task_recurrence_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = TaskRecurrenceCodec();

  test('daily rule round-trips with fixed timezone and count', () {
    final rule = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 6, 9, 30),
      interval: 2,
      calendar: RecurrenceCalendar.gregorian,
      timeZone: RecurrenceTimeZone.fixed('Europe/Amsterdam'),
      end: RecurrenceEnd.afterCount(7),
    );

    final decoded = codec.decodeRule(codec.encodeRule(rule));

    expect(decoded.frequency, rule.frequency);
    expect(decoded.interval, 2);
    expect(decoded.anchorLocalDateTime, rule.anchorLocalDateTime);
    expect(decoded.timeZone, rule.timeZone);
    expect(decoded.end, rule.end);
  });

  test('jalali monthly selectors and invalid-date policy round-trip', () {
    final rule = RecurrenceRule.monthly(
      anchorLocalDateTime: _local(1405, 5, 15, 8),
      monthlySelectors: <RecurrenceMonthSelector>[
        RecurrenceMonthSelector.dayOfMonth(5),
        RecurrenceMonthSelector.dayOfMonth(20),
        const RecurrenceMonthSelector.lastDay(),
      ],
      calendar: RecurrenceCalendar.jalali,
      invalidDatePolicy: RecurrenceInvalidDatePolicy.clampToLastDay,
    );

    final decoded = codec.decodeRule(codec.encodeRule(rule));

    expect(decoded.calendar, RecurrenceCalendar.jalali);
    expect(decoded.monthlySelectors, rule.monthlySelectors);
    expect(
      decoded.invalidDatePolicy,
      RecurrenceInvalidDatePolicy.clampToLastDay,
    );
  });

  test('move exception preserves original and effective local keys', () {
    final exception = RecurrenceException.move(
      originalLocalDateTime: _local(1405, 5, 20, 9),
      movedToLocalDateTime: _local(1405, 5, 22, 11, 15),
    );

    final decoded = codec.decodeException(codec.encodeException(exception));

    expect(decoded.action, RecurrenceExceptionAction.move);
    expect(decoded.originalLocalDateTime, exception.originalLocalDateTime);
    expect(decoded.movedToLocalDateTime, exception.movedToLocalDateTime);
  });

  test('rejects unknown codec version', () {
    expect(() => codec.decodeRule('{"version":99}'), throwsA(isA<Exception>()));
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
