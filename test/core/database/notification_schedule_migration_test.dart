import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'version one migrates notifications, tasks, and reminders through schema eight',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'borj-notification-migration-',
      );
      final file = File('${directory.path}/migration.sqlite');

      try {
        final now = DateTime.utc(2026, 7, 27, 8);
        final raw = sqlite.sqlite3.open(file.path);
        try {
          raw.execute('''
          CREATE TABLE tasks (
            id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            priority INTEGER NOT NULL CHECK (priority BETWEEN 0 AND 3),
            is_done INTEGER NOT NULL DEFAULT 0 CHECK (is_done IN (0, 1)),
            sort_order INTEGER NOT NULL,
            created_at_utc INTEGER NOT NULL,
            updated_at_utc INTEGER NOT NULL,
            completed_at_utc INTEGER NULL
          )
        ''');
          raw.execute(
            '''
          INSERT INTO tasks (
            id,
            title,
            priority,
            is_done,
            sort_order,
            created_at_utc,
            updated_at_utc,
            completed_at_utc
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
            <Object?>[
              'task-before-migration',
              'تسک قبل از مهاجرت',
              2,
              0,
              0,
              now.millisecondsSinceEpoch ~/ 1000,
              now.millisecondsSinceEpoch ~/ 1000,
              null,
            ],
          );
          raw.execute('PRAGMA user_version = 1');
        } finally {
          raw.close();
        }

        final migrated = AppDatabase(NativeDatabase(file));
        try {
          expect(migrated.schemaVersion, 9);

          final versionRows = await migrated
              .customSelect('PRAGMA user_version')
              .get();
          expect(versionRows.single.read<int>('user_version'), 9);

          final tasks = await migrated.select(migrated.taskRows).get();
          expect(tasks, hasLength(1));
          expect(tasks.single.id, 'task-before-migration');
          expect(tasks.single.displayNumber, 1);
          expect(tasks.single.status, TaskStatus.planned.storageValue);
          expect(tasks.single.positionInStatus, 0);

          final tableRows = await migrated
              .customSelect(
                "SELECT name FROM sqlite_master "
                "WHERE type = 'table' AND name = 'notification_schedules'",
              )
              .get();
          expect(tableRows, hasLength(1));
        } finally {
          await migrated.close();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}
