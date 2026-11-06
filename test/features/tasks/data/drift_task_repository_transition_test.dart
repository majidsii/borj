import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  AppDatabase? database;
  late DriftTaskRepository repository;

  setUp(() {
    final openedDatabase = openTestDatabase();
    database = openedDatabase;
    repository = DriftTaskRepository(openedDatabase);
  });

  tearDown(() async {
    final openedDatabase = database;
    database = null;
    if (openedDatabase != null) {
      await openedDatabase.close();
    }
  });

  test(
    'transition compacts source and inserts at exact target position',
    () async {
      final now = DateTime.utc(2026, 8, 2, 10);

      await repository.create(_task(id: 'planned-a', now: now));
      await repository.create(
        _task(id: 'planned-b', now: now.add(const Duration(minutes: 1))),
      );
      await repository.create(
        _task(
          id: 'progress-a',
          status: TaskStatus.inProgress,
          now: now.add(const Duration(minutes: 2)),
        ),
      );
      await repository.create(
        _task(
          id: 'progress-b',
          status: TaskStatus.inProgress,
          now: now.add(const Duration(minutes: 3)),
        ),
      );

      await repository.transition(
        id: 'planned-a',
        status: TaskStatus.inProgress,
        targetPosition: 1,
        changedAtUtc: now.add(const Duration(hours: 1)),
      );

      expect(await _ids(repository, TaskStatus.planned), <String>['planned-b']);
      expect(await _ids(repository, TaskStatus.inProgress), <String>[
        'progress-a',
        'planned-a',
        'progress-b',
      ]);
      expect(await _positions(repository, TaskStatus.planned), <int>[0]);
      expect(await _positions(repository, TaskStatus.inProgress), <int>[
        0,
        1,
        2,
      ]);
    },
  );

  test(
    'transition maintains terminal timestamps across status changes',
    () async {
      final now = DateTime.utc(2026, 8, 2, 11);
      await repository.create(
        _task(id: 'task', status: TaskStatus.inProgress, now: now),
      );

      final localCompletedAt = DateTime(2026, 8, 2, 18, 30);
      await repository.transition(
        id: 'task',
        status: TaskStatus.completed,
        targetPosition: 0,
        changedAtUtc: localCompletedAt,
      );

      final completed = (await repository.getById('task'))!;
      expect(completed.status, TaskStatus.completed);
      expect(completed.completedAtUtc, localCompletedAt.toUtc());
      expect(completed.canceledAtUtc, isNull);
      expect(completed.updatedAtUtc, localCompletedAt.toUtc());

      final reopenedAt = DateTime.utc(2026, 8, 2, 16);
      await repository.transition(
        id: 'task',
        status: TaskStatus.planned,
        targetPosition: 0,
        changedAtUtc: reopenedAt,
      );

      final reopened = (await repository.getById('task'))!;
      expect(reopened.status, TaskStatus.planned);
      expect(reopened.completedAtUtc, isNull);
      expect(reopened.canceledAtUtc, isNull);

      final canceledAt = DateTime.utc(2026, 8, 2, 17);
      await repository.transition(
        id: 'task',
        status: TaskStatus.canceled,
        targetPosition: 0,
        changedAtUtc: canceledAt,
      );

      final canceled = (await repository.getById('task'))!;
      expect(canceled.status, TaskStatus.canceled);
      expect(canceled.completedAtUtc, isNull);
      expect(canceled.canceledAtUtc, canceledAt);

      final restartedAt = DateTime.utc(2026, 8, 2, 18);
      await repository.transition(
        id: 'task',
        status: TaskStatus.inProgress,
        targetPosition: 0,
        changedAtUtc: restartedAt,
      );

      final restarted = (await repository.getById('task'))!;
      expect(restarted.status, TaskStatus.inProgress);
      expect(restarted.completedAtUtc, isNull);
      expect(restarted.canceledAtUtc, isNull);
    },
  );

  test('transition clamps negative and oversized target positions', () async {
    final now = DateTime.utc(2026, 8, 2, 12);
    await repository.create(
      _task(id: 'done-a', status: TaskStatus.completed, now: now),
    );
    await repository.create(
      _task(
        id: 'done-b',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.create(
      _task(id: 'first', now: now.add(const Duration(minutes: 2))),
    );
    await repository.create(
      _task(id: 'last', now: now.add(const Duration(minutes: 3))),
    );

    await repository.transition(
      id: 'first',
      status: TaskStatus.completed,
      targetPosition: -10,
      changedAtUtc: now.add(const Duration(hours: 1)),
    );
    await repository.transition(
      id: 'last',
      status: TaskStatus.completed,
      targetPosition: 999,
      changedAtUtc: now.add(const Duration(hours: 2)),
    );

    expect(await _ids(repository, TaskStatus.completed), <String>[
      'first',
      'done-a',
      'done-b',
      'last',
    ]);
    expect(await _positions(repository, TaskStatus.completed), <int>[
      0,
      1,
      2,
      3,
    ]);
  });

  test('missing transition id fails without writes', () async {
    final now = DateTime.utc(2026, 8, 2, 13);
    await repository.create(_task(id: 'planned', now: now));
    await repository.create(
      _task(
        id: 'completed',
        status: TaskStatus.completed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    final before = await _snapshot(repository);

    await expectLater(
      repository.transition(
        id: 'missing',
        status: TaskStatus.canceled,
        targetPosition: 0,
        changedAtUtc: now.add(const Duration(hours: 1)),
      ),
      throwsA(isA<ValidationFailure>()),
    );

    expect(await _snapshot(repository), before);
  });

  test('transition survives file restart with contiguous positions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'borj-task-transition-',
    );
    final file = File('${directory.path}/tasks.sqlite');
    final now = DateTime.utc(2026, 8, 2, 14);

    try {
      final setupDatabase = database;
      database = null;
      await setupDatabase?.close();

      final firstDatabase = AppDatabase(NativeDatabase(file));
      final firstRepository = DriftTaskRepository(firstDatabase);
      await firstRepository.create(_task(id: 'planned-a', now: now));
      await firstRepository.create(
        _task(id: 'planned-b', now: now.add(const Duration(minutes: 1))),
      );
      await firstRepository.create(
        _task(
          id: 'progress',
          status: TaskStatus.inProgress,
          now: now.add(const Duration(minutes: 2)),
        ),
      );
      await firstRepository.transition(
        id: 'planned-b',
        status: TaskStatus.inProgress,
        targetPosition: 0,
        changedAtUtc: now.add(const Duration(hours: 1)),
      );
      await firstDatabase.close();

      final reopenedDatabase = AppDatabase(NativeDatabase(file));
      final reopenedRepository = DriftTaskRepository(reopenedDatabase);
      try {
        expect(await _ids(reopenedRepository, TaskStatus.planned), <String>[
          'planned-a',
        ]);
        expect(await _ids(reopenedRepository, TaskStatus.inProgress), <String>[
          'planned-b',
          'progress',
        ]);
        expect(
          await _positions(reopenedRepository, TaskStatus.inProgress),
          <int>[0, 1],
        );
      } finally {
        await reopenedDatabase.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'reorderWithinStatus writes contiguous positions only in one status',
    () async {
      final now = DateTime.utc(2026, 8, 2, 15);
      for (var index = 0; index < 3; index++) {
        await repository.create(
          _task(
            id: 'planned-$index',
            now: now.add(Duration(minutes: index)),
          ),
        );
      }
      await repository.create(
        _task(
          id: 'completed',
          status: TaskStatus.completed,
          now: now.add(const Duration(minutes: 4)),
        ),
      );
      final completedBefore = await repository.getById('completed');

      await repository.reorderWithinStatus(
        status: TaskStatus.planned,
        orderedIds: const <String>['planned-2', 'planned-0', 'planned-1'],
      );

      expect(await _ids(repository, TaskStatus.planned), <String>[
        'planned-2',
        'planned-0',
        'planned-1',
      ]);
      expect(await _positions(repository, TaskStatus.planned), <int>[0, 1, 2]);
      expect(await repository.getById('completed'), completedBefore);
    },
  );

  test(
    'reorderWithinStatus rejects invalid inventories without writes',
    () async {
      final now = DateTime.utc(2026, 8, 2, 16);
      await repository.create(_task(id: 'planned-a', now: now));
      await repository.create(
        _task(id: 'planned-b', now: now.add(const Duration(minutes: 1))),
      );
      await repository.create(
        _task(
          id: 'completed',
          status: TaskStatus.completed,
          now: now.add(const Duration(minutes: 2)),
        ),
      );

      final invalidOrders = <List<String>>[
        <String>['planned-a', 'planned-a'],
        <String>['planned-a'],
        <String>['planned-a', 'missing'],
        <String>['planned-a', 'completed'],
      ];

      for (final orderedIds in invalidOrders) {
        final before = await _snapshot(repository);
        await expectLater(
          repository.reorderWithinStatus(
            status: TaskStatus.planned,
            orderedIds: orderedIds,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(await _snapshot(repository), before);
      }
    },
  );
}

Future<List<String>> _ids(
  DriftTaskRepository repository,
  TaskStatus status,
) async {
  return (await repository.watchByStatus(status).first)
      .map((task) => task.id)
      .toList(growable: false);
}

Future<List<int>> _positions(
  DriftTaskRepository repository,
  TaskStatus status,
) async {
  return (await repository.watchByStatus(status).first)
      .map((task) => task.positionInStatus)
      .toList(growable: false);
}

Future<List<List<Object?>>> _snapshot(DriftTaskRepository repository) async {
  return (await repository.watchAll().first)
      .map(
        (task) => <Object?>[
          task.id,
          task.displayNumber,
          task.status,
          task.positionInStatus,
          task.updatedAtUtc,
          task.completedAtUtc,
          task.canceledAtUtc,
        ],
      )
      .toList(growable: false);
}

TaskItem _task({
  required String id,
  TaskStatus status = TaskStatus.planned,
  required DateTime now,
}) {
  return TaskItem(
    id: id,
    displayNumber: 999,
    title: id,
    priority: 1,
    status: status,
    positionInStatus: 999,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}
