import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create update and clear round-trip every task planning field',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = DriftTaskRepository(database);

      try {
        final createdAt = DateTime.utc(2026, 8, 4, 8);
        final original = TaskItem(
          id: 'planning-round-trip',
          displayNumber: 99,
          title: 'برنامه‌ریزی انتشار',
          description: 'شرح اولیه',
          priority: 2,
          status: TaskStatus.planned,
          positionInStatus: 99,
          startAtUtc: DateTime.utc(2026, 8, 5, 7, 30),
          dueAtUtc: DateTime.utc(2026, 8, 5, 10),
          estimatedDurationMinutes: 150,
          createdAtUtc: createdAt,
          updatedAtUtc: createdAt,
        );

        await repository.create(original);

        final created = await repository.getById(original.id);
        expect(created, isNotNull);
        expect(created!.displayNumber, 1);
        expect(created.positionInStatus, 0);
        expect(created.description, 'شرح اولیه');
        expect(created.startAtUtc, DateTime.utc(2026, 8, 5, 7, 30));
        expect(created.dueAtUtc, DateTime.utc(2026, 8, 5, 10));
        expect(created.estimatedDurationMinutes, 150);

        final updatedAt = DateTime.utc(2026, 8, 4, 9);
        final updated = created.copyWith(
          description: 'شرح ویرایش‌شده',
          startAtUtc: DateTime.utc(2026, 8, 6, 8),
          dueAtUtc: DateTime.utc(2026, 8, 6, 11, 15),
          estimatedDurationMinutes: 195,
          updatedAtUtc: updatedAt,
        );
        await repository.update(updated);

        final loaded = await repository.getById(original.id);
        expect(loaded, isNotNull);
        expect(loaded!.id, original.id);
        expect(loaded.displayNumber, 1);
        expect(loaded.createdAtUtc, createdAt);
        expect(loaded.status, TaskStatus.planned);
        expect(loaded.positionInStatus, 0);
        expect(loaded.description, 'شرح ویرایش‌شده');
        expect(loaded.startAtUtc, DateTime.utc(2026, 8, 6, 8));
        expect(loaded.dueAtUtc, DateTime.utc(2026, 8, 6, 11, 15));
        expect(loaded.estimatedDurationMinutes, 195);
        expect(loaded.updatedAtUtc, updatedAt);

        final clearedAt = DateTime.utc(2026, 8, 4, 10);
        await repository.update(
          loaded.copyWith(
            clearDescription: true,
            clearStartAt: true,
            clearDueAt: true,
            clearEstimatedDuration: true,
            updatedAtUtc: clearedAt,
          ),
        );

        final cleared = await repository.getById(original.id);
        expect(cleared, isNotNull);
        expect(cleared!.description, isNull);
        expect(cleared.startAtUtc, isNull);
        expect(cleared.dueAtUtc, isNull);
        expect(cleared.estimatedDurationMinutes, isNull);
        expect(cleared.id, original.id);
        expect(cleared.displayNumber, 1);
        expect(cleared.createdAtUtc, createdAt);
        expect(cleared.status, TaskStatus.planned);
        expect(cleared.positionInStatus, 0);
        expect(cleared.updatedAtUtc, clearedAt);
      } finally {
        await database.close();
      }
    },
  );

  test('transition and reorder preserve every task planning field', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftTaskRepository(database);

    try {
      final createdAt = DateTime.utc(2026, 8, 4, 8);
      final first = _planningTask(
        id: 'planning-a',
        title: 'کار اول',
        description: 'جزئیات کار اول',
        startAtUtc: DateTime.utc(2026, 8, 5, 8),
        dueAtUtc: DateTime.utc(2026, 8, 5, 9),
        estimatedDurationMinutes: 60,
        createdAtUtc: createdAt,
      );
      final second = _planningTask(
        id: 'planning-b',
        title: 'کار دوم',
        description: 'جزئیات کار دوم',
        startAtUtc: DateTime.utc(2026, 8, 6, 10),
        dueAtUtc: DateTime.utc(2026, 8, 6, 12, 30),
        estimatedDurationMinutes: 150,
        createdAtUtc: createdAt.add(const Duration(minutes: 1)),
      );

      await repository.create(first);
      await repository.create(second);

      final before = await repository.getById(first.id);
      expect(before, isNotNull);

      await repository.transition(
        id: first.id,
        status: TaskStatus.inProgress,
        targetPosition: 0,
        changedAtUtc: DateTime.utc(2026, 8, 4, 9),
      );
      await repository.transition(
        id: first.id,
        status: TaskStatus.planned,
        targetPosition: 1,
        changedAtUtc: DateTime.utc(2026, 8, 4, 10),
      );
      await repository.reorderWithinStatus(
        status: TaskStatus.planned,
        orderedIds: <String>[first.id, second.id],
      );

      final after = await repository.getById(first.id);
      expect(after, isNotNull);
      expect(after!.status, TaskStatus.planned);
      expect(after.positionInStatus, 0);
      expect(after.description, before!.description);
      expect(after.startAtUtc, before.startAtUtc);
      expect(after.dueAtUtc, before.dueAtUtc);
      expect(after.estimatedDurationMinutes, before.estimatedDurationMinutes);
      expect(after.id, before.id);
      expect(after.displayNumber, before.displayNumber);
      expect(after.createdAtUtc, before.createdAtUtc);

      final planned = await repository.watchByStatus(TaskStatus.planned).first;
      expect(planned.map((task) => task.id), <String>[first.id, second.id]);
      expect(planned[1].description, second.description);
      expect(planned[1].startAtUtc, second.startAtUtc);
      expect(planned[1].dueAtUtc, second.dueAtUtc);
      expect(
        planned[1].estimatedDurationMinutes,
        second.estimatedDurationMinutes,
      );
    } finally {
      await database.close();
    }
  });

  test(
    'task planning fields survive closing and reopening the database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'borj-task-planning-restart-',
      );
      final file = File('${directory.path}/planning.sqlite');

      try {
        final firstDatabase = AppDatabase(NativeDatabase(file));
        final firstRepository = DriftTaskRepository(firstDatabase);
        final task = _planningTask(
          id: 'planning-restart',
          title: 'کار پایدار',
          description: 'توضیحات پایدار',
          startAtUtc: DateTime.utc(2026, 8, 8, 6, 45),
          dueAtUtc: DateTime.utc(2026, 8, 8, 9, 15),
          estimatedDurationMinutes: 150,
          createdAtUtc: DateTime.utc(2026, 8, 4, 12),
        );

        await firstRepository.create(task);
        await firstDatabase.close();

        final reopenedDatabase = AppDatabase(NativeDatabase(file));
        try {
          final reopenedRepository = DriftTaskRepository(reopenedDatabase);
          final reopened = await reopenedRepository.getById(task.id);

          expect(reopened, isNotNull);
          expect(reopened!.description, task.description);
          expect(reopened.startAtUtc, task.startAtUtc);
          expect(reopened.dueAtUtc, task.dueAtUtc);
          expect(
            reopened.estimatedDurationMinutes,
            task.estimatedDurationMinutes,
          );
          expect(reopened.startAtUtc!.isUtc, isTrue);
          expect(reopened.dueAtUtc!.isUtc, isTrue);
          expect(reopened.displayNumber, 1);
          expect(reopened.positionInStatus, 0);
        } finally {
          await reopenedDatabase.close();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}

TaskItem _planningTask({
  required String id,
  required String title,
  required String description,
  required DateTime startAtUtc,
  required DateTime dueAtUtc,
  required int estimatedDurationMinutes,
  required DateTime createdAtUtc,
}) {
  return TaskItem(
    id: id,
    displayNumber: 1,
    title: title,
    description: description,
    priority: 2,
    status: TaskStatus.planned,
    positionInStatus: 0,
    startAtUtc: startAtUtc,
    dueAtUtc: dueAtUtc,
    estimatedDurationMinutes: estimatedDurationMinutes,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: createdAtUtc,
  );
}
