import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/application/task_timer_service.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/data/drift_task_time_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskTimeRepository repository;
  late _MutableClock clock;
  late TaskTimerService service;
  var ids = 0;
  final start = DateTime.utc(2026, 8, 6, 8);

  setUp(() async {
    database = openTestDatabase();
    repository = DriftTaskTimeRepository(database);
    clock = _MutableClock(start);
    ids = 0;
    service = TaskTimerService(
      repository: repository,
      clock: clock,
      nextId: () => 'time-${++ids}',
    );
    await DriftTaskRepository(database).create(
      TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار تایمر',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
    );
  });

  tearDown(() => database.close());

  test('start persists one running timer and rejects a second start', () async {
    final running = await service.start('task-1');

    expect(running.isRunning, isTrue);
    await expectLater(
      service.start('task-1'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('pause resume and stop accumulate only running intervals', () async {
    await service.start('task-1');
    clock.value = start.add(const Duration(minutes: 2));
    final paused = await service.pause();
    clock.value = start.add(const Duration(minutes: 12));
    final resumed = await service.resume();
    clock.value = start.add(const Duration(minutes: 15));
    final stopped = await service.stop();

    expect(paused.accumulatedSeconds, 120);
    expect(resumed.isRunning, isTrue);
    expect(stopped.accumulatedSeconds, 300);
    expect(await repository.getActive(), isNull);
  });

  test(
    'new service instance recovers running timer from persistence',
    () async {
      await service.start('task-1');
      clock.value = start.add(const Duration(minutes: 10));
      final restarted = TaskTimerService(
        repository: DriftTaskTimeRepository(database),
        clock: clock,
        nextId: () => 'unused',
      );

      final paused = await restarted.pause();

      expect(paused.accumulatedSeconds, 600);
    },
  );

  test(
    'manual duration creates a stopped entry ending at clock time',
    () async {
      clock.value = start.add(const Duration(hours: 1));
      final entry = await service.addManualDuration(
        taskId: 'task-1',
        durationMinutes: 45,
        note: 'مطالعه',
      );

      expect(entry.startedAtUtc, start.add(const Duration(minutes: 15)));
      expect(entry.endedAtUtc, start.add(const Duration(hours: 1)));
      expect(entry.note, 'مطالعه');
    },
  );

  test('manual entry rejects overlap with an existing entry', () async {
    await service.addManual(
      taskId: 'task-1',
      startedAtUtc: start,
      endedAtUtc: start.add(const Duration(minutes: 30)),
    );

    await expectLater(
      service.addManual(
        taskId: 'task-1',
        startedAtUtc: start.add(const Duration(minutes: 20)),
        endedAtUtc: start.add(const Duration(minutes: 40)),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'manual update validates overlap and preserves entry identity',
    () async {
      final first = await service.addManual(
        taskId: 'task-1',
        startedAtUtc: start,
        endedAtUtc: start.add(const Duration(minutes: 10)),
      );
      await service.addManual(
        taskId: 'task-1',
        startedAtUtc: start.add(const Duration(minutes: 20)),
        endedAtUtc: start.add(const Duration(minutes: 30)),
      );

      final updated = await service.updateManual(
        id: first.id,
        startedAtUtc: start.add(const Duration(minutes: 5)),
        endedAtUtc: start.add(const Duration(minutes: 15)),
        note: 'اصلاح',
      );

      expect(updated.id, first.id);
      expect(updated.note, 'اصلاح');
    },
  );

  test('manual update rejects overlap with another entry', () async {
    final first = await service.addManual(
      taskId: 'task-1',
      startedAtUtc: start,
      endedAtUtc: start.add(const Duration(minutes: 10)),
    );
    await service.addManual(
      taskId: 'task-1',
      startedAtUtc: start.add(const Duration(minutes: 20)),
      endedAtUtc: start.add(const Duration(minutes: 30)),
    );

    await expectLater(
      service.updateManual(
        id: first.id,
        startedAtUtc: start.add(const Duration(minutes: 25)),
        endedAtUtc: start.add(const Duration(minutes: 35)),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('active entry cannot be deleted before stop', () async {
    final running = await service.start('task-1');

    await expectLater(
      service.delete(running.id),
      throwsA(isA<ValidationFailure>()),
    );
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime nowLocal() => value.toLocal();

  @override
  DateTime nowUtc() => value.toUtc();
}
