import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRecurrenceRepository repository;

  setUp(() async {
    database = openTestDatabase();
    repository = DriftTaskRecurrenceRepository(database);
    await DriftTaskRepository(database).create(_task());
  });

  tearDown(() async {
    await database.close();
  });

  test('persists rule, exception, and independent completion', () async {
    final now = DateTime.utc(2026, 8, 6, 8);
    final original = _local(2026, 8, 7, 9);
    final rule = TaskRecurrenceRule(
      id: 'rule-1',
      taskId: 'task-1',
      rule: RecurrenceRule.daily(anchorLocalDateTime: original),
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    await repository.replaceRule(taskId: 'task-1', rule: rule);
    await repository.upsertException(
      TaskRecurrenceException(
        id: 'exception-1',
        taskId: 'task-1',
        exception: RecurrenceException.move(
          originalLocalDateTime: original,
          movedToLocalDateTime: _local(2026, 8, 7, 11),
        ),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.setCompletion(
      TaskOccurrenceCompletion(
        taskId: 'task-1',
        originalLocalDateTime: original,
        completedAtUtc: now,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    final bundle = await repository.getByTask('task-1');

    expect(bundle.rule, isNotNull);
    expect(bundle.rule!.rule.anchorLocalDateTime, original);
    expect(bundle.exceptions, hasLength(1));
    expect(
      bundle.exceptions.single.exception.action,
      RecurrenceExceptionAction.move,
    );
    expect(bundle.completions, hasLength(1));
    expect(bundle.completions.single.occurrenceKey, 'task-1@2026-08-07T09:00');
  });

  test('replacing with null clears all task recurrence state', () async {
    final now = DateTime.utc(2026, 8, 6, 8);
    final original = _local(2026, 8, 7, 9);
    await repository.replaceRule(
      taskId: 'task-1',
      rule: TaskRecurrenceRule(
        id: 'rule-1',
        taskId: 'task-1',
        rule: RecurrenceRule.daily(anchorLocalDateTime: original),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.setCompletion(
      TaskOccurrenceCompletion(
        taskId: 'task-1',
        originalLocalDateTime: original,
        completedAtUtc: now,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    await repository.replaceRule(taskId: 'task-1', rule: null);
    final bundle = await repository.getByTask('task-1');

    expect(bundle.rule, isNull);
    expect(bundle.exceptions, isEmpty);
    expect(bundle.completions, isEmpty);
  });

  test('watch streams emit sorted persisted state', () async {
    final now = DateTime.utc(2026, 8, 6, 8);
    final next = repository.watchRules().firstWhere(
      (items) => items.length == 1,
    );

    await repository.replaceRule(
      taskId: 'task-1',
      rule: TaskRecurrenceRule(
        id: 'rule-1',
        taskId: 'task-1',
        rule: RecurrenceRule.daily(anchorLocalDateTime: _local(2026, 8, 7, 9)),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    expect((await next).single.taskId, 'task-1');
  });
}

TaskItem _task() {
  final now = DateTime.utc(2026, 8, 6, 8);
  return TaskItem(
    id: 'task-1',
    displayNumber: 1,
    title: 'کار تکرارشونده',
    priority: 1,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: DateTime.utc(2026, 8, 7, 9),
    createdAtUtc: now,
    updatedAtUtc: now,
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
