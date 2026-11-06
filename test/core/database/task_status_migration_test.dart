import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'version two migrates tasks deterministically through schema eight',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'borj-task-status-migration-',
      );
      final file = File('${directory.path}/migration.sqlite');

      try {
        _createVersionTwoFixture(file);

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
            containsAll(<String>['task-a', 'task-b', 'task-c', 'task-d']),
          );

          expect(byId['task-a']!.displayNumber, 1);
          expect(byId['task-b']!.displayNumber, 2);
          expect(byId['task-c']!.displayNumber, 3);
          expect(byId['task-d']!.displayNumber, 4);

          expect(byId['task-b']!.status, TaskStatus.planned.storageValue);
          expect(byId['task-c']!.status, TaskStatus.planned.storageValue);
          expect(byId['task-a']!.status, TaskStatus.completed.storageValue);
          expect(byId['task-d']!.status, TaskStatus.completed.storageValue);

          expect(byId['task-c']!.positionInStatus, 0);
          expect(byId['task-b']!.positionInStatus, 1);
          expect(byId['task-d']!.positionInStatus, 0);
          expect(byId['task-a']!.positionInStatus, 1);

          _expectSameUtcInstant(
            byId['task-a']!.completedAtUtc,
            DateTime.utc(2026, 7, 26, 12),
          );
          _expectSameUtcInstant(
            byId['task-d']!.completedAtUtc,
            DateTime.utc(2026, 7, 26, 14),
          );
          expect(byId['task-b']!.completedAtUtc, isNull);
          expect(byId['task-c']!.completedAtUtc, isNull);
          expect(rows.every((row) => row.canceledAtUtc == null), isTrue);

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
              'priority',
              'status',
              'position_in_status',
              'created_at_utc',
              'updated_at_utc',
              'completed_at_utc',
              'canceled_at_utc',
            }),
          );
          expect(columnNames, isNot(contains('is_done')));
          expect(columnNames, isNot(contains('sort_order')));
        } finally {
          await migrated.close();
        }

        final reopened = AppDatabase(NativeDatabase(file));
        try {
          final rows = await reopened.select(reopened.taskRows).get();
          final snapshot =
              rows
                  .map(
                    (row) => <Object?>[
                      row.id,
                      row.displayNumber,
                      row.status,
                      row.positionInStatus,
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
              'task-a',
              1,
              'completed',
              1,
              DateTime.utc(2026, 7, 26, 12),
              null,
            ],
            <Object?>['task-b', 2, 'planned', 1, null, null],
            <Object?>['task-c', 3, 'planned', 0, null, null],
            <Object?>[
              'task-d',
              4,
              'completed',
              0,
              DateTime.utc(2026, 7, 26, 14),
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

void _expectSameUtcInstant(DateTime? actual, DateTime expectedUtc) {
  if (actual == null) {
    fail('Expected a persisted completion timestamp.');
  }

  expect(actual.millisecondsSinceEpoch, expectedUtc.millisecondsSinceEpoch);
  expect(actual.toUtc(), expectedUtc);
}

void _createVersionTwoFixture(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    database.execute('''
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

    final insert = database.prepare('''
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
    ''');
    try {
      insert.execute(<Object?>[
        'task-b',
        'فعال دوم',
        1,
        0,
        8,
        _seconds(DateTime.utc(2026, 7, 26, 10)),
        _seconds(DateTime.utc(2026, 7, 26, 11)),
        null,
      ]);
      insert.execute(<Object?>[
        'task-a',
        'تکمیل بدون زمان قدیمی',
        2,
        1,
        4,
        _seconds(DateTime.utc(2026, 7, 26, 10)),
        _seconds(DateTime.utc(2026, 7, 26, 12)),
        null,
      ]);
      insert.execute(<Object?>[
        'task-c',
        'فعال اول',
        0,
        0,
        2,
        _seconds(DateTime.utc(2026, 7, 26, 13)),
        _seconds(DateTime.utc(2026, 7, 26, 13)),
        null,
      ]);
      insert.execute(<Object?>[
        'task-d',
        'تکمیل با زمان',
        3,
        1,
        1,
        _seconds(DateTime.utc(2026, 7, 26, 14)),
        _seconds(DateTime.utc(2026, 7, 26, 14)),
        _seconds(DateTime.utc(2026, 7, 26, 14)),
      ]);
    } finally {
      insert.close();
    }

    database.execute('PRAGMA user_version = 2');
  } finally {
    database.close();
  }
}

int _seconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
