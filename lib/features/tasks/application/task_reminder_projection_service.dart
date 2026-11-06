import 'package:borj/core/notifications/notification_coordinator.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/application/task_occurrence_projector.dart';
import 'package:borj/features/tasks/application/task_reminder_projector.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_recurrence_repository.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';

final class TaskReminderProjectionService {
  factory TaskReminderProjectionService({
    required TaskReminderRepository reminderRepository,
    required NotificationCoordinator coordinator,
    required DateTime Function() nowUtc,
    TaskReminderProjector projector = const TaskReminderProjector(),
    TaskRecurrenceRepository? recurrenceRepository,
    TaskOccurrenceProjector occurrenceProjector =
        const TaskOccurrenceProjector(),
    Future<String> Function()? floatingTimeZoneId,
    Duration recurrenceHorizon = const Duration(days: 90),
  }) {
    return TaskReminderProjectionService._(
      reminderRepository,
      coordinator,
      nowUtc,
      projector,
      recurrenceRepository,
      occurrenceProjector,
      floatingTimeZoneId,
      recurrenceHorizon,
    );
  }

  const TaskReminderProjectionService._(
    this._reminderRepository,
    this._coordinator,
    this._nowUtc,
    this._projector,
    this._recurrenceRepository,
    this._occurrenceProjector,
    this._floatingTimeZoneId,
    this._recurrenceHorizon,
  );

  final TaskReminderRepository _reminderRepository;
  final NotificationCoordinator _coordinator;
  final DateTime Function() _nowUtc;
  final TaskReminderProjector _projector;
  final TaskRecurrenceRepository? _recurrenceRepository;
  final TaskOccurrenceProjector _occurrenceProjector;
  final Future<String> Function()? _floatingTimeZoneId;
  final Duration _recurrenceHorizon;

  Future<void> reproject(TaskItem task) async {
    final rules = await _reminderRepository.getByTask(task.id);
    final now = _nowUtc().toUtc();
    final recurrenceRepository = _recurrenceRepository;

    if (recurrenceRepository == null) {
      final expected = _projector.project(
        task: task,
        rules: rules,
        nowUtc: now,
      );
      await _coordinator.replaceByOwner(_owner(task.id), expected);
      return;
    }

    final bundle = await recurrenceRepository.getByTask(task.id);
    final recurrenceRule = bundle.rule;
    if (recurrenceRule == null) {
      final expected = _projector.project(
        task: task,
        rules: rules,
        nowUtc: now,
      );
      await _coordinator.replaceByOwner(_owner(task.id), expected);
      return;
    }

    final timeZoneSource = _floatingTimeZoneId;
    final timeZoneId = timeZoneSource == null ? 'UTC' : await timeZoneSource();
    final occurrences = _occurrenceProjector.project(
      tasks: <TaskItem>[task],
      rules: <TaskRecurrenceRule>[recurrenceRule],
      exceptions: bundle.exceptions,
      completions: bundle.completions,
      rangeStartUtc: now,
      rangeEndUtc: now.add(_recurrenceHorizon),
      floatingTimeZoneId: timeZoneId,
    );
    final expected = _projector.projectForOccurrences(
      task: task,
      rules: rules,
      occurrences: occurrences,
      nowUtc: now,
    );
    await _coordinator.replaceByOwner(_owner(task.id), expected);
  }

  Future<void> clear(String taskId) {
    return _coordinator.replaceByOwner(
      _owner(taskId),
      const <NotificationRequest>[],
    );
  }
}

NotificationOwner _owner(String taskId) {
  return NotificationOwner(type: NotificationOwnerType.task, id: taskId);
}
