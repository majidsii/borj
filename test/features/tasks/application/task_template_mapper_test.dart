import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/application/task_template_mapper.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TaskTemplateMapper();
  final now = DateTime.utc(2026, 8, 8, 5);

  TaskTemplate template({
    List<TaskTemplateReminderDefault> reminders = const [],
    TaskTemplateRecurrence? recurrence,
  }) {
    return TaskTemplate(
      id: 'template-1',
      kind: TaskTemplateKind.custom,
      templateName: 'قالب تمرکز',
      initialTaskTitle: 'کار روی …',
      description: 'توضیح قابل استفاده مجدد',
      priority: 3,
      estimatedDurationMinutes: 125,
      reminderDefaults: reminders,
      recurrenceDefault: recurrence,
      hidden: false,
      displayOrder: 0,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  test('template maps reusable values into a new unscheduled task draft', () {
    final recurrence = TaskTemplateRecurrence(
      frequency: RecurrenceFrequency.daily,
      interval: 1,
      calendar: RecurrenceCalendar.gregorian,
      timeZone: const RecurrenceTimeZone.floating(),
      weeklyDays: const <RecurrenceWeekday>{},
      monthlySelectors: const [],
      annualDates: const [],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      end: TaskTemplateRecurrenceEnd.daysAfterAnchor(30),
    );

    final draft = mapper.toTaskDetailsDraft(
      template(
        reminders: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.oneDayBefore,
            privacyMode: NotificationPrivacyMode.private,
          ),
        ],
        recurrence: recurrence,
      ),
    );

    expect(draft.title, 'کار روی …');
    expect(draft.description, 'توضیح قابل استفاده مجدد');
    expect(draft.priority, 3);
    expect(draft.estimatedHours, 2);
    expect(draft.estimatedMinutes, 5);

    expect(draft.startLocal, isNull);
    expect(draft.dueLocal, isNull);

    final selected = draft.reminders.where((item) => item.selected).toList();
    expect(selected, hasLength(1));
    expect(selected.single.trigger, TaskReminderTrigger.oneDayBefore);
    expect(selected.single.existingId, isNull);
    expect(selected.single.createdAtUtc, isNull);

    expect(draft.recurrence.enabled, isTrue);
    expect(draft.recurrence.existingId, isNull);
    expect(draft.recurrence.existingCreatedAtUtc, isNull);
    expect(draft.recurrence.relativeEndDaysAfterAnchor, 30);
  });
}
