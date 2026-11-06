import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskTemplateRecurrenceEnd', () {
    test('supports never', () {
      const end = TaskTemplateRecurrenceEnd.never();

      expect(end.kind, TaskTemplateRecurrenceEndKind.never);
      expect(end.count, isNull);
      expect(end.days, isNull);
    });

    test('afterCount requires at least one occurrence', () {
      expect(
        () => TaskTemplateRecurrenceEnd.afterCount(0),
        throwsA(isA<ValidationFailure>()),
      );

      final end = TaskTemplateRecurrenceEnd.afterCount(3);

      expect(end.kind, TaskTemplateRecurrenceEndKind.afterCount);
      expect(end.count, 3);
    });

    test('daysAfterAnchor requires at least one day', () {
      expect(
        () => TaskTemplateRecurrenceEnd.daysAfterAnchor(0),
        throwsA(isA<ValidationFailure>()),
      );

      final end = TaskTemplateRecurrenceEnd.daysAfterAnchor(30);

      expect(end.kind, TaskTemplateRecurrenceEndKind.daysAfterAnchor);
      expect(end.days, 30);
    });
  });

  group('TaskTemplateRecurrence', () {
    test('rejects interval below one', () {
      expect(
        () => TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.daily,
          interval: 0,
          calendar: RecurrenceCalendar.gregorian,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const {},
          monthlySelectors: [],
          annualDates: [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: const TaskTemplateRecurrenceEnd.never(),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('weekly recurrence requires at least one weekday', () {
      expect(
        () => TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          calendar: RecurrenceCalendar.gregorian,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const {},
          monthlySelectors: [],
          annualDates: [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: const TaskTemplateRecurrenceEnd.never(),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final recurrence = TaskTemplateRecurrence(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        calendar: RecurrenceCalendar.gregorian,
        timeZone: const RecurrenceTimeZone.floating(),
        weeklyDays: const {RecurrenceWeekday.monday},
        monthlySelectors: [],
        annualDates: [],
        invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
        end: const TaskTemplateRecurrenceEnd.never(),
      );

      expect(recurrence.weeklyDays, {RecurrenceWeekday.monday});
    });

    test('monthly recurrence requires at least one selector', () {
      expect(
        () => TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          calendar: RecurrenceCalendar.gregorian,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const {},
          monthlySelectors: [],
          annualDates: [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: const TaskTemplateRecurrenceEnd.never(),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final recurrence = TaskTemplateRecurrence(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        calendar: RecurrenceCalendar.gregorian,
        timeZone: const RecurrenceTimeZone.floating(),
        weeklyDays: const {},
        monthlySelectors: [RecurrenceMonthSelector.dayOfMonth(15)],
        annualDates: [],
        invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
        end: const TaskTemplateRecurrenceEnd.never(),
      );

      expect(recurrence.monthlySelectors, hasLength(1));
    });

    test('yearly recurrence requires at least one annual date', () {
      expect(
        () => TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.yearly,
          interval: 1,
          calendar: RecurrenceCalendar.jalali,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const {},
          monthlySelectors: [],
          annualDates: [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: const TaskTemplateRecurrenceEnd.never(),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final recurrence = TaskTemplateRecurrence(
        frequency: RecurrenceFrequency.yearly,
        interval: 1,
        calendar: RecurrenceCalendar.jalali,
        timeZone: const RecurrenceTimeZone.floating(),
        weeklyDays: const {},
        monthlySelectors: [],
        annualDates: [RecurrenceAnnualDate(month: 1, day: 1)],
        invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
        end: const TaskTemplateRecurrenceEnd.never(),
      );

      expect(recurrence.annualDates, hasLength(1));
    });
  });
}
