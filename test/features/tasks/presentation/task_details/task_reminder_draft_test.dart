import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected reminders require a due time', () {
    final draft = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 4, 12))
      ..title = 'کار';
    final index = draft.reminders.indexWhere(
      (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
    );
    draft.reminders[index] = draft.reminders[index].copyWith(selected: true);

    expect(draft.validate()[TaskDetailsField.reminders], isNotEmpty);

    draft.dueLocal = DateTime(2026, 8, 5, 12);
    expect(draft.validate(), isEmpty);
  });

  test('buildReminderRules creates selected rules and preserves edit ids', () {
    final existing = TaskReminderRule(
      id: 'existing-rule',
      taskId: 'task-1',
      trigger: TaskReminderTrigger.oneHourBefore,
      enabled: false,
      privacyMode: NotificationPrivacyMode.private,
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 2),
    );
    final task = TaskItem(
      id: 'task-1',
      displayNumber: 1,
      title: 'کار',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 0,
      dueAtUtc: DateTime.utc(2026, 8, 5, 12),
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 2),
    );
    final draft = TaskDetailsDraft.fromTaskWithReminderRules(
      task,
      reminderRules: <TaskReminderRule>[existing],
    );
    final atDueIndex = draft.reminders.indexWhere(
      (item) => item.trigger == TaskReminderTrigger.atDue,
    );
    draft.reminders[atDueIndex] = draft.reminders[atDueIndex].copyWith(
      selected: true,
    );
    var next = 0;

    final rules = draft.buildReminderRules(
      taskId: task.id,
      savedAtUtc: DateTime.utc(2026, 8, 4),
      nextId: () => 'new-${++next}',
    );

    expect(rules, hasLength(2));
    expect(
      rules
          .singleWhere(
            (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
          )
          .id,
      'existing-rule',
    );
    expect(
      rules.singleWhere((item) => item.trigger == TaskReminderTrigger.atDue).id,
      'new-1',
    );
    expect(
      rules
          .singleWhere(
            (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
          )
          .privacyMode,
      NotificationPrivacyMode.private,
    );
    expect(
      rules
          .singleWhere(
            (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
          )
          .enabled,
      isFalse,
    );
  });
}
