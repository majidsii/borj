import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_template_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_template.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 4);

  TaskItem task(String id) {
    return TaskItem(
      id: id,
      displayNumber: 999,
      title: 'کار موجود',
      priority: 2,
      status: TaskStatus.planned,
      positionInStatus: 99,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  TaskTemplate custom(String id) {
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.custom,
      templateName: 'قالب پایدار',
      initialTaskTitle: 'کار قالبی …',
      priority: 2,
      estimatedDurationMinutes: 45,
      hidden: false,
      displayOrder: 99,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  test('schema version 8 contains task_templates', () async {
    final database = AppDatabase(NativeDatabase.memory());

    try {
      expect(database.schemaVersion, 9);
      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'task_templates'",
          )
          .get();
      expect(rows, hasLength(1));
    } finally {
      await database.close();
    }
  });

  test('schema 7 to 8 migration preserves task data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-task-template-migration-',
    );
    final file = File('${directory.path}/dashboard.sqlite');

    final seededDatabase = AppDatabase(NativeDatabase(file));
    final seededTaskRepository = DriftTaskRepository(seededDatabase);

    await seededTaskRepository.create(task('existing-task'));
    await seededDatabase.close();

    final raw = sqlite3.open(file.path);
    try {
      raw.execute('DROP TABLE task_templates');
      raw.execute('PRAGMA user_version = 7');
    } finally {
      raw.close();
    }

    final upgradedDatabase = AppDatabase(NativeDatabase(file));
    final upgradedTaskRepository = DriftTaskRepository(upgradedDatabase);

    try {
      final existing = await upgradedTaskRepository.getById('existing-task');
      expect(existing, isNotNull);
      expect(existing!.title, 'کار موجود');

      final tables = await upgradedDatabase
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'task_templates'",
          )
          .get();
      expect(tables, hasLength(1));
    } finally {
      await upgradedDatabase.close();
      await directory.delete(recursive: true);
    }
  });

  test('custom templates survive restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-task-template-restart-',
    );
    final file = File('${directory.path}/dashboard.sqlite');

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = DriftTaskTemplateRepository(firstDatabase);

    await firstRepository.createCustom(custom('persistent-template'));
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    final reopenedRepository = DriftTaskTemplateRepository(reopenedDatabase);

    try {
      final persisted = await reopenedRepository.getById('persistent-template');
      expect(persisted, isNotNull);
      expect(persisted!.templateName, 'قالب پایدار');
      expect(persisted.displayOrder, 0);
    } finally {
      await reopenedDatabase.close();
      await directory.delete(recursive: true);
    }
  });
}
