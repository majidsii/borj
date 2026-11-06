import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';

final class TaskReminderProjector {
  const TaskReminderProjector();

  List<NotificationRequest> project({
    required TaskItem task,
    required List<TaskReminderRule> rules,
    required DateTime nowUtc,
  }) {
    final dueAtUtc = task.dueAtUtc;
    if (!task.isActive || dueAtUtc == null) {
      return const <NotificationRequest>[];
    }

    return _projectForDue(
      task: task,
      rules: rules,
      dueAtUtc: dueAtUtc,
      nowUtc: nowUtc,
      scheduleScope: null,
      payloadExtra: const <String, String>{},
    );
  }

  List<NotificationRequest> projectForOccurrences({
    required TaskItem task,
    required List<TaskReminderRule> rules,
    required List<TaskCalendarOccurrence> occurrences,
    required DateTime nowUtc,
  }) {
    _requireUtc(nowUtc);
    if (!task.isActive) return const <NotificationRequest>[];

    final output = <NotificationRequest>[];
    for (final occurrence in occurrences) {
      if (occurrence.task.id != task.id ||
          !occurrence.recurring ||
          (occurrence.status != TaskCalendarOccurrenceStatus.scheduled &&
              occurrence.status != TaskCalendarOccurrenceStatus.moved)) {
        continue;
      }
      final localKey = occurrence.originalLocalDateTime.storageKey;
      final scheduleScope = localKey.replaceAll(RegExp('[^0-9]'), '');
      output.addAll(
        _projectForDue(
          task: task,
          rules: rules,
          dueAtUtc: occurrence.instantUtc,
          nowUtc: nowUtc,
          scheduleScope: scheduleScope,
          payloadExtra: <String, String>{
            'occurrenceKey': occurrence.occurrenceKey,
            'originalLocalDateTime': localKey,
          },
        ),
      );
    }

    output.sort(_compareRequest);
    return List<NotificationRequest>.unmodifiable(output);
  }

  List<NotificationRequest> _projectForDue({
    required TaskItem task,
    required List<TaskReminderRule> rules,
    required DateTime dueAtUtc,
    required DateTime nowUtc,
    required String? scheduleScope,
    required Map<String, String> payloadExtra,
  }) {
    _requireUtc(nowUtc);
    _requireUtc(dueAtUtc);

    final requests = <NotificationRequest>[];
    final seenTriggers = <Object>{};

    for (final rule in rules) {
      if (rule.taskId != task.id) {
        throw ArgumentError.value(
          rule.taskId,
          'rules',
          'Reminder rule does not belong to task ${task.id}.',
        );
      }
      if (!seenTriggers.add(rule.trigger)) {
        throw ArgumentError.value(
          rules,
          'rules',
          'Duplicate task reminder triggers are not allowed.',
        );
      }
      if (!rule.enabled) continue;

      final scheduledAtUtc = rule.trigger.scheduledAtUtc(dueAtUtc);
      if (!scheduledAtUtc.isAfter(nowUtc)) continue;

      final scheduleId = scheduleScope == null
          ? rule.scheduleId
          : 'task-${task.id}-occurrence-$scheduleScope-'
                'reminder-${rule.id}';

      requests.add(
        NotificationRequest(
          scheduleId: scheduleId,
          owner: NotificationOwner(
            type: NotificationOwnerType.task,
            id: task.id,
          ),
          title: 'یادآور کار: ${task.title}',
          body: _bodyFor(task, rule),
          scheduledAtUtc: scheduledAtUtc,
          payload: <String, String>{
            'route': '/tasks/${task.id}',
            'taskId': task.id,
            'reminderRuleId': rule.id,
            'trigger': rule.trigger.storageValue,
            ...payloadExtra,
          },
          privacyMode: rule.privacyMode,
        ),
      );
    }

    requests.sort(_compareRequest);
    return List<NotificationRequest>.unmodifiable(requests);
  }
}

int _compareRequest(NotificationRequest left, NotificationRequest right) {
  final time = left.scheduledAtUtc.compareTo(right.scheduledAtUtc);
  if (time != 0) return time;
  return left.scheduleId.compareTo(right.scheduleId);
}

void _requireUtc(DateTime value) {
  if (!value.isUtc) {
    throw ArgumentError.value(
      value,
      'value',
      'Reminder projection requires UTC.',
    );
  }
}

String _bodyFor(TaskItem task, TaskReminderRule rule) {
  return switch (rule.trigger.offsetMinutes) {
    0 => 'زمان انجام «${task.title}» رسیده است.',
    final minutes when minutes < 60 =>
      'تا سررسید «${task.title}»، $minutes دقیقه باقی مانده است.',
    final minutes when minutes % 1440 == 0 =>
      'تا سررسید «${task.title}»، ${minutes ~/ 1440} روز باقی مانده است.',
    final minutes =>
      'تا سررسید «${task.title}»، ${minutes ~/ 60} ساعت باقی مانده است.',
  };
}
