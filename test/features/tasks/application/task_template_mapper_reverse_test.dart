import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/application/task_template_mapper.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TaskTemplateMapper();
  final savedAt = DateTime.utc(2026, 8, 8, 5);

  TaskDetailsDraft source({
    DateTime? start,
    DateTime? due,
    TaskRecurrenceDraft? recurrence,
  }) {
    return TaskDetailsDraft(
      title: 'عنوان کار فعلی',
      description: 'شرح فعلی',
      priority: 2,
      startLocal: start,
      dueLocal: due,
      estimatedHours: 1,
      estimatedMinutes: 15,
      reminders: <TaskReminderDraft>[
        const TaskReminderDraft(
          trigger: TaskReminderTrigger.atDue,
          selected: true,
          privacyMode: NotificationPrivacyMode.private,
          existingId: 'old-reminder',
          createdAtUtc: null,
        ),
        const TaskReminderDraft(
          trigger: TaskReminderTrigger.oneDayBefore,
          selected: false,
          privacyMode: NotificationPrivacyMode.full,
          existingId: 'old-disabled',
          createdAtUtc: null,
        ),
        TaskReminderDraft.empty(TaskReminderTrigger.fifteenMinutesBefore),
        TaskReminderDraft.empty(TaskReminderTrigger.oneHourBefore),
      ],
      recurrence: recurrence ?? TaskRecurrenceDraft.disabled(),
    );
  }

  test('task draft -> custom template strips schedule and identities', () {
    final result = mapper.toCustomTemplate(
      source: source(
        start: DateTime(2026, 8, 10, 8),
        due: DateTime(2026, 8, 10, 10),
      ),
      id: 'template-new',
      templateName: 'قالب ذخیره‌شده',
      displayOrder: 4,
      savedAtUtc: savedAt,
    );

    expect(result.kind, TaskTemplateKind.custom);
    expect(result.systemKey, isNull);
    expect(result.initialTaskTitle, 'عنوان کار فعلی');
    expect(result.description, 'شرح فعلی');
    expect(result.priority, 2);
    expect(result.estimatedDurationMinutes, 75);
    expect(result.displayOrder, 4);
    expect(result.hidden, isFalse);
    expect(result.reminderDefaults, hasLength(1));
    expect(result.reminderDefaults.single.trigger, TaskReminderTrigger.atDue);
    expect(result.recurrenceDefault, isNull);
  });

  test('fixed until becomes relative days from recurrence anchor', () {
    final anchor = DateTime(2026, 8, 10, 9);
    final recurrence = TaskRecurrenceDraft(
      enabled: true,
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
      endKind: RecurrenceEndKind.until,
      untilLocal: DateTime(2026, 9, 9, 9),
      afterCount: 10,
      existingId: 'old-recurrence',
      existingCreatedAtUtc: DateTime.utc(2026, 7, 1),
    );

    final result = mapper.toCustomTemplate(
      source: source(due: anchor, recurrence: recurrence),
      id: 'relative-template',
      templateName: 'قالب نسبی',
      displayOrder: 0,
      savedAtUtc: savedAt,
    );

    expect(result.recurrenceDefault, isNotNull);
    expect(
      result.recurrenceDefault!.end.kind,
      TaskTemplateRecurrenceEndKind.daysAfterAnchor,
    );
    expect(result.recurrenceDefault!.end.days, 30);
  });

  test('fixed until without recurrence anchor is rejected', () {
    final recurrence = TaskRecurrenceDraft(
      enabled: true,
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
      endKind: RecurrenceEndKind.until,
      untilLocal: DateTime(2026, 9, 9, 9),
      afterCount: 10,
    );

    expect(
      () => mapper.toCustomTemplate(
        source: source(recurrence: recurrence),
        id: 'invalid-template',
        templateName: 'قالب نامعتبر',
        displayOrder: 0,
        savedAtUtc: savedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'template creates fresh reminder and recurrence identities when saved',
    () {
      final template = TaskTemplate(
        id: 'source-template',
        kind: TaskTemplateKind.custom,
        templateName: 'قالب',
        initialTaskTitle: 'کار …',
        priority: 1,
        reminderDefaults: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.atDue,
            privacyMode: NotificationPrivacyMode.full,
          ),
        ],
        recurrenceDefault: TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          calendar: RecurrenceCalendar.gregorian,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const <RecurrenceWeekday>{},
          monthlySelectors: const [],
          annualDates: const [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: TaskTemplateRecurrenceEnd.daysAfterAnchor(7),
        ),
        hidden: false,
        displayOrder: 0,
        createdAtUtc: savedAt,
        updatedAtUtc: savedAt,
      );

      final draft = mapper.toTaskDetailsDraft(template)
        ..dueLocal = DateTime(2026, 8, 10, 12);
      var i = 0;
      String nextId() => 'fresh-${++i}';

      final reminders = draft.buildReminderRules(
        taskId: 'new-task',
        savedAtUtc: savedAt,
        nextId: nextId,
      );
      final recurrence = draft.buildRecurrenceRule(
        taskId: 'new-task',
        savedAtUtc: savedAt,
        nextId: nextId,
      );

      expect(reminders.single.id, 'fresh-1');
      expect(recurrence!.id, 'fresh-2');
      expect(recurrence.createdAtUtc, savedAt);
    },
  );
}
