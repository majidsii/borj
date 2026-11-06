import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_draft.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_recurrence_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 6);

  test('new draft allows blank initial title but requires template name', () {
    final draft = TaskTemplateDraft.create();

    expect(draft.initialTaskTitle, isEmpty);
    expect(draft.validate(), isNotNull);

    draft.templateName = 'قالب بدون عنوان اولیه';

    expect(draft.validate(), isNull);
  });

  test('draft round-trips reusable custom template values', () {
    final recurrence = TaskTemplateRecurrence(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      calendar: RecurrenceCalendar.gregorian,
      timeZone: const RecurrenceTimeZone.floating(),
      weeklyDays: const <RecurrenceWeekday>{
        RecurrenceWeekday.monday,
        RecurrenceWeekday.friday,
      },
      monthlySelectors: const [],
      annualDates: const [],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      end: TaskTemplateRecurrenceEnd.afterCount(8),
    );

    final source = TaskTemplate(
      id: 'custom-source',
      kind: TaskTemplateKind.custom,
      templateName: 'قالب هفتگی',
      initialTaskTitle: 'پیگیری …',
      description: 'شرح',
      priority: 2,
      estimatedDurationMinutes: 95,
      reminderDefaults: const <TaskTemplateReminderDefault>[
        TaskTemplateReminderDefault(
          trigger: TaskReminderTrigger.oneHourBefore,
          privacyMode: NotificationPrivacyMode.private,
        ),
      ],
      recurrenceDefault: recurrence,
      hidden: false,
      displayOrder: 3,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    final draft = TaskTemplateDraft.fromTemplate(source);

    expect(draft.templateName, 'قالب هفتگی');
    expect(draft.initialTaskTitle, 'پیگیری …');
    expect(draft.description, 'شرح');
    expect(draft.priority, 2);
    expect(draft.estimatedHours, 1);
    expect(draft.estimatedMinutes, 35);
    expect(draft.reminderDefaults, source.reminderDefaults);
    expect(draft.recurrence.enabled, isTrue);
    expect(draft.recurrence.frequency, RecurrenceFrequency.weekly);
    expect(draft.recurrence.afterCount, 8);

    final built = draft.buildCustom(
      id: 'custom-new',
      displayOrder: 4,
      savedAtUtc: now.add(const Duration(hours: 1)),
    );

    expect(built.kind, TaskTemplateKind.custom);
    expect(built.systemKey, isNull);
    expect(built.templateName, source.templateName);
    expect(built.initialTaskTitle, source.initialTaskTitle);
    expect(built.estimatedDurationMinutes, 95);
    expect(built.recurrenceDefault!.end.count, 8);
  });

  test('recurrence draft supports relative days after anchor', () {
    final draft = TaskTemplateRecurrenceDraft.create()
      ..enabled = true
      ..frequency = RecurrenceFrequency.daily
      ..daysAfterAnchor = 30
      ..endKind = TaskTemplateRecurrenceEndKind.daysAfterAnchor;

    expect(draft.validate(), isNull);

    final built = draft.build();

    expect(built, isNotNull);
    expect(built!.end.kind, TaskTemplateRecurrenceEndKind.daysAfterAnchor);
    expect(built.end.days, 30);
  });
}
