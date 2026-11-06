import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_draft.dart';

final class TaskTemplateMapper {
  const TaskTemplateMapper();

  TaskDetailsDraft toTaskDetailsDraft(TaskTemplate template) {
    final duration = template.estimatedDurationMinutes ?? 0;
    final byTrigger = <TaskReminderTrigger, TaskTemplateReminderDefault>{
      for (final reminder in template.reminderDefaults)
        reminder.trigger: reminder,
    };

    return TaskDetailsDraft(
      title: template.initialTaskTitle,
      description: template.description ?? '',
      priority: template.priority,
      startLocal: null,
      dueLocal: null,
      estimatedHours: duration ~/ 60,
      estimatedMinutes: duration % 60,
      reminders: TaskReminderTrigger.values
          .map((trigger) {
            final reminder = byTrigger[trigger];
            return reminder == null
                ? TaskReminderDraft.empty(trigger)
                : TaskReminderDraft(
                    trigger: trigger,
                    selected: true,
                    privacyMode: reminder.privacyMode,
                  );
          })
          .toList(growable: false),
      recurrence: _toTaskRecurrence(template.recurrenceDefault),
    );
  }

  TaskTemplate toCustomTemplate({
    required TaskDetailsDraft source,
    required String id,
    required String templateName,
    required int displayOrder,
    required DateTime savedAtUtc,
  }) {
    final totalMinutes = source.estimatedHours * 60 + source.estimatedMinutes;
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.custom,
      templateName: templateName,
      initialTaskTitle: source.title,
      description: source.description,
      priority: source.priority,
      estimatedDurationMinutes: totalMinutes == 0 ? null : totalMinutes,
      reminderDefaults: source.reminders
          .where((item) => item.selected)
          .map(
            (item) => TaskTemplateReminderDefault(
              trigger: item.trigger,
              privacyMode: item.privacyMode,
            ),
          )
          .toList(growable: false),
      recurrenceDefault: _fromTaskRecurrence(source),
      hidden: false,
      displayOrder: displayOrder,
      createdAtUtc: savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }

  TaskRecurrenceDraft _toTaskRecurrence(TaskTemplateRecurrence? source) {
    if (source == null) return TaskRecurrenceDraft.disabled();
    return TaskRecurrenceDraft(
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
      endKind: switch (source.end.kind) {
        TaskTemplateRecurrenceEndKind.never => RecurrenceEndKind.never,
        TaskTemplateRecurrenceEndKind.afterCount =>
          RecurrenceEndKind.afterCount,
        TaskTemplateRecurrenceEndKind.daysAfterAnchor =>
          RecurrenceEndKind.until,
      },
      untilLocal: null,
      afterCount: source.end.count ?? 10,
      relativeEndDaysAfterAnchor: source.end.days,
    );
  }

  TaskTemplateRecurrence? _fromTaskRecurrence(TaskDetailsDraft source) {
    final draft = source.recurrence;
    if (!draft.enabled) return null;

    final timeZone = switch (draft.timeZoneMode) {
      RecurrenceTimeZoneMode.floating => const RecurrenceTimeZone.floating(),
      RecurrenceTimeZoneMode.fixed => RecurrenceTimeZone.fixed(
        draft.fixedTimeZoneId.trim(),
      ),
    };

    final end = switch (draft.endKind) {
      RecurrenceEndKind.never => const TaskTemplateRecurrenceEnd.never(),
      RecurrenceEndKind.afterCount => TaskTemplateRecurrenceEnd.afterCount(
        draft.afterCount,
      ),
      RecurrenceEndKind.until => _relativeEnd(source),
    };

    return TaskTemplateRecurrence(
      frequency: draft.frequency,
      interval: draft.interval,
      calendar: draft.calendar,
      timeZone: timeZone,
      weeklyDays: draft.weeklyDays,
      monthlySelectors: _monthlySelectors(draft),
      annualDates: _annualDates(draft),
      invalidDatePolicy: draft.invalidDatePolicy,
      end: end,
    );
  }

  TaskTemplateRecurrenceEnd _relativeEnd(TaskDetailsDraft source) {
    final linkedDays = source.recurrence.relativeEndDaysAfterAnchor;
    if (linkedDays != null) {
      return TaskTemplateRecurrenceEnd.daysAfterAnchor(linkedDays);
    }
    final anchor = source.dueLocal ?? source.startLocal;
    final until = source.recurrence.untilLocal;
    if (anchor == null || until == null) {
      throw const ValidationFailure(
        'برای ذخیره پایان تکرار در قالب، زمان مبنا و پایان لازم است.',
      );
    }
    final anchorDate = DateTime.utc(anchor.year, anchor.month, anchor.day);
    final untilDate = DateTime.utc(until.year, until.month, until.day);
    final days = untilDate.difference(anchorDate).inDays;
    if (days < 1) {
      throw const ValidationFailure(
        'پایان تکرار قالب باید حداقل یک روز بعد از زمان مبنا باشد.',
      );
    }
    return TaskTemplateRecurrenceEnd.daysAfterAnchor(days);
  }

  List<RecurrenceMonthSelector> _monthlySelectors(TaskRecurrenceDraft draft) {
    final output = <RecurrenceMonthSelector>[];
    final seen = <int>{};
    for (final token in draft.monthlyDaysText.split(',')) {
      final value = int.tryParse(token.trim());
      if (value != null && value >= 1 && value <= 31 && seen.add(value)) {
        output.add(RecurrenceMonthSelector.dayOfMonth(value));
      }
    }
    if (draft.includeLastDay) {
      output.add(const RecurrenceMonthSelector.lastDay());
    }
    return output;
  }

  List<RecurrenceAnnualDate> _annualDates(TaskRecurrenceDraft draft) {
    final output = <RecurrenceAnnualDate>[];
    final seen = <String>{};
    for (final token in draft.annualDatesText.split(',')) {
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
