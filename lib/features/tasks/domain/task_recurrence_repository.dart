import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_bundle.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';

abstract interface class TaskRecurrenceRepository {
  Stream<List<TaskRecurrenceRule>> watchRules();

  Stream<List<TaskRecurrenceException>> watchExceptions();

  Stream<List<TaskOccurrenceCompletion>> watchCompletions();

  Future<TaskRecurrenceBundle> getByTask(String taskId);

  Future<void> replaceRule({
    required String taskId,
    required TaskRecurrenceRule? rule,
  });

  Future<void> upsertException(TaskRecurrenceException exception);

  Future<void> deleteException({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  });

  Future<void> setCompletion(TaskOccurrenceCompletion completion);

  Future<void> clearCompletion({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  });

  Future<void> clearTask(String taskId);
}
