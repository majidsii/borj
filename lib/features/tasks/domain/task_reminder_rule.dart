import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';

final class TaskReminderRule {
  TaskReminderRule({
    required String id,
    required String taskId,
    required this.trigger,
    this.enabled = true,
    this.privacyMode = NotificationPrivacyMode.full,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : id = id.trim(),
       taskId = taskId.trim() {
    if (this.id.isEmpty) {
      throw const ValidationFailure('شناسه یادآور نمی‌تواند خالی باشد.');
    }
    if (this.taskId.isEmpty) {
      throw const ValidationFailure('شناسه کار یادآور نمی‌تواند خالی باشد.');
    }
    _validateUtc(createdAtUtc);
    _validateUtc(updatedAtUtc);
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure(
        'زمان ویرایش یادآور نمی‌تواند قبل از زمان ساخت باشد.',
      );
    }
  }

  final String id;
  final String taskId;
  final TaskReminderTrigger trigger;
  final bool enabled;
  final NotificationPrivacyMode privacyMode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  String get scheduleId => 'task-$taskId-reminder-$id';

  TaskReminderRule copyWith({
    TaskReminderTrigger? trigger,
    bool? enabled,
    NotificationPrivacyMode? privacyMode,
    DateTime? updatedAtUtc,
  }) {
    return TaskReminderRule(
      id: id,
      taskId: taskId,
      trigger: trigger ?? this.trigger,
      enabled: enabled ?? this.enabled,
      privacyMode: privacyMode ?? this.privacyMode,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskReminderRule &&
            other.id == id &&
            other.taskId == taskId &&
            other.trigger == trigger &&
            other.enabled == enabled &&
            other.privacyMode == privacyMode &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    trigger,
    enabled,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  );

  @override
  String toString() {
    return 'TaskReminderRule(id: $id, taskId: $taskId, '
        'trigger: $trigger, enabled: $enabled, privacyMode: $privacyMode)';
  }
}

void _validateUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure('زمان یادآور باید به‌صورت UTC ذخیره شود.');
  }
}
