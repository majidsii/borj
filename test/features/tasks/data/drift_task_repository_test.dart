import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;

  var sharedDatabaseOpen = false;
  setUp(() {
    database = openTestDatabase();
    repository = DriftTaskRepository(database);
    sharedDatabaseOpen = true;
  });
  tearDown(() async {
    if (sharedDatabaseOpen) {
      await database.close();
    }
  });

  test('watchAll orders workflow status then status-local position', () async {
    final now = DateTime.utc(2026, 7, 26, 10);

    await repository.create(
      _task(
        id: 'completed',
        status: TaskStatus.completed,
        requestedPosition: 90,
        now: now,
      ),
    );
    await repository.create(
      _task(
        id: 'planned-a',
        status: TaskStatus.planned,
        requestedPosition: 80,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.create(
      _task(
        id: 'canceled',
        status: TaskStatus.canceled,
        requestedPosition: 70,
        now: now.add(const Duration(minutes: 2)),
      ),
    );
    await repository.create(
      _task(
        id: 'planned-b',
        status: TaskStatus.planned,
        requestedPosition: 60,
        now: now.add(const Duration(minutes: 3)),
      ),
    );
    await repository.create(
      _task(
        id: 'in-progress',
        status: TaskStatus.inProgress,
        requestedPosition: 50,
        now: now.add(const Duration(minutes: 4)),
      ),
    );

    final items = await repository.watchAll().first;

    expect(items.map((item) => item.id).toList(), <String>[
      'planned-a',
      'planned-b',
      'in-progress',
      'completed',
      'canceled',
    ]);
    expect(items.map((item) => item.positionInStatus).toList(), <int>[
      0,
      1,
      0,
      0,
      0,
    ]);
  });

  test('watchByStatus filters and orders one status', () async {
    final now = DateTime.utc(2026, 7, 26, 11);

    await repository.create(
      _task(id: 'planned-a', status: TaskStatus.planned, now: now),
    );
    await repository.create(
      _task(
        id: 'completed',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.create(
      _task(
        id: 'planned-b',
        status: TaskStatus.planned,
        now: now.add(const Duration(minutes: 2)),
      ),
    );

    final planned = await repository.watchByStatus(TaskStatus.planned).first;

    expect(planned.map((item) => item.id).toList(), <String>[
      'planned-a',
      'planned-b',
    ]);
    expect(planned.map((item) => item.status).toSet(), <TaskStatus>{
      TaskStatus.planned,
    });
    expect(planned.map((item) => item.positionInStatus).toList(), <int>[0, 1]);
  });

  test('getById returns an exact task and null for a missing id', () async {
    final now = DateTime.utc(2026, 7, 26, 12);
    await repository.create(
      _task(id: 'task-1', status: TaskStatus.inProgress, now: now),
    );

    final found = await repository.getById('task-1');

    expect(found, isNotNull);
    expect(found!.id, 'task-1');
    expect(found.status, TaskStatus.inProgress);
    expect(await repository.getById('missing'), isNull);
  });

  test('create allocates display numbers and status positions', () async {
    final now = DateTime.utc(2026, 7, 26, 13);

    await repository.create(
      _task(id: 'task-a', displayNumber: 700, requestedPosition: 70, now: now),
    );
    await repository.create(
      _task(
        id: 'task-b',
        displayNumber: 700,
        requestedPosition: 70,
        now: now.add(const Duration(minutes: 1)),
      ),
    );

    final items = await repository.watchAll().first;

    expect(items.map((item) => item.displayNumber).toList(), <int>[1, 2]);
    expect(items.map((item) => item.positionInStatus).toList(), <int>[0, 1]);
  });

  test('delete then create advances the display number', () async {
    final now = DateTime.utc(2026, 7, 26, 14);

    await repository.create(
      _task(id: 'task-1', status: TaskStatus.planned, now: now),
    );
    await repository.create(
      _task(
        id: 'task-2',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.delete('task-1');
    await repository.create(
      _task(
        id: 'task-3',
        status: TaskStatus.planned,
        now: now.add(const Duration(minutes: 2)),
      ),
    );

    final created = await repository.getById('task-3');

    expect(created, isNotNull);
    expect(created!.displayNumber, 3);
    expect(created.positionInStatus, 0);
  });

  test(
    'update persists editable fields and preserves display number',
    () async {
      final now = DateTime.utc(2026, 7, 26, 15);
      await repository.create(
        _task(
          id: 'task-1',
          displayNumber: 900,
          requestedPosition: 90,
          title: 'عنوان قدیمی',
          priority: 0,
          now: now,
        ),
      );

      final persisted = (await repository.getById('task-1'))!;
      final updated = persisted.copyWith(
        title: 'عنوان جدید',
        priority: 2,
        positionInStatus: 3,
        updatedAtUtc: now.add(const Duration(hours: 1)),
      );

      await repository.update(updated);

      final stored = await repository.getById('task-1');
      expect(stored, updated);
      expect(stored!.displayNumber, 1);
    },
  );

  test(
    'transition stores UTC completion and clears it when reopened',
    () async {
      final now = DateTime.utc(2026, 7, 26, 16);
      await repository.create(_task(id: 'task-1', now: now));

      final changedAt = DateTime(2026, 7, 26, 20, 30);
      await repository.transition(
        id: 'task-1',
        status: TaskStatus.completed,
        targetPosition: 0,
        changedAtUtc: changedAt,
      );

      final completed = await repository.getById('task-1');
      expect(completed!.isDone, isTrue);
      expect(completed.completedAtUtc, changedAt.toUtc());
      expect(completed.updatedAtUtc, changedAt.toUtc());

      await repository.transition(
        id: 'task-1',
        status: TaskStatus.planned,
        targetPosition: 0,
        changedAtUtc: changedAt.add(const Duration(minutes: 5)),
      );

      final reopened = await repository.getById('task-1');
      expect(reopened!.isDone, isFalse);
      expect(reopened.completedAtUtc, isNull);
    },
  );

  test('deleteCompleted keeps only non-completed tasks', () async {
    final now = DateTime.utc(2026, 7, 26, 17);
    await repository.create(
      _task(id: 'active', status: TaskStatus.planned, now: now),
    );
    await repository.create(
      _task(
        id: 'done',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.create(
      _task(
        id: 'canceled',
        status: TaskStatus.canceled,
        now: now.add(const Duration(minutes: 2)),
      ),
    );

    await repository.deleteCompleted();

    final items = await repository.watchAll().first;
    expect(items.map((item) => item.id).toList(), <String>[
      'active',
      'canceled',
    ]);
  });

  test('delete compacts only the removed task status', () async {
    final now = DateTime.utc(2026, 7, 26, 17, 30);
    for (var index = 0; index < 3; index++) {
      await repository.create(
        _task(
          id: 'planned-$index',
          status: TaskStatus.planned,
          now: now.add(Duration(minutes: index)),
        ),
      );
    }
    await repository.create(
      _task(
        id: 'completed',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 3)),
      ),
    );

    await repository.delete('planned-1');

    final planned = await repository.watchByStatus(TaskStatus.planned).first;
    final completed = await repository
        .watchByStatus(TaskStatus.completed)
        .first;
    expect(planned.map((item) => item.id).toList(), <String>[
      'planned-0',
      'planned-2',
    ]);
    expect(planned.map((item) => item.positionInStatus).toList(), <int>[0, 1]);
    expect(completed.single.id, 'completed');
    expect(completed.single.positionInStatus, 0);
  });

  test('delete removes only the requested task', () async {
    final now = DateTime.utc(2026, 7, 26, 18);
    await repository.create(_task(id: 'keep', now: now));
    await repository.create(
      _task(id: 'remove', now: now.add(const Duration(minutes: 1))),
    );

    await repository.delete('remove');

    expect(await repository.getById('remove'), isNull);
    expect((await repository.getById('keep'))!.id, 'keep');
  });

  test(
    'status reorder changes positions without changing display numbers',
    () async {
      final now = DateTime.utc(2026, 7, 26, 19);
      for (var index = 0; index < 3; index++) {
        await repository.create(
          _task(
            id: 'task-$index',
            now: now.add(Duration(minutes: index)),
          ),
        );
      }

      final before = <String, int>{
        for (final item in await repository.watchAll().first)
          item.id: item.displayNumber,
      };

      await repository.reorderWithinStatus(
        status: TaskStatus.planned,
        orderedIds: const <String>['task-2', 'task-0', 'task-1'],
      );

      final items = await repository.watchAll().first;
      expect(items.map((item) => item.id).toList(), <String>[
        'task-2',
        'task-0',
        'task-1',
      ]);
      expect(items.map((item) => item.positionInStatus).toList(), <int>[
        0,
        1,
        2,
      ]);
      expect(<String, int>{
        for (final item in items) item.id: item.displayNumber,
      }, before);
    },
  );

  test('file restart preserves and advances display numbers', () async {
    await database.close();
    sharedDatabaseOpen = false;

    final directory = await Directory.systemTemp.createTemp(
      'borj-task-repository-',
    );
    final file = File('${directory.path}/tasks.sqlite');

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = DriftTaskRepository(firstDatabase);
    final now = DateTime.utc(2026, 7, 26, 20);

    await firstRepository.create(
      _task(
        id: 'persistent-task',
        displayNumber: 800,
        title: 'بعد از بازشدن دوباره',
        priority: 3,
        now: now,
      ),
    );
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    final reopenedRepository = DriftTaskRepository(reopenedDatabase);

    try {
      final persisted = await reopenedRepository.getById('persistent-task');
      expect(persisted, isNotNull);
      expect(persisted!.displayNumber, 1);
      expect(persisted.title, 'بعد از بازشدن دوباره');

      await reopenedRepository.create(
        _task(
          id: 'after-restart',
          displayNumber: 800,
          now: now.add(const Duration(minutes: 1)),
        ),
      );

      expect(
        (await reopenedRepository.getById('after-restart'))!.displayNumber,
        2,
      );
    } finally {
      await reopenedDatabase.close();
      await directory.delete(recursive: true);
    }
  });
}

TaskItem _task({
  required String id,
  int displayNumber = 500,
  String title = 'کار',
  int priority = 1,
  TaskStatus status = TaskStatus.planned,
  int requestedPosition = 50,
  required DateTime now,
}) {
  return TaskItem(
    id: id,
    displayNumber: displayNumber,
    title: title,
    priority: priority,
    status: status,
    positionInStatus: requestedPosition,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}
