import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';

final class TaskTemplateRecurrenceDraft {
  TaskTemplateRecurrenceDraft({
    required this.enabled,
    required this.frequency,
    required this.interval,
    required this.calendar,
    required this.timeZoneMode,
    required this.fixedTimeZoneId,
    required Set<RecurrenceWeekday> weeklyDays,
    required this.monthlyDaysText,
    required this.includeLastDay,
    required this.annualDatesText,
    required this.invalidDatePolicy,
    required this.endKind,
    required this.afterCount,
    required this.daysAfterAnchor,
  }) : weeklyDays = Set<RecurrenceWeekday>.from(weeklyDays);

  factory TaskTemplateRecurrenceDraft.create() {
    return TaskTemplateRecurrenceDraft(
      enabled: false,
      frequency: RecurrenceFrequency.daily,
      interval: 1,
      calendar: RecurrenceCalendar.gregorian,
      timeZoneMode: RecurrenceTimeZoneMode.floating,
      fixedTimeZoneId: 'Asia/Tehran',
      weeklyDays: const <RecurrenceWeekday>{},
      monthlyDaysText: '',
      includeLastDay: false,
      annualDatesText: '',
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      endKind: TaskTemplateRecurrenceEndKind.never,
      afterCount: 10,
      daysAfterAnchor: 30,
    );
  }

  factory TaskTemplateRecurrenceDraft.fromRecurrence(
    TaskTemplateRecurrence? source,
  ) {
    if (source == null) return TaskTemplateRecurrenceDraft.create();

    return TaskTemplateRecurrenceDraft(
      enabled: true,
      frequency: source.frequency,
      interval: source.interval,
      calendar: source.calendar,
      timeZoneMode: source.timeZone.mode,
      fixedTimeZoneId: source.timeZone.fixedTimeZoneId ?? 'Asia/Tehran',
      weeklyDays: source.weeklyDays,
      monthlyDaysText: source.monthlySelectors
          .where((item) => item.kind == RecurrenceMonthSelectorKind.dayOfMonth)
          .map((item) => item.day.toString())
          .join(', '),
      includeLastDay: source.monthlySelectors.any(
        (item) => item.kind == RecurrenceMonthSelectorKind.lastDay,
      ),
      annualDatesText: source.annualDates
          .map((item) => '${item.month}/${item.day}')
          .join(', '),
      invalidDatePolicy: source.invalidDatePolicy,
      endKind: source.end.kind,
      afterCount: source.end.count ?? 10,
      daysAfterAnchor: source.end.days ?? 30,
    );
  }

  bool enabled;
  RecurrenceFrequency frequency;
  int interval;
  RecurrenceCalendar calendar;
  RecurrenceTimeZoneMode timeZoneMode;
  String fixedTimeZoneId;
  final Set<RecurrenceWeekday> weeklyDays;
  String monthlyDaysText;
  bool includeLastDay;
  String annualDatesText;
  RecurrenceInvalidDatePolicy invalidDatePolicy;
  TaskTemplateRecurrenceEndKind endKind;
  int afterCount;
  int daysAfterAnchor;

  String? validate() {
    if (!enabled) return null;
    if (interval < 1) return 'فاصله تکرار باید حداقل یک باشد.';
    if (timeZoneMode == RecurrenceTimeZoneMode.fixed &&
        fixedTimeZoneId.trim().isEmpty) {
      return 'منطقه زمانی ثابت نمی‌تواند خالی باشد.';
    }
    if (frequency == RecurrenceFrequency.weekly && weeklyDays.isEmpty) {
      return 'برای تکرار هفتگی حداقل یک روز را انتخاب کنید.';
    }
    if (frequency == RecurrenceFrequency.monthly &&
        _monthlySelectors().isEmpty) {
      return 'برای تکرار ماهانه حداقل یک روز را مشخص کنید.';
    }
    if (frequency == RecurrenceFrequency.yearly && _annualDates().isEmpty) {
      return 'برای تکرار سالانه حداقل یک تاریخ را مشخص کنید.';
    }
    if (endKind == TaskTemplateRecurrenceEndKind.afterCount && afterCount < 1) {
      return 'تعداد رخدادها باید حداقل یک باشد.';
    }
    if (endKind == TaskTemplateRecurrenceEndKind.daysAfterAnchor &&
        daysAfterAnchor < 1) {
      return 'فاصله پایان از زمان مبنا باید حداقل یک روز باشد.';
    }
    return null;
  }

  TaskTemplateRecurrence? build() {
    if (!enabled) return null;
    final error = validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final timeZone = switch (timeZoneMode) {
      RecurrenceTimeZoneMode.floating => const RecurrenceTimeZone.floating(),
      RecurrenceTimeZoneMode.fixed => RecurrenceTimeZone.fixed(
        fixedTimeZoneId.trim(),
      ),
    };

    final end = switch (endKind) {
      TaskTemplateRecurrenceEndKind.never =>
        const TaskTemplateRecurrenceEnd.never(),
      TaskTemplateRecurrenceEndKind.afterCount =>
        TaskTemplateRecurrenceEnd.afterCount(afterCount),
      TaskTemplateRecurrenceEndKind.daysAfterAnchor =>
        TaskTemplateRecurrenceEnd.daysAfterAnchor(daysAfterAnchor),
    };

    return TaskTemplateRecurrence(
      frequency: frequency,
      interval: interval,
      calendar: calendar,
      timeZone: timeZone,
      weeklyDays: weeklyDays,
      monthlySelectors: _monthlySelectors(),
      annualDates: _annualDates(),
      invalidDatePolicy: invalidDatePolicy,
      end: end,
    );
  }

  List<RecurrenceMonthSelector> _monthlySelectors() {
    final output = <RecurrenceMonthSelector>[];
    final seen = <int>{};
    for (final token in monthlyDaysText.split(',')) {
      final day = int.tryParse(token.trim());
      if (day != null && day >= 1 && day <= 31 && seen.add(day)) {
        output.add(RecurrenceMonthSelector.dayOfMonth(day));
      }
    }
    if (includeLastDay) {
      output.add(const RecurrenceMonthSelector.lastDay());
    }
    return output;
  }

  List<RecurrenceAnnualDate> _annualDates() {
    final output = <RecurrenceAnnualDate>[];
    final seen = <String>{};
    for (final token in annualDatesText.split(',')) {
      final parts = token.trim().split('/');
      if (parts.length != 2) continue;
      final month = int.tryParse(parts[0].trim());
      final day = int.tryParse(parts[1].trim());
      if (month == null || day == null) continue;
      final key = '$month/$day';
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && seen.add(key)) {
        output.add(RecurrenceAnnualDate(month: month, day: day));
      }
    }
    return output;
  }
}
