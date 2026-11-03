import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_local_date_time.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_rule.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_recurrence_rule.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('schema version five upgrades to recurring task schema eight', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-task-recurrence-migration-',
    );
    final file = File('${directory.path}/migration.sqlite');

    try {
      final created = AppDatabase(NativeDatabase(file));
      expect(created.schemaVersion, 9);
      await created.select(created.taskRecurrenceRuleRows).get();
      await created.close();

      final raw = sqlite.sqlite3.open(file.path);
      try {
        raw.execute('DROP TABLE task_occurrence_completions');
        raw.execute('DROP TABLE task_time_entries');
        raw.execute('DROP TABLE task_recurrence_exceptions');
        raw.execute('DROP TABLE task_recurrence_rules');
        raw.execute('PRAGMA user_version = 5');
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
        final recurrenceRepository = DriftTaskRecurrenceRepository(upgraded);
        final now = DateTime.utc(2026, 8, 6, 8);
        await taskRepository.create(
          TaskItem(
            id: 'migrated-task',
            displayNumber: 1,
            title: 'کار مهاجرت تکرار',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 0,
            dueAtUtc: DateTime.utc(2026, 8, 7, 9),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await recurrenceRepository.replaceRule(
          taskId: 'migrated-task',
          rule: TaskRecurrenceRule(
            id: 'migrated-rule',
            taskId: 'migrated-task',
            rule: RecurrenceRule.daily(
              anchorLocalDateTime: RecurrenceLocalDateTime(
                year: 2026,
                month: 8,
                day: 7,
                hour: 9,
              ),
            ),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );

        expect(
          (await recurrenceRepository.getByTask('migrated-task')).rule,
          isNotNull,
        );
      } finally {
        await upgraded.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}
