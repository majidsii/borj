import 'package:borj/features/tasks/domain/task_reminder_rule.dart';

abstract interface class TaskReminderRepository {
  Stream<List<TaskReminderRule>> watchByTask(String taskId);

  Future<List<TaskReminderRule>> getByTask(String taskId);

  Future<void> replaceForTask(String taskId, List<TaskReminderRule> expected);

  Future<void> deleteByTask(String taskId);
}
