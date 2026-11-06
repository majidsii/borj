import 'dart:collection';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';

final class RecurrenceRule {
  factory RecurrenceRule.daily({
    required RecurrenceLocalDateTime anchorLocalDateTime,
    int interval = 1,
    RecurrenceCalendar calendar = RecurrenceCalendar.gregorian,
    RecurrenceTimeZone timeZone = const RecurrenceTimeZone.floating(),
    RecurrenceEnd end = const RecurrenceEnd.never(),
  }) {
    return RecurrenceRule._(
      frequency: RecurrenceFrequency.daily,
      interval: interval,
      calendar: calendar,
      anchorLocalDateTime: anchorLocalDateTime,
      timeZone: timeZone,
      end: end,
      weeklyDays: const <RecurrenceWeekday>{},
      monthlySelectors: const <RecurrenceMonthSelector>[],
      annualDates: const <RecurrenceAnnualDate>[],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
    );
  }

  factory RecurrenceRule.weekly({
    required RecurrenceLocalDateTime anchorLocalDateTime,
    required Set<RecurrenceWeekday> weeklyDays,
    int interval = 1,
    RecurrenceCalendar calendar = RecurrenceCalendar.gregorian,
    RecurrenceTimeZone timeZone = const RecurrenceTimeZone.floating(),
    RecurrenceEnd end = const RecurrenceEnd.never(),
  }) {
    if (weeklyDays.isEmpty) {
      throw const ValidationFailure(
        'تکرار هفتگی باید حداقل یک روز هفته داشته باشد.',
      );
    }
    return RecurrenceRule._(
      frequency: RecurrenceFrequency.weekly,
      interval: interval,
      calendar: calendar,
      anchorLocalDateTime: anchorLocalDateTime,
      timeZone: timeZone,
      end: end,
      weeklyDays: weeklyDays,
      monthlySelectors: const <RecurrenceMonthSelector>[],
      annualDates: const <RecurrenceAnnualDate>[],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
    );
  }

  factory RecurrenceRule.monthly({
    required RecurrenceLocalDateTime anchorLocalDateTime,
    required List<RecurrenceMonthSelector> monthlySelectors,
    int interval = 1,
    RecurrenceCalendar calendar = RecurrenceCalendar.gregorian,
    RecurrenceTimeZone timeZone = const RecurrenceTimeZone.floating(),
    RecurrenceEnd end = const RecurrenceEnd.never(),
    RecurrenceInvalidDatePolicy invalidDatePolicy =
        RecurrenceInvalidDatePolicy.skipPeriod,
  }) {
    if (monthlySelectors.isEmpty) {
      throw const ValidationFailure(
        'تکرار ماهانه باید حداقل یک انتخاب روز داشته باشد.',
      );
    }
    return RecurrenceRule._(
      frequency: RecurrenceFrequency.monthly,
      interval: interval,
      calendar: calendar,
      anchorLocalDateTime: anchorLocalDateTime,
      timeZone: timeZone,
      end: end,
      weeklyDays: const <RecurrenceWeekday>{},
      monthlySelectors: monthlySelectors,
      annualDates: const <RecurrenceAnnualDate>[],
      invalidDatePolicy: invalidDatePolicy,
    );
  }

  factory RecurrenceRule.yearly({
    required RecurrenceLocalDateTime anchorLocalDateTime,
    required List<RecurrenceAnnualDate> annualDates,
    int interval = 1,
    RecurrenceCalendar calendar = RecurrenceCalendar.gregorian,
    RecurrenceTimeZone timeZone = const RecurrenceTimeZone.floating(),
    RecurrenceEnd end = const RecurrenceEnd.never(),
    RecurrenceInvalidDatePolicy invalidDatePolicy =
        RecurrenceInvalidDatePolicy.skipPeriod,
  }) {
    if (annualDates.isEmpty) {
      throw const ValidationFailure(
        'تکرار سالانه باید حداقل یک تاریخ داشته باشد.',
      );
    }
    return RecurrenceRule._(
      frequency: RecurrenceFrequency.yearly,
      interval: interval,
      calendar: calendar,
      anchorLocalDateTime: anchorLocalDateTime,
      timeZone: timeZone,
      end: end,
      weeklyDays: const <RecurrenceWeekday>{},
      monthlySelectors: const <RecurrenceMonthSelector>[],
      annualDates: annualDates,
      invalidDatePolicy: invalidDatePolicy,
    );
  }

  RecurrenceRule._({
    required this.frequency,
    required this.interval,
    required this.calendar,
    required this.anchorLocalDateTime,
    required this.timeZone,
    required this.end,
    required Set<RecurrenceWeekday> weeklyDays,
    required List<RecurrenceMonthSelector> monthlySelectors,
    required List<RecurrenceAnnualDate> annualDates,
    required this.invalidDatePolicy,
  }) : weeklyDays = UnmodifiableSetView<RecurrenceWeekday>(
         Set<RecurrenceWeekday>.from(weeklyDays),
       ),
       monthlySelectors = UnmodifiableListView<RecurrenceMonthSelector>(
         List<RecurrenceMonthSelector>.from(monthlySelectors),
       ),
       annualDates = UnmodifiableListView<RecurrenceAnnualDate>(
         List<RecurrenceAnnualDate>.from(annualDates),
       ) {
    if (interval < 1) {
      throw const ValidationFailure('فاصله تکرار باید حداقل یک باشد.');
    }
  }

  final RecurrenceFrequency frequency;
  final int interval;
  final RecurrenceCalendar calendar;
  final RecurrenceLocalDateTime anchorLocalDateTime;
  final RecurrenceTimeZone timeZone;
  final RecurrenceEnd end;
  final Set<RecurrenceWeekday> weeklyDays;
  final List<RecurrenceMonthSelector> monthlySelectors;
  final List<RecurrenceAnnualDate> annualDates;
  final RecurrenceInvalidDatePolicy invalidDatePolicy;
}
