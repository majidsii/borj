import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/application/task_occurrence_projector.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  const projector = TaskOccurrenceProjector();
  final now = DateTime.utc(2026, 8, 6, 8);

  test('projects recurring move and completion by original identity', () {
    final task = _task('series');
    final first = _local(2026, 8, 7, 9);
    final second = _local(2026, 8, 8, 9);
    final rule = TaskRecurrenceRule(
      id: 'rule',
      taskId: task.id,
      rule: RecurrenceRule.daily(
        anchorLocalDateTime: first,
        timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
        end: RecurrenceEnd.afterCount(3),
      ),
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    final result = projector.project(
      tasks: <TaskItem>[task],
      rules: <TaskRecurrenceRule>[rule],
      exceptions: <TaskRecurrenceException>[
        TaskRecurrenceException(
          id: 'move',
          taskId: task.id,
          exception: RecurrenceException.move(
            originalLocalDateTime: first,
            movedToLocalDateTime: _local(2026, 8, 7, 11),
          ),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      completions: <TaskOccurrenceCompletion>[
        TaskOccurrenceCompletion(
          taskId: task.id,
          originalLocalDateTime: second,
          completedAtUtc: now,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      rangeStartUtc: DateTime.utc(2026, 8, 7),
      rangeEndUtc: DateTime.utc(2026, 8, 11),
      floatingTimeZoneId: 'Europe/Amsterdam',
    );

    expect(result, hasLength(3));
    expect(result.first.status, TaskCalendarOccurrenceStatus.moved);
    expect(result.first.originalLocalDateTime, first);
    expect(result.first.instantUtc, DateTime.utc(2026, 8, 7, 11));
    expect(result[1].status, TaskCalendarOccurrenceStatus.completed);
    expect(result[1].occurrenceKey, 'series@2026-08-08T09:00');
  });

  test('projects skipped and canceled occurrences without completion', () {
    final task = _task('series');
    final first = _local(2026, 8, 7, 9);
    final rule = TaskRecurrenceRule(
      id: 'rule',
      taskId: task.id,
      rule: RecurrenceRule.daily(
        anchorLocalDateTime: first,
        timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
        end: RecurrenceEnd.afterCount(2),
      ),
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    final result = projector.project(
      tasks: <TaskItem>[task],
      rules: <TaskRecurrenceRule>[rule],
      exceptions: <TaskRecurrenceException>[
        TaskRecurrenceException(
          id: 'skip',
          taskId: task.id,
          exception: RecurrenceException.skip(originalLocalDateTime: first),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
        TaskRecurrenceException(
          id: 'cancel',
          taskId: task.id,
          exception: RecurrenceException.cancel(
            originalLocalDateTime: _local(2026, 8, 8, 9),
          ),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      completions: const <TaskOccurrenceCompletion>[],
      rangeStartUtc: DateTime.utc(2026, 8, 7),
      rangeEndUtc: DateTime.utc(2026, 8, 10),
      floatingTimeZoneId: 'UTC',
    );

    expect(
      result.map((item) => item.status).toList(),
      <TaskCalendarOccurrenceStatus>[
        TaskCalendarOccurrenceStatus.skipped,
        TaskCalendarOccurrenceStatus.canceled,
      ],
    );
  });

  test('one-off task uses due time and task terminal state', () {
    final task = _task(
      'one-off',
      status: TaskStatus.completed,
      completedAtUtc: now,
    );

    final result = projector.project(
      tasks: <TaskItem>[task],
      rules: const <TaskRecurrenceRule>[],
      exceptions: const <TaskRecurrenceException>[],
      completions: const <TaskOccurrenceCompletion>[],
      rangeStartUtc: DateTime.utc(2026, 8, 7),
      rangeEndUtc: DateTime.utc(2026, 8, 8),
      floatingTimeZoneId: 'Etc/UTC',
    );

    expect(result.single.recurring, isFalse);
    expect(result.single.status, TaskCalendarOccurrenceStatus.completed);
  });
}

TaskItem _task(
  String id, {
  TaskStatus status = TaskStatus.planned,
  DateTime? completedAtUtc,
}) {
  final now = DateTime.utc(2026, 8, 6, 8);
  return TaskItem(
    id: id,
    displayNumber: 1,
    title: 'کار $id',
    priority: 1,
    status: status,
    positionInStatus: 0,
    dueAtUtc: DateTime.utc(2026, 8, 7, 9),
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: completedAtUtc,
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
