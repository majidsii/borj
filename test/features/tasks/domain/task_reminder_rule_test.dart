import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task reminder trigger keeps stable storage and UTC offsets', () {
    final dueAtUtc = DateTime.utc(2026, 8, 5, 12);

    expect(TaskReminderTrigger.atDue.scheduledAtUtc(dueAtUtc), dueAtUtc);
    expect(
      TaskReminderTrigger.fifteenMinutesBefore.scheduledAtUtc(dueAtUtc),
      DateTime.utc(2026, 8, 5, 11, 45),
    );
    expect(
      TaskReminderTrigger.oneHourBefore.scheduledAtUtc(dueAtUtc),
      DateTime.utc(2026, 8, 5, 11),
    );
    expect(
      TaskReminderTrigger.oneDayBefore.scheduledAtUtc(dueAtUtc),
      DateTime.utc(2026, 8, 4, 12),
    );

    for (final trigger in TaskReminderTrigger.values) {
      expect(TaskReminderTrigger.parseStorage(trigger.storageValue), trigger);
    }
  });

  test('task reminder rule validates identity UTC and timestamps', () {
    final rule = TaskReminderRule(
      id: ' rule-1 ',
      taskId: ' task-1 ',
      trigger: TaskReminderTrigger.oneHourBefore,
      privacyMode: NotificationPrivacyMode.private,
      createdAtUtc: DateTime.utc(2026, 8, 4, 8),
      updatedAtUtc: DateTime.utc(2026, 8, 4, 9),
    );

    expect(rule.id, 'rule-1');
    expect(rule.taskId, 'task-1');
    expect(rule.scheduleId, 'task-task-1-reminder-rule-1');
    expect(rule.privacyMode, NotificationPrivacyMode.private);

    expect(
      () => TaskReminderRule(
        id: '',
        taskId: 'task-1',
        trigger: TaskReminderTrigger.atDue,
        createdAtUtc: DateTime.utc(2026, 8, 4),
        updatedAtUtc: DateTime.utc(2026, 8, 4),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => TaskReminderRule(
        id: 'rule',
        taskId: 'task',
        trigger: TaskReminderTrigger.atDue,
        createdAtUtc: DateTime(2026, 8, 4),
        updatedAtUtc: DateTime.utc(2026, 8, 4),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => TaskReminderRule(
        id: 'rule',
        taskId: 'task',
        trigger: TaskReminderTrigger.atDue,
        createdAtUtc: DateTime.utc(2026, 8, 4, 10),
        updatedAtUtc: DateTime.utc(2026, 8, 4, 9),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
