import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recurrence state survives restart with stable occurrence identity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dashboard-task-recurrence-restart-',
      );
      final file = File('${directory.path}/recurrence.sqlite');
      final now = DateTime.utc(2026, 8, 6, 8);
      final original = RecurrenceLocalDateTime(
        year: 2026,
        month: 8,
        day: 7,
        hour: 9,
      );

      try {
        final first = AppDatabase(NativeDatabase(file));
        final taskRepository = DriftTaskRepository(first);
        final recurrenceRepository = DriftTaskRecurrenceRepository(first);
        await taskRepository.create(
          TaskItem(
            id: 'restart-task',
            displayNumber: 1,
            title: 'کار تکرار ماندگار',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 0,
            dueAtUtc: DateTime.utc(2026, 8, 7, 9),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await recurrenceRepository.replaceRule(
          taskId: 'restart-task',
          rule: TaskRecurrenceRule(
            id: 'restart-rule',
            taskId: 'restart-task',
            rule: RecurrenceRule.daily(
              anchorLocalDateTime: original,
              interval: 2,
            ),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await recurrenceRepository.upsertException(
          TaskRecurrenceException(
            id: 'restart-exception',
            taskId: 'restart-task',
            exception: RecurrenceException.move(
              originalLocalDateTime: original,
              movedToLocalDateTime: original.copyWith(hour: 11),
            ),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await recurrenceRepository.setCompletion(
          TaskOccurrenceCompletion(
            taskId: 'restart-task',
            originalLocalDateTime: original,
            completedAtUtc: now,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        await first.close();

        final second = AppDatabase(NativeDatabase(file));
        try {
          expect(second.schemaVersion, 9);
          final restored = await DriftTaskRecurrenceRepository(
            second,
          ).getByTask('restart-task');

          expect(restored.rule!.id, 'restart-rule');
          expect(restored.rule!.rule.interval, 2);
          expect(restored.exceptions.single.id, 'restart-exception');
          expect(
            restored.exceptions.single.exception.movedToLocalDateTime,
            original.copyWith(hour: 11),
          );
          expect(
            restored.completions.single.occurrenceKey,
            'restart-task@2026-08-07T09:00',
          );
        } finally {
          await second.close();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}
