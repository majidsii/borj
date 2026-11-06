import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/application/task_reminder_projector.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projector = TaskReminderProjector();
  final nowUtc = DateTime.utc(2026, 8, 4, 8);
  final dueAtUtc = DateTime.utc(2026, 8, 5, 12);

  test('projects enabled future rules with stable identity and payload', () {
    final requests = projector.project(
      task: _task(dueAtUtc: dueAtUtc),
      rules: <TaskReminderRule>[
        _rule(id: 'hour', trigger: TaskReminderTrigger.oneHourBefore),
        _rule(
          id: 'due',
          trigger: TaskReminderTrigger.atDue,
          privacyMode: NotificationPrivacyMode.private,
        ),
      ],
      nowUtc: nowUtc,
    );

    expect(requests, hasLength(2));
    expect(requests.map((item) => item.scheduleId), const <String>[
      'task-task-1-reminder-hour',
      'task-task-1-reminder-due',
    ]);
    expect(requests.first.scheduledAtUtc, DateTime.utc(2026, 8, 5, 11));
    expect(
      requests.first.owner,
      NotificationOwner(type: NotificationOwnerType.task, id: 'task-1'),
    );
    expect(requests.first.payload['route'], '/tasks/task-1');
    expect(requests.first.payload['reminderRuleId'], 'hour');
    expect(requests.last.privacyMode, NotificationPrivacyMode.private);
  });

  test('inactive missing-due disabled and past rules produce no schedule', () {
    expect(
      projector.project(
        task: _task(dueAtUtc: null),
        rules: <TaskReminderRule>[
          _rule(id: 'due', trigger: TaskReminderTrigger.atDue),
        ],
        nowUtc: nowUtc,
      ),
      isEmpty,
    );
    expect(
      projector.project(
        task: _task(
          dueAtUtc: dueAtUtc,
          status: TaskStatus.completed,
          completedAtUtc: nowUtc,
        ),
        rules: <TaskReminderRule>[
          _rule(id: 'due', trigger: TaskReminderTrigger.atDue),
        ],
        nowUtc: nowUtc,
      ),
      isEmpty,
    );
    expect(
      projector.project(
        task: _task(dueAtUtc: dueAtUtc),
        rules: <TaskReminderRule>[
          _rule(
            id: 'disabled',
            trigger: TaskReminderTrigger.atDue,
            enabled: false,
          ),
        ],
        nowUtc: nowUtc,
      ),
      isEmpty,
    );
    expect(
      projector.project(
        task: _task(dueAtUtc: DateTime.utc(2026, 8, 4, 8)),
        rules: <TaskReminderRule>[
          _rule(id: 'due', trigger: TaskReminderTrigger.atDue),
        ],
        nowUtc: nowUtc,
      ),
      isEmpty,
    );
  });

  test('rejects a rule owned by another task and duplicate triggers', () {
    expect(
      () => projector.project(
        task: _task(dueAtUtc: dueAtUtc),
        rules: <TaskReminderRule>[
          _rule(
            id: 'other',
            taskId: 'task-2',
            trigger: TaskReminderTrigger.atDue,
          ),
        ],
        nowUtc: nowUtc,
      ),
      throwsArgumentError,
    );

    expect(
      () => projector.project(
        task: _task(dueAtUtc: dueAtUtc),
        rules: <TaskReminderRule>[
          _rule(id: 'one', trigger: TaskReminderTrigger.atDue),
          _rule(id: 'two', trigger: TaskReminderTrigger.atDue),
        ],
        nowUtc: nowUtc,
      ),
      throwsArgumentError,
    );
  });
}

TaskItem _task({
  required DateTime? dueAtUtc,
  TaskStatus status = TaskStatus.planned,
  DateTime? completedAtUtc,
}) {
  return TaskItem(
    id: 'task-1',
    displayNumber: 1,
    title: 'ارسال گزارش',
    priority: 2,
    status: status,
    positionInStatus: 0,
    dueAtUtc: dueAtUtc,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
    completedAtUtc: completedAtUtc,
  );
}

TaskReminderRule _rule({
  required String id,
  String taskId = 'task-1',
  required TaskReminderTrigger trigger,
  bool enabled = true,
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
}) {
  return TaskReminderRule(
    id: id,
    taskId: taskId,
    trigger: trigger,
    enabled: enabled,
    privacyMode: privacyMode,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}
