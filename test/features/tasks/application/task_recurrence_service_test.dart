import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/features/tasks/application/task_recurrence_service.dart';
import 'package:borj/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRecurrenceRepository repository;
  late List<String> changed;
  late TaskRecurrenceService service;
  final now = DateTime.utc(2026, 8, 6, 8);

  setUp(() async {
    database = openTestDatabase();
    repository = DriftTaskRecurrenceRepository(database);
    changed = <String>[];
    service = TaskRecurrenceService(
      repository: repository,
      nowUtc: () => now,
      nextId: () => 'generated-${changed.length}',
      onChanged: (taskId) async => changed.add(taskId),
    );
    await DriftTaskRepository(database).create(
      TaskItem(
        id: 'task',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        dueAtUtc: DateTime.utc(2026, 8, 7, 9),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
  });

  tearDown(() => database.close());

  test('replace rule preserves id on later edits', () async {
    await service.replaceRule(
      taskId: 'task',
      rule: RecurrenceRule.daily(anchorLocalDateTime: _local(2026, 8, 7, 9)),
    );
    final first = (await repository.getByTask('task')).rule!;

    await service.replaceRule(
      taskId: 'task',
      rule: RecurrenceRule.daily(
        anchorLocalDateTime: _local(2026, 8, 7, 9),
        interval: 2,
      ),
    );
    final second = (await repository.getByTask('task')).rule!;

    expect(second.id, first.id);
    expect(second.rule.interval, 2);
    expect(changed, <String>['task', 'task']);
  });

  test('completion and exception are independent', () async {
    final original = _local(2026, 8, 7, 9);
    await service.replaceRule(
      taskId: 'task',
      rule: RecurrenceRule.daily(anchorLocalDateTime: original),
    );
    await service.skip(taskId: 'task', originalLocalDateTime: original);
    await service.setCompleted(
      taskId: 'task',
      originalLocalDateTime: original,
      completed: true,
    );

    final bundle = await repository.getByTask('task');
    expect(bundle.exceptions, hasLength(1));
    expect(bundle.completions, hasLength(1));

    await service.restore(taskId: 'task', originalLocalDateTime: original);
    final restored = await repository.getByTask('task');
    expect(restored.exceptions, isEmpty);
    expect(restored.completions, hasLength(1));
  });

  test('disabling recurrence clears exception and completion state', () async {
    final original = _local(2026, 8, 7, 9);
    await service.replaceRule(
      taskId: 'task',
      rule: RecurrenceRule.daily(anchorLocalDateTime: original),
    );
    await service.setCompleted(
      taskId: 'task',
      originalLocalDateTime: original,
      completed: true,
    );

    await service.replaceRule(taskId: 'task', rule: null);

    final bundle = await repository.getByTask('task');
    expect(bundle.rule, isNull);
    expect(bundle.completions, isEmpty);
  });
}

RecurrenceLocalDateTime _local(int year, int month, int day, int hour) {
  return RecurrenceLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
  );
}
