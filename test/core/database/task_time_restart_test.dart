import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_time_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_time_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('running timer survives restart and derives elapsed from UTC', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-task-time-restart-',
    );
    final file = File('${directory.path}/timer.sqlite');
    final start = DateTime.utc(2026, 8, 6, 8);

    try {
      final first = AppDatabase(NativeDatabase(file));
      await DriftTaskRepository(first).create(
        TaskItem(
          id: 'task-1',
          displayNumber: 1,
          title: 'کار ماندگار',
          priority: 1,
          status: TaskStatus.planned,
          positionInStatus: 0,
          createdAtUtc: start,
          updatedAtUtc: start,
        ),
      );
      await DriftTaskTimeRepository(first).insert(
        TaskTimeEntry.running(
          id: 'timer-1',
          taskId: 'task-1',
          startedAtUtc: start,
        ),
      );
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      try {
        expect(second.schemaVersion, 9);
        final restored = await DriftTaskTimeRepository(second).getActive();
        expect(restored!.id, 'timer-1');
        expect(
          restored.elapsedSecondsAt(start.add(const Duration(minutes: 12))),
          720,
        );
      } finally {
        await second.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  test('paused timer remains paused without adding offline duration', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-task-time-paused-restart-',
    );
    final file = File('${directory.path}/timer.sqlite');
    final start = DateTime.utc(2026, 8, 6, 8);

    try {
      final first = AppDatabase(NativeDatabase(file));
      await DriftTaskRepository(first).create(
        TaskItem(
          id: 'task-1',
          displayNumber: 1,
          title: 'کار توقف',
          priority: 1,
          status: TaskStatus.planned,
          positionInStatus: 0,
          createdAtUtc: start,
          updatedAtUtc: start,
        ),
      );
      final repository = DriftTaskTimeRepository(first);
      final paused = TaskTimeEntry.running(
        id: 'timer-1',
        taskId: 'task-1',
        startedAtUtc: start,
      ).pause(start.add(const Duration(minutes: 3)));
      await repository.insert(paused);
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      try {
        final restored = await DriftTaskTimeRepository(second).getActive();
        expect(restored!.isPaused, isTrue);
        expect(
          restored.elapsedSecondsAt(start.add(const Duration(days: 2))),
          180,
        );
      } finally {
        await second.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}
