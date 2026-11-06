import 'package:borj/features/tasks/application/task_reminder_projection_service.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';

final class TaskReminderRulesService {
  factory TaskReminderRulesService({
    required TaskReminderRepository repository,
    required TaskReminderProjectionService projection,
  }) {
    return TaskReminderRulesService._(repository, projection);
  }

  const TaskReminderRulesService._(this._repository, this._projection);

  final TaskReminderRepository _repository;
  final TaskReminderProjectionService _projection;

  Future<void> replaceForTask({
    required TaskItem task,
    required List<TaskReminderRule> rules,
  }) async {
    await _repository.replaceForTask(task.id, rules);
    await _projection.reproject(task);
  }

  Future<void> deleteForTask(String taskId) async {
    await _repository.deleteByTask(taskId);
    await _projection.clear(taskId);
  }
}
