import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/data/drift_task_time_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema version six upgrades append-only to timer schema eight',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dashboard-task-time-migration-',
      );
      final file = File('${directory.path}/migration.sqlite');
      final now = DateTime.utc(2026, 8, 6, 8);

      try {
        final created = AppDatabase(NativeDatabase(file));
        await DriftTaskRepository(created).create(
          TaskItem(
            id: 'existing-task',
            displayNumber: 1,
            title: 'کار موجود',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 0,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await created.close();

        final raw = sqlite.sqlite3.open(file.path);
        try {
          raw.execute('DROP TABLE task_time_entries');
          raw.execute('PRAGMA user_version = 6');
        } finally {
          raw.close();
        }

        final upgraded = AppDatabase(NativeDatabase(file));
        try {
          expect(upgraded.schemaVersion, 9);
          final versionRows = await upgraded
              .customSelect('PRAGMA user_version')
              .get();
          expect(versionRows.single.read<int>('user_version'), 9);
          expect(
            (await DriftTaskRepository(
              upgraded,
            ).getById('existing-task'))!.title,
            'کار موجود',
          );

          final repository = DriftTaskTimeRepository(upgraded);
          await repository.insert(
            TaskTimeEntry.running(
              id: 'migrated-timer',
              taskId: 'existing-task',
              startedAtUtc: now,
            ),
          );
          expect((await repository.getActive())!.id, 'migrated-timer');
        } finally {
          await upgraded.close();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}
