import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:drift/drift.dart';

final class DriftTaskReminderRepository implements TaskReminderRepository {
  const DriftTaskReminderRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TaskReminderRule>> watchByTask(String taskId) {
    final normalizedTaskId = _requiredTaskId(taskId);
    final query = _database.select(_database.taskReminderRuleRows)
      ..where((row) => row.taskId.equals(normalizedTaskId))
      ..orderBy(<OrderingTerm Function(TaskReminderRuleRows)>[
        (row) => OrderingTerm.asc(row.trigger),
        (row) => OrderingTerm.asc(row.id),
      ]);

    return query.watch().map(
      (rows) => rows.map(_ruleFromRow).toList(growable: false),
    );
  }

  @override
  Future<List<TaskReminderRule>> getByTask(String taskId) async {
    final normalizedTaskId = _requiredTaskId(taskId);
    final query = _database.select(_database.taskReminderRuleRows)
      ..where((row) => row.taskId.equals(normalizedTaskId))
      ..orderBy(<OrderingTerm Function(TaskReminderRuleRows)>[
        (row) => OrderingTerm.asc(row.trigger),
        (row) => OrderingTerm.asc(row.id),
      ]);

    final rows = await query.get();
    return rows.map(_ruleFromRow).toList(growable: false);
  }

  @override
  Future<void> replaceForTask(
    String taskId,
    List<TaskReminderRule> expected,
  ) async {
    final normalizedTaskId = _requiredTaskId(taskId);
    final desiredByTrigger = <TaskReminderTrigger, TaskReminderRule>{};

    for (final rule in expected) {
      if (rule.taskId != normalizedTaskId) {
        throw ArgumentError.value(
          rule.taskId,
          'expected',
          'Every reminder rule must belong to $normalizedTaskId.',
        );
      }
      if (desiredByTrigger.containsKey(rule.trigger)) {
        throw ArgumentError.value(
          expected,
          'expected',
          'A task cannot contain duplicate reminder triggers.',
        );
      }
      desiredByTrigger[rule.trigger] = rule;
    }

    await _database.transaction(() async {
      final existingRows = await (_database.select(
        _database.taskReminderRuleRows,
      )..where((row) => row.taskId.equals(normalizedTaskId))).get();

      for (final row in existingRows) {
        final trigger = TaskReminderTrigger.parseStorage(row.trigger);
        final desired = desiredByTrigger[trigger];
        if (desired == null || desired.id != row.id) {
          await (_database.delete(
            _database.taskReminderRuleRows,
          )..where((item) => item.id.equals(row.id))).go();
        }
      }

      for (final rule in desiredByTrigger.values) {
        await _database
            .into(_database.taskReminderRuleRows)
            .insertOnConflictUpdate(_companionFromRule(rule));
      }
    });
  }

  @override
  Future<void> deleteByTask(String taskId) async {
    final normalizedTaskId = _requiredTaskId(taskId);
    await (_database.delete(
      _database.taskReminderRuleRows,
    )..where((row) => row.taskId.equals(normalizedTaskId))).go();
  }
}

TaskReminderRule _ruleFromRow(TaskReminderRuleRow row) {
  return TaskReminderRule(
    id: row.id,
    taskId: row.taskId,
    trigger: TaskReminderTrigger.parseStorage(row.trigger),
    enabled: row.enabled,
    privacyMode: NotificationPrivacyMode.values.byName(row.privacyMode),
    createdAtUtc: row.createdAtUtc.toUtc(),
    updatedAtUtc: row.updatedAtUtc.toUtc(),
  );
}

TaskReminderRuleRowsCompanion _companionFromRule(TaskReminderRule rule) {
  return TaskReminderRuleRowsCompanion(
    id: Value<String>(rule.id),
    taskId: Value<String>(rule.taskId),
    trigger: Value<String>(rule.trigger.storageValue),
    enabled: Value<bool>(rule.enabled),
    privacyMode: Value<String>(rule.privacyMode.name),
    createdAtUtc: Value<DateTime>(rule.createdAtUtc),
    updatedAtUtc: Value<DateTime>(rule.updatedAtUtc),
  );
}

String _requiredTaskId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'taskId', 'Task id cannot be blank.');
  }
  return normalized;
}
