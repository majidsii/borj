import 'dart:collection';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';

enum TaskTemplateRecurrenceEndKind { never, afterCount, daysAfterAnchor }

final class TaskTemplateRecurrenceEnd {
  const TaskTemplateRecurrenceEnd.never()
    : kind = TaskTemplateRecurrenceEndKind.never,
      count = null,
      days = null;

  factory TaskTemplateRecurrenceEnd.afterCount(int count) {
    if (count < 1) {
      throw const ValidationFailure(
        'تعداد رخدادهای پایان قالب باید حداقل یک باشد.',
      );
    }

    return TaskTemplateRecurrenceEnd._(
      kind: TaskTemplateRecurrenceEndKind.afterCount,
      count: count,
      days: null,
    );
  }

  factory TaskTemplateRecurrenceEnd.daysAfterAnchor(int days) {
    if (days < 1) {
      throw const ValidationFailure(
        'فاصله پایان تکرار از تاریخ مبنا باید حداقل یک روز باشد.',
      );
    }

    return TaskTemplateRecurrenceEnd._(
      kind: TaskTemplateRecurrenceEndKind.daysAfterAnchor,
      count: null,
      days: days,
    );
  }

  const TaskTemplateRecurrenceEnd._({
    required this.kind,
    required this.count,
    required this.days,
  });

  final TaskTemplateRecurrenceEndKind kind;
  final int? count;
  final int? days;

  @override
  bool operator ==(Object other) {
    return other is TaskTemplateRecurrenceEnd &&
        other.kind == kind &&
        other.count == count &&
        other.days == days;
  }

  @override
  int get hashCode => Object.hash(kind, count, days);
}

final class TaskTemplateRecurrence {
  TaskTemplateRecurrence({
    required this.frequency,
    required this.interval,
    required this.calendar,
    required this.timeZone,
    required Set<RecurrenceWeekday> weeklyDays,
    required List<RecurrenceMonthSelector> monthlySelectors,
    required List<RecurrenceAnnualDate> annualDates,
    required this.invalidDatePolicy,
    required this.end,
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
      throw const ValidationFailure('فاصله تکرار قالب باید حداقل یک باشد.');
    }

    if (timeZone.mode == RecurrenceTimeZoneMode.fixed &&
        (timeZone.fixedTimeZoneId == null ||
            timeZone.fixedTimeZoneId!.trim().isEmpty)) {
      throw const ValidationFailure(
        'منطقه زمانی ثابت قالب نمی‌تواند خالی باشد.',
      );
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        if (this.weeklyDays.isNotEmpty ||
            this.monthlySelectors.isNotEmpty ||
            this.annualDates.isNotEmpty) {
          throw const ValidationFailure(
            'تکرار روزانه قالب نمی‌تواند انتخاب هفتگی، ماهانه یا سالانه داشته باشد.',
          );
        }

      case RecurrenceFrequency.weekly:
        if (this.weeklyDays.isEmpty) {
          throw const ValidationFailure(
            'تکرار هفتگی قالب باید حداقل یک روز هفته داشته باشد.',
          );
        }
        if (this.monthlySelectors.isNotEmpty || this.annualDates.isNotEmpty) {
          throw const ValidationFailure(
            'تکرار هفتگی قالب نمی‌تواند انتخاب ماهانه یا سالانه داشته باشد.',
          );
        }

      case RecurrenceFrequency.monthly:
        if (this.monthlySelectors.isEmpty) {
          throw const ValidationFailure(
            'تکرار ماهانه قالب باید حداقل یک انتخاب روز داشته باشد.',
          );
        }
        if (this.weeklyDays.isNotEmpty || this.annualDates.isNotEmpty) {
          throw const ValidationFailure(
            'تکرار ماهانه قالب نمی‌تواند انتخاب هفتگی یا سالانه داشته باشد.',
          );
        }

      case RecurrenceFrequency.yearly:
        if (this.annualDates.isEmpty) {
          throw const ValidationFailure(
            'تکرار سالانه قالب باید حداقل یک تاریخ داشته باشد.',
          );
        }
        if (this.weeklyDays.isNotEmpty || this.monthlySelectors.isNotEmpty) {
          throw const ValidationFailure(
            'تکرار سالانه قالب نمی‌تواند انتخاب هفتگی یا ماهانه داشته باشد.',
          );
        }
    }
  }

  final RecurrenceFrequency frequency;
  final int interval;
  final RecurrenceCalendar calendar;
  final RecurrenceTimeZone timeZone;
  final Set<RecurrenceWeekday> weeklyDays;
  final List<RecurrenceMonthSelector> monthlySelectors;
  final List<RecurrenceAnnualDate> annualDates;
  final RecurrenceInvalidDatePolicy invalidDatePolicy;
  final TaskTemplateRecurrenceEnd end;
}
