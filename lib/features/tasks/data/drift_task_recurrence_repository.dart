import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/tasks/data/task_recurrence_codec.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_bundle.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_repository.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:drift/drift.dart';

final class DriftTaskRecurrenceRepository implements TaskRecurrenceRepository {
  const DriftTaskRecurrenceRepository(
    this._database, {
    this._codec = const TaskRecurrenceCodec(),
  });

  final AppDatabase _database;
  final TaskRecurrenceCodec _codec;

  @override
  Stream<List<TaskRecurrenceRule>> watchRules() {
    final query = _database.select(_database.taskRecurrenceRuleRows)
      ..orderBy(<OrderingTerm Function(TaskRecurrenceRuleRows)>[
        (row) => OrderingTerm.asc(row.taskId),
      ]);
    return query.watch().map(
      (rows) => rows.map(_ruleFromRow).toList(growable: false),
    );
  }

  @override
  Stream<List<TaskRecurrenceException>> watchExceptions() {
    final query = _database.select(_database.taskRecurrenceExceptionRows)
      ..orderBy(<OrderingTerm Function(TaskRecurrenceExceptionRows)>[
        (row) => OrderingTerm.asc(row.taskId),
        (row) => OrderingTerm.asc(row.originalLocalKey),
      ]);
    return query.watch().map(
      (rows) => rows.map(_exceptionFromRow).toList(growable: false),
    );
  }

  @override
  Stream<List<TaskOccurrenceCompletion>> watchCompletions() {
    final query = _database.select(_database.taskOccurrenceCompletionRows)
      ..orderBy(<OrderingTerm Function(TaskOccurrenceCompletionRows)>[
        (row) => OrderingTerm.asc(row.taskId),
        (row) => OrderingTerm.asc(row.originalLocalKey),
      ]);
    return query.watch().map(
      (rows) => rows.map(_completionFromRow).toList(growable: false),
    );
  }

  @override
  Future<TaskRecurrenceBundle> getByTask(String taskId) async {
    final ruleRow = await (_database.select(
      _database.taskRecurrenceRuleRows,
    )..where((row) => row.taskId.equals(taskId))).getSingleOrNull();

    final exceptionRows = await (_database.select(
      _database.taskRecurrenceExceptionRows,
    )..where((row) => row.taskId.equals(taskId))).get();

    final completionRows = await (_database.select(
      _database.taskOccurrenceCompletionRows,
    )..where((row) => row.taskId.equals(taskId))).get();

    return TaskRecurrenceBundle(
      taskId: taskId,
      rule: ruleRow == null ? null : _ruleFromRow(ruleRow),
      exceptions: exceptionRows.map(_exceptionFromRow).toList(growable: false),
      completions: completionRows
          .map(_completionFromRow)
          .toList(growable: false),
    );
  }

  @override
  Future<void> replaceRule({
    required String taskId,
    required TaskRecurrenceRule? rule,
  }) {
    return _database.transaction(() async {
      if (rule != null && rule.taskId != taskId) {
        throw ArgumentError.value(
          rule.taskId,
          'rule',
          'Recurrence rule belongs to a different task.',
        );
      }

      await (_database.delete(
        _database.taskRecurrenceRuleRows,
      )..where((row) => row.taskId.equals(taskId))).go();

      if (rule == null) {
        await (_database.delete(
          _database.taskRecurrenceExceptionRows,
        )..where((row) => row.taskId.equals(taskId))).go();
        await (_database.delete(
          _database.taskOccurrenceCompletionRows,
        )..where((row) => row.taskId.equals(taskId))).go();
        return;
      }

      await _database
          .into(_database.taskRecurrenceRuleRows)
          .insert(
            TaskRecurrenceRuleRowsCompanion.insert(
              id: rule.id,
              taskId: rule.taskId,
              ruleJson: _codec.encodeRule(rule.rule),
              createdAtUtc: rule.createdAtUtc,
              updatedAtUtc: rule.updatedAtUtc,
            ),
          );
    });
  }

  @override
  Future<void> upsertException(TaskRecurrenceException exception) {
    final originalKey = exception.exception.originalLocalDateTime.storageKey;
    return _database.transaction(() async {
      await (_database.delete(_database.taskRecurrenceExceptionRows)..where(
            (row) =>
                row.taskId.equals(exception.taskId) &
                row.originalLocalKey.equals(originalKey),
          ))
          .go();

      await _database
          .into(_database.taskRecurrenceExceptionRows)
          .insert(
            TaskRecurrenceExceptionRowsCompanion.insert(
              id: exception.id,
              taskId: exception.taskId,
              originalLocalKey: originalKey,
              exceptionJson: _codec.encodeException(exception.exception),
              createdAtUtc: exception.createdAtUtc,
              updatedAtUtc: exception.updatedAtUtc,
            ),
          );
    });
  }

  @override
  Future<void> deleteException({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) async {
    await (_database.delete(_database.taskRecurrenceExceptionRows)..where(
          (row) =>
              row.taskId.equals(taskId) &
              row.originalLocalKey.equals(originalLocalDateTime.storageKey),
        ))
        .go();
  }

  @override
  Future<void> setCompletion(TaskOccurrenceCompletion completion) {
    return _database.transaction(() async {
      await (_database.delete(_database.taskOccurrenceCompletionRows)..where(
            (row) =>
                row.taskId.equals(completion.taskId) &
                row.originalLocalKey.equals(
                  completion.originalLocalDateTime.storageKey,
                ),
          ))
          .go();

      await _database
          .into(_database.taskOccurrenceCompletionRows)
          .insert(
            TaskOccurrenceCompletionRowsCompanion.insert(
              taskId: completion.taskId,
              originalLocalKey: completion.originalLocalDateTime.storageKey,
              completedAtUtc: completion.completedAtUtc,
              createdAtUtc: completion.createdAtUtc,
              updatedAtUtc: completion.updatedAtUtc,
            ),
          );
    });
  }

  @override
  Future<void> clearCompletion({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) async {
    await (_database.delete(_database.taskOccurrenceCompletionRows)..where(
          (row) =>
              row.taskId.equals(taskId) &
              row.originalLocalKey.equals(originalLocalDateTime.storageKey),
        ))
        .go();
  }

  @override
  Future<void> clearTask(String taskId) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.taskRecurrenceExceptionRows,
      )..where((row) => row.taskId.equals(taskId))).go();
      await (_database.delete(
        _database.taskOccurrenceCompletionRows,
      )..where((row) => row.taskId.equals(taskId))).go();
      await (_database.delete(
        _database.taskRecurrenceRuleRows,
      )..where((row) => row.taskId.equals(taskId))).go();
    });
  }

  TaskRecurrenceRule _ruleFromRow(TaskRecurrenceRuleRow row) {
    return TaskRecurrenceRule(
      id: row.id,
      taskId: row.taskId,
      rule: _codec.decodeRule(row.ruleJson),
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  TaskRecurrenceException _exceptionFromRow(TaskRecurrenceExceptionRow row) {
    final exception = _codec.decodeException(row.exceptionJson);
    if (exception.originalLocalDateTime.storageKey != row.originalLocalKey) {
      throw StateError('Stored recurrence exception identity is inconsistent.');
    }
    return TaskRecurrenceException(
      id: row.id,
      taskId: row.taskId,
      exception: exception,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  TaskOccurrenceCompletion _completionFromRow(TaskOccurrenceCompletionRow row) {
    return TaskOccurrenceCompletion(
      taskId: row.taskId,
      originalLocalDateTime: _codec.decodeLocalDateTime(row.originalLocalKey),
      completedAtUtc: row.completedAtUtc.toUtc(),
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }
}
