import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/tasks/application/task_reminder_projector.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projector = TaskReminderProjector();
  final now = DateTime.utc(2026, 8, 6, 8);
  final task = TaskItem(
    id: 'task',
    displayNumber: 1,
    title: 'جلسه روزانه',
    priority: 1,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: DateTime.utc(2026, 8, 7, 9),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
  final rule = TaskReminderRule(
    id: 'reminder',
    taskId: task.id,
    trigger: TaskReminderTrigger.oneHourBefore,
    createdAtUtc: now,
    updatedAtUtc: now,
  );

  test('recurring reminders use stable occurrence-scoped schedule ids', () {
    final occurrence = _occurrence(
      task: task,
      local: _local(2026, 8, 7, 9),
      instantUtc: DateTime.utc(2026, 8, 7, 9),
    );

    final result = projector.projectForOccurrences(
      task: task,
      rules: <TaskReminderRule>[rule],
      occurrences: <TaskCalendarOccurrence>[occurrence],
      nowUtc: now,
    );

    expect(result, hasLength(1));
    expect(
      result.single.scheduleId,
      'task-task-occurrence-202608070900-reminder-reminder',
    );
    expect(result.single.payload['occurrenceKey'], 'task@2026-08-07T09:00');
    expect(result.single.scheduledAtUtc, DateTime.utc(2026, 8, 7, 8));
  });

  test('skipped, canceled, and completed occurrences do not notify', () {
    final occurrences = <TaskCalendarOccurrence>[
      _occurrence(
        task: task,
        local: _local(2026, 8, 7, 9),
        instantUtc: DateTime.utc(2026, 8, 7, 9),
        status: TaskCalendarOccurrenceStatus.skipped,
      ),
      _occurrence(
        task: task,
        local: _local(2026, 8, 8, 9),
        instantUtc: DateTime.utc(2026, 8, 8, 9),
        status: TaskCalendarOccurrenceStatus.canceled,
      ),
      _occurrence(
        task: task,
        local: _local(2026, 8, 9, 9),
        instantUtc: DateTime.utc(2026, 8, 9, 9),
        status: TaskCalendarOccurrenceStatus.completed,
      ),
    ];

    final result = projector.projectForOccurrences(
      task: task,
      rules: <TaskReminderRule>[rule],
      occurrences: occurrences,
      nowUtc: now,
    );

    expect(result, isEmpty);
  });
}

TaskCalendarOccurrence _occurrence({
  required TaskItem task,
  required RecurrenceLocalDateTime local,
  required DateTime instantUtc,
  TaskCalendarOccurrenceStatus status = TaskCalendarOccurrenceStatus.scheduled,
}) {
  return TaskCalendarOccurrence(
    task: task,
    originalLocalDateTime: local,
    effectiveLocalDateTime: local,
    instantUtc: instantUtc,
    timeZoneId: 'Etc/UTC',
    calendar: RecurrenceCalendar.gregorian,
    sequence: 1,
    status: status,
    recurring: true,
  );
}

RecurrenceLocalDateTime _local(int year, int month, int day, int hour) {
  return RecurrenceLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
  );
}
