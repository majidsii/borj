import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';

final class TaskReminderDraft {
  const TaskReminderDraft({
    required this.trigger,
    required this.selected,
    required this.privacyMode,
    this.existingId,
    this.createdAtUtc,
  });

  factory TaskReminderDraft.empty(TaskReminderTrigger trigger) {
    return TaskReminderDraft(
      trigger: trigger,
      selected: false,
      privacyMode: NotificationPrivacyMode.full,
    );
  }

  factory TaskReminderDraft.fromRule(TaskReminderRule rule) {
    return TaskReminderDraft(
      trigger: rule.trigger,
      selected: rule.enabled,
      privacyMode: rule.privacyMode,
      existingId: rule.id,
      createdAtUtc: rule.createdAtUtc,
    );
  }

  final TaskReminderTrigger trigger;
  final bool selected;
  final NotificationPrivacyMode privacyMode;
  final String? existingId;
  final DateTime? createdAtUtc;

  TaskReminderDraft copyWith({
    bool? selected,
    NotificationPrivacyMode? privacyMode,
  }) {
    return TaskReminderDraft(
      trigger: trigger,
      selected: selected ?? this.selected,
      privacyMode: privacyMode ?? this.privacyMode,
      existingId: existingId,
      createdAtUtc: createdAtUtc,
    );
  }

  TaskReminderRule buildRule({
    required String taskId,
    required DateTime savedAtUtc,
    required String Function() nextId,
  }) {
    return TaskReminderRule(
      id: existingId ?? nextId(),
      taskId: taskId,
      trigger: trigger,
      enabled: selected,
      privacyMode: privacyMode,
      createdAtUtc: createdAtUtc ?? savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }
}

List<TaskReminderDraft> taskReminderDraftsFromRules(
  List<TaskReminderRule> rules,
) {
  final byTrigger = <TaskReminderTrigger, TaskReminderRule>{
    for (final rule in rules) rule.trigger: rule,
  };
  return List<TaskReminderDraft>.unmodifiable(
    TaskReminderTrigger.values.map((trigger) {
      final rule = byTrigger[trigger];
      return rule == null
          ? TaskReminderDraft.empty(trigger)
          : TaskReminderDraft.fromRule(rule);
    }),
  );
}
