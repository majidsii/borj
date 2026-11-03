import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'version three migrates task planning fields deterministically through schema eight',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dashboard-shakhsi-task-planning-migration-',
      );
      final file = File('${directory.path}/migration.sqlite');

      try {
        _createVersionThreeFixture(file);

        final migrated = AppDatabase(NativeDatabase(file));
        try {
          expect(migrated.schemaVersion, 9);

          final versionRows = await migrated
              .customSelect('PRAGMA user_version')
              .get();
          expect(versionRows.single.read<int>('user_version'), 9);

          final rows = await migrated.select(migrated.taskRows).get();
          final byId = <String, TaskRow>{for (final row in rows) row.id: row};

          expect(rows, hasLength(4));
          expect(
            byId.keys,
            containsAll(<String>[
              'task-planned',
              'task-progress',
              'task-completed',
              'task-canceled',
            ]),
          );

          _expectLegacyRow(
            byId['task-planned']!,
            displayNumber: 11,
            title: 'کار برنامه‌ریزی‌شده',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 2,
            createdAtUtc: DateTime.utc(2026, 8, 1, 8),
            updatedAtUtc: DateTime.utc(2026, 8, 1, 9),
          );
          _expectLegacyRow(
            byId['task-progress']!,
            displayNumber: 7,
            title: 'کار در حال انجام',
            priority: 3,
            status: TaskStatus.inProgress,
            positionInStatus: 4,
            createdAtUtc: DateTime.utc(2026, 8, 1, 10),
            updatedAtUtc: DateTime.utc(2026, 8, 1, 11),
          );
          _expectLegacyRow(
            byId['task-completed']!,
            displayNumber: 3,
            title: 'کار تکمیل‌شده',
            priority: 2,
            status: TaskStatus.completed,
            positionInStatus: 1,
            createdAtUtc: DateTime.utc(2026, 8, 1, 12),
            updatedAtUtc: DateTime.utc(2026, 8, 1, 13),
            completedAtUtc: DateTime.utc(2026, 8, 1, 13),
          );
          _expectLegacyRow(
            byId['task-canceled']!,
            displayNumber: 19,
            title: 'کار لغوشده',
            priority: 0,
            status: TaskStatus.canceled,
            positionInStatus: 6,
            createdAtUtc: DateTime.utc(2026, 8, 1, 14),
            updatedAtUtc: DateTime.utc(2026, 8, 1, 15),
            canceledAtUtc: DateTime.utc(2026, 8, 1, 15),
          );

          for (final row in rows) {
            expect(row.description, isNull);
            expect(row.startAtUtc, isNull);
            expect(row.dueAtUtc, isNull);
            expect(row.estimatedDurationMinutes, isNull);
          }

          final columns = await migrated
              .customSelect('PRAGMA table_info(tasks)')
              .get();
          final columnNames = columns
              .map((row) => row.read<String>('name'))
              .toSet();

          expect(
            columnNames,
            containsAll(<String>{
              'id',
              'display_number',
              'title',
              'description',
              'priority',
              'status',
              'position_in_status',
              'start_at_utc',
              'due_at_utc',
              'estimated_duration_minutes',
              'created_at_utc',
              'updated_at_utc',
              'completed_at_utc',
              'canceled_at_utc',
            }),
          );

          await expectLater(
            migrated.customStatement('''
              INSERT INTO tasks (
                id,
                display_number,
                title,
                priority,
                status,
                position_in_status,
                estimated_duration_minutes,
                created_at_utc,
                updated_at_utc
              ) VALUES (
                'invalid-duration',
                100,
                'مدت نامعتبر',
                1,
                'planned',
                0,
                0,
                1785571200,
                1785571200
              )
            '''),
            throwsA(anything),
          );

          await expectLater(
            migrated.customStatement('''
              INSERT INTO tasks (
                id,
                display_number,
                title,
                priority,
                status,
                position_in_status,
                start_at_utc,
                due_at_utc,
                created_at_utc,
                updated_at_utc
              ) VALUES (
                'invalid-order',
                101,
                'زمان نامعتبر',
                1,
                'planned',
                0,
                1785578400,
                1785574800,
                1785571200,
                1785571200
              )
            '''),
            throwsA(anything),
          );
        } finally {
          await migrated.close();
        }

        final reopened = AppDatabase(NativeDatabase(file));
        try {
          expect(reopened.schemaVersion, 9);
          final rows = await reopened.select(reopened.taskRows).get();
          final snapshot =
              rows
                  .map(
                    (row) => <Object?>[
                      row.id,
                      row.displayNumber,
                      row.title,
                      row.priority,
                      row.status,
                      row.positionInStatus,
                      row.description,
                      row.startAtUtc,
                      row.dueAtUtc,
                      row.estimatedDurationMinutes,
                      row.createdAtUtc.toUtc(),
                      row.updatedAtUtc.toUtc(),
                      row.completedAtUtc?.toUtc(),
                      row.canceledAtUtc?.toUtc(),
                    ],
                  )
                  .toList(growable: false)
                ..sort(
                  (left, right) =>
                      (left.first! as String).compareTo(right.first! as String),
                );

          expect(snapshot, <List<Object?>>[
            <Object?>[
              'task-canceled',
              19,
              'کار لغوشده',
              0,
              'canceled',
              6,
              null,
              null,
              null,
              null,
              DateTime.utc(2026, 8, 1, 14),
              DateTime.utc(2026, 8, 1, 15),
              null,
              DateTime.utc(2026, 8, 1, 15),
            ],
            <Object?>[
              'task-completed',
              3,
              'کار تکمیل‌شده',
              2,
              'completed',
              1,
              null,
              null,
              null,
              null,
              DateTime.utc(2026, 8, 1, 12),
              DateTime.utc(2026, 8, 1, 13),
              DateTime.utc(2026, 8, 1, 13),
              null,
            ],
            <Object?>[
              'task-planned',
              11,
              'کار برنامه‌ریزی‌شده',
              1,
              'planned',
              2,
              null,
              null,
              null,
              null,
              DateTime.utc(2026, 8, 1, 8),
              DateTime.utc(2026, 8, 1, 9),
              null,
              null,
            ],
            <Object?>[
              'task-progress',
              7,
              'کار در حال انجام',
              3,
              'inProgress',
              4,
              null,
              null,
              null,
              null,
              DateTime.utc(2026, 8, 1, 10),
              DateTime.utc(2026, 8, 1, 11),
              null,
              null,
            ],
          ]);
        } finally {
          await reopened.close();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}

void _expectLegacyRow(
  TaskRow row, {
  required int displayNumber,
  required String title,
  required int priority,
  required TaskStatus status,
  required int positionInStatus,
  required DateTime createdAtUtc,
  required DateTime updatedAtUtc,
  DateTime? completedAtUtc,
  DateTime? canceledAtUtc,
}) {
  expect(row.displayNumber, displayNumber);
  expect(row.title, title);
  expect(row.priority, priority);
  expect(row.status, status.storageValue);
  expect(row.positionInStatus, positionInStatus);
  _expectSameUtcInstant(row.createdAtUtc, createdAtUtc);
  _expectSameUtcInstant(row.updatedAtUtc, updatedAtUtc);

  if (completedAtUtc == null) {
    expect(row.completedAtUtc, isNull);
  } else {
    _expectSameUtcInstant(row.completedAtUtc!, completedAtUtc);
  }

  if (canceledAtUtc == null) {
    expect(row.canceledAtUtc, isNull);
  } else {
    _expectSameUtcInstant(row.canceledAtUtc!, canceledAtUtc);
  }
}

void _expectSameUtcInstant(DateTime actual, DateTime expectedUtc) {
  expect(actual.millisecondsSinceEpoch, expectedUtc.millisecondsSinceEpoch);
  expect(actual.toUtc(), expectedUtc);
}

void _createVersionThreeFixture(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    database.execute('''
      CREATE TABLE tasks (
        id TEXT NOT NULL PRIMARY KEY,
        display_number INTEGER NOT NULL UNIQUE,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL,
        status TEXT NOT NULL,
        position_in_status INTEGER NOT NULL,
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL,
        completed_at_utc INTEGER NULL,
        canceled_at_utc INTEGER NULL,
        CHECK (display_number > 0),
        CHECK (priority BETWEEN 0 AND 3),
        CHECK (status IN ('planned', 'inProgress', 'completed', 'canceled')),
        CHECK (position_in_status >= 0),
        CHECK (
          (status = 'completed'
            AND completed_at_utc IS NOT NULL
            AND canceled_at_utc IS NULL)
          OR
          (status = 'canceled'
            AND canceled_at_utc IS NOT NULL
            AND completed_at_utc IS NULL)
          OR
          (status IN ('planned', 'inProgress')
            AND completed_at_utc IS NULL
            AND canceled_at_utc IS NULL)
        )
      )
    ''');

    final insert = database.prepare('''
      INSERT INTO tasks (
        id,
        display_number,
        title,
        priority,
        status,
        position_in_status,
        created_at_utc,
        updated_at_utc,
        completed_at_utc,
        canceled_at_utc
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    try {
      insert.execute(<Object?>[
        'task-planned',
        11,
        'کار برنامه‌ریزی‌شده',
        1,
        'planned',
        2,
        _seconds(DateTime.utc(2026, 8, 1, 8)),
        _seconds(DateTime.utc(2026, 8, 1, 9)),
        null,
        null,
      ]);
      insert.execute(<Object?>[
        'task-progress',
        7,
        'کار در حال انجام',
        3,
        'inProgress',
        4,
        _seconds(DateTime.utc(2026, 8, 1, 10)),
        _seconds(DateTime.utc(2026, 8, 1, 11)),
        null,
        null,
      ]);
      insert.execute(<Object?>[
        'task-completed',
        3,
        'کار تکمیل‌شده',
        2,
        'completed',
        1,
        _seconds(DateTime.utc(2026, 8, 1, 12)),
        _seconds(DateTime.utc(2026, 8, 1, 13)),
        _seconds(DateTime.utc(2026, 8, 1, 13)),
        null,
      ]);
      insert.execute(<Object?>[
        'task-canceled',
        19,
        'کار لغوشده',
        0,
        'canceled',
        6,
        _seconds(DateTime.utc(2026, 8, 1, 14)),
        _seconds(DateTime.utc(2026, 8, 1, 15)),
        null,
        _seconds(DateTime.utc(2026, 8, 1, 15)),
      ]);
    } finally {
      insert.close();
    }

    database.execute('PRAGMA user_version = 3');
  } finally {
    database.close();
  }
}

int _seconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
