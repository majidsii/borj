import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_reminder_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_rule.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_trigger.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema version four upgrades through reminder and recurrence schema eight',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dashboard-task-reminder-migration-',
      );
      final file = File('${directory.path}/migration.sqlite');

      try {
        final created = AppDatabase(NativeDatabase(file));
        expect(created.schemaVersion, 9);
        await created.select(created.taskReminderRuleRows).get();
        await created.close();

        final raw = sqlite.sqlite3.open(file.path);
        try {
          raw.execute('DROP TABLE task_reminder_rules');
          raw.execute('DROP TABLE task_time_entries');
          raw.execute('PRAGMA user_version = 4');
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

          final taskRepository = DriftTaskRepository(upgraded);
          final reminderRepository = DriftTaskReminderRepository(upgraded);
          final task = TaskItem(
            id: 'migrated-task',
            displayNumber: 1,
            title: 'کار مهاجرت',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 0,
            dueAtUtc: DateTime.utc(2026, 8, 7, 12),
            createdAtUtc: DateTime.utc(2026, 8, 4),
            updatedAtUtc: DateTime.utc(2026, 8, 4),
          );
          await taskRepository.create(task);
          await reminderRepository.replaceForTask(task.id, <TaskReminderRule>[
            TaskReminderRule(
              id: 'migrated-rule',
              taskId: task.id,
              trigger: TaskReminderTrigger.oneHourBefore,
              createdAtUtc: DateTime.utc(2026, 8, 4),
              updatedAtUtc: DateTime.utc(2026, 8, 4),
            ),
          ]);

          expect(await reminderRepository.getByTask(task.id), hasLength(1));
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
