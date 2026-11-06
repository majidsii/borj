import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/data/drift_task_reminder_repository.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late DriftTaskReminderRepository repository;

  setUp(() async {
    database = openTestDatabase();
    taskRepository = DriftTaskRepository(database);
    repository = DriftTaskReminderRepository(database);
    await taskRepository.create(_task());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'replaceForTask round-trips ordered rules and preserves identity',
    () async {
      final first = _rule(
        id: 'rule-hour',
        trigger: TaskReminderTrigger.oneHourBefore,
        privacyMode: NotificationPrivacyMode.private,
      );
      final second = _rule(id: 'rule-due', trigger: TaskReminderTrigger.atDue);

      await repository.replaceForTask('task-1', <TaskReminderRule>[
        first,
        second,
      ]);

      final stored = await repository.getByTask('task-1');
      expect(stored, hasLength(2));
      expect(stored.map((item) => item.trigger).toSet(), <TaskReminderTrigger>{
        TaskReminderTrigger.atDue,
        TaskReminderTrigger.oneHourBefore,
      });
      expect(
        stored
            .singleWhere(
              (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
            )
            .privacyMode,
        NotificationPrivacyMode.private,
      );

      final updatedDue = second.copyWith(
        privacyMode: NotificationPrivacyMode.private,
        updatedAtUtc: DateTime.utc(2026, 8, 5),
      );
      await repository.replaceForTask('task-1', <TaskReminderRule>[updatedDue]);

      final replaced = await repository.getByTask('task-1');
      expect(replaced, <TaskReminderRule>[updatedDue]);
    },
  );

  test('watchByTask emits replacement and deleteByTask clears it', () async {
    final emissions = <List<TaskReminderRule>>[];
    final subscription = repository.watchByTask('task-1').listen(emissions.add);

    await repository.replaceForTask('task-1', <TaskReminderRule>[
      _rule(id: 'rule-due', trigger: TaskReminderTrigger.atDue),
    ]);
    await Future<void>.delayed(Duration.zero);
    await repository.deleteByTask('task-1');
    await Future<void>.delayed(Duration.zero);

    expect(emissions.any((items) => items.length == 1), isTrue);
    expect(emissions.last, isEmpty);
    await subscription.cancel();
  });

  test('task deletion cascades reminder rules', () async {
    await repository.replaceForTask('task-1', <TaskReminderRule>[
      _rule(id: 'rule-due', trigger: TaskReminderTrigger.atDue),
    ]);

    await taskRepository.delete('task-1');

    expect(await repository.getByTask('task-1'), isEmpty);
  });

  test('rejects rules from another task and duplicate triggers', () async {
    expect(
      () => repository.replaceForTask('task-1', <TaskReminderRule>[
        _rule(
          id: 'other',
          taskId: 'task-2',
          trigger: TaskReminderTrigger.atDue,
        ),
      ]),
      throwsArgumentError,
    );

    expect(
      () => repository.replaceForTask('task-1', <TaskReminderRule>[
        _rule(id: 'one', trigger: TaskReminderTrigger.atDue),
        _rule(id: 'two', trigger: TaskReminderTrigger.atDue),
      ]),
      throwsArgumentError,
    );
  });
}

TaskItem _task() {
  return TaskItem(
    id: 'task-1',
    displayNumber: 1,
    title: 'کار',
    priority: 1,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: DateTime.utc(2026, 8, 7, 12),
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}

TaskReminderRule _rule({
  required String id,
  String taskId = 'task-1',
  required TaskReminderTrigger trigger,
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
}) {
  return TaskReminderRule(
    id: id,
    taskId: taskId,
    trigger: trigger,
    privacyMode: privacyMode,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}
