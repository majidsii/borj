import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/data/drift_task_time_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late DriftTaskTimeRepository repository;
  final now = DateTime.utc(2026, 8, 6, 8);

  setUp(() async {
    database = openTestDatabase();
    taskRepository = DriftTaskRepository(database);
    repository = DriftTaskTimeRepository(database);
    await _createTask(taskRepository, 'task-1', 1, now);
    await _createTask(taskRepository, 'task-2', 2, now);
  });

  tearDown(() => database.close());

  test('persists a running timer and exposes it as the active entry', () async {
    final entry = TaskTimeEntry.running(
      id: 'timer-1',
      taskId: 'task-1',
      startedAtUtc: now,
    );

    await repository.insert(entry);

    expect(await repository.getActive(), entry);
    expect((await repository.getByTask('task-1')).single, entry);
  });

  test('database rejects a second globally active timer', () async {
    await repository.insert(
      TaskTimeEntry.running(id: 'timer-1', taskId: 'task-1', startedAtUtc: now),
    );

    await expectLater(
      repository.insert(
        TaskTimeEntry.running(
          id: 'timer-2',
          taskId: 'task-2',
          startedAtUtc: now.add(const Duration(minutes: 1)),
        ),
      ),
      throwsA(isA<PersistenceFailure>()),
    );
  });

  test('pause update survives repository remapping', () async {
    final running = TaskTimeEntry.running(
      id: 'timer-1',
      taskId: 'task-1',
      startedAtUtc: now,
    );
    await repository.insert(running);
    await repository.update(running.pause(now.add(const Duration(minutes: 3))));

    final restored = await repository.getActive();
    expect(restored!.isPaused, isTrue);
    expect(restored.accumulatedSeconds, 180);
  });

  test('stopped and manual entries are ordered newest first by task', () async {
    final first = TaskTimeEntry.manual(
      id: 'manual-1',
      taskId: 'task-1',
      startedAtUtc: now,
      endedAtUtc: now.add(const Duration(minutes: 10)),
      savedAtUtc: now.add(const Duration(hours: 1)),
    );
    final second = TaskTimeEntry.manual(
      id: 'manual-2',
      taskId: 'task-1',
      startedAtUtc: now.add(const Duration(hours: 2)),
      endedAtUtc: now.add(const Duration(hours: 2, minutes: 5)),
      savedAtUtc: now.add(const Duration(hours: 3)),
    );
    await repository.insert(first);
    await repository.insert(second);

    expect(
      (await repository.getByTask('task-1')).map((item) => item.id),
      <String>['manual-2', 'manual-1'],
    );
  });

  test('watchActive emits lifecycle changes', () async {
    final values = <TaskTimeEntry?>[];
    final subscription = repository.watchActive().listen(values.add);
    final running = TaskTimeEntry.running(
      id: 'timer-1',
      taskId: 'task-1',
      startedAtUtc: now,
    );
    await repository.insert(running);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repository.update(running.pause(now.add(const Duration(minutes: 1))));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repository.update(
      running
          .pause(now.add(const Duration(minutes: 1)))
          .stop(now.add(const Duration(minutes: 2))),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await subscription.cancel();

    expect(values.any((item) => item?.isRunning ?? false), isTrue);
    expect(values.any((item) => item?.isPaused ?? false), isTrue);
    expect(values.last, isNull);
  });

  test('task deletion cascades its time entries', () async {
    await repository.insert(
      TaskTimeEntry.manual(
        id: 'manual-1',
        taskId: 'task-1',
        startedAtUtc: now,
        endedAtUtc: now.add(const Duration(minutes: 5)),
        savedAtUtc: now.add(const Duration(hours: 1)),
      ),
    );

    await taskRepository.delete('task-1');

    expect(await repository.getByTask('task-1'), isEmpty);
  });

  test('delete removes a stopped entry', () async {
    await repository.insert(
      TaskTimeEntry.manual(
        id: 'manual-1',
        taskId: 'task-1',
        startedAtUtc: now,
        endedAtUtc: now.add(const Duration(minutes: 5)),
        savedAtUtc: now.add(const Duration(hours: 1)),
      ),
    );

    await repository.delete('manual-1');

    expect(await repository.getById('manual-1'), isNull);
  });
}

Future<void> _createTask(
  DriftTaskRepository repository,
  String id,
  int displayNumber,
  DateTime now,
) {
  return repository.create(
    TaskItem(
      id: id,
      displayNumber: displayNumber,
      title: id,
      priority: 0,
      status: TaskStatus.planned,
      positionInStatus: 0,
      createdAtUtc: now,
      updatedAtUtc: now,
    ),
  );
}
