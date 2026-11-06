import 'dart:async';

import 'package:borj/core/notifications/notification_coordinator.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:borj/features/tasks/application/task_reminder_projection_service.dart';
import 'package:borj/features/tasks/data/reminder_aware_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('due edits and terminal transitions reproject the owner set', () async {
    final taskRepository = _MemoryTaskRepository();
    final reminderRepository = _MemoryTaskReminderRepository();
    final scheduleRepository = _MemoryScheduleRepository();
    final scheduler = _MemoryScheduler();
    final projection = TaskReminderProjectionService(
      reminderRepository: reminderRepository,
      coordinator: NotificationCoordinator(
        repository: scheduleRepository,
        scheduler: scheduler,
      ),
      nowUtc: () => DateTime.utc(2026, 8, 4, 8),
    );
    final repository = ReminderAwareTaskRepository(
      inner: taskRepository,
      reminderRepository: reminderRepository,
      projection: () => projection,
    );
    final task = _task(dueAtUtc: DateTime.utc(2026, 8, 5, 12));

    await taskRepository.create(task);
    await reminderRepository.replaceForTask('task-1', <TaskReminderRule>[
      _rule(trigger: TaskReminderTrigger.oneHourBefore),
    ]);
    await projection.reproject(task);

    expect(
      scheduleRepository.items.single.scheduledAtUtc,
      DateTime.utc(2026, 8, 5, 11),
    );

    final edited = task.copyWith(
      dueAtUtc: DateTime.utc(2026, 8, 6, 15),
      updatedAtUtc: DateTime.utc(2026, 8, 4, 9),
    );
    await repository.update(edited);

    expect(
      scheduleRepository.items.single.scheduledAtUtc,
      DateTime.utc(2026, 8, 6, 14),
    );

    await repository.transition(
      id: task.id,
      status: TaskStatus.completed,
      targetPosition: 0,
      changedAtUtc: DateTime.utc(2026, 8, 4, 10),
    );

    expect(scheduleRepository.items, isEmpty);
    expect(scheduler.items, isEmpty);

    await repository.transition(
      id: task.id,
      status: TaskStatus.planned,
      targetPosition: 0,
      changedAtUtc: DateTime.utc(2026, 8, 4, 11),
    );

    expect(scheduleRepository.items, hasLength(1));
  });

  test('delete and deleteCompleted clear every task-owned schedule', () async {
    final taskRepository = _MemoryTaskRepository();
    final reminderRepository = _MemoryTaskReminderRepository();
    final scheduleRepository = _MemoryScheduleRepository();
    final projection = TaskReminderProjectionService(
      reminderRepository: reminderRepository,
      coordinator: NotificationCoordinator(
        repository: scheduleRepository,
        scheduler: _MemoryScheduler(),
      ),
      nowUtc: () => DateTime.utc(2026, 8, 4, 8),
    );
    final repository = ReminderAwareTaskRepository(
      inner: taskRepository,
      reminderRepository: reminderRepository,
      projection: () => projection,
    );

    final first = _task(dueAtUtc: DateTime.utc(2026, 8, 5, 12));
    final second = TaskItem(
      id: 'task-2',
      displayNumber: 2,
      title: 'کار تکمیل‌شده',
      priority: 1,
      status: TaskStatus.completed,
      positionInStatus: 0,
      dueAtUtc: DateTime.utc(2026, 8, 5, 13),
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 4),
      completedAtUtc: DateTime.utc(2026, 8, 4),
    );
    await taskRepository.create(first);
    await taskRepository.create(second);
    await reminderRepository.replaceForTask('task-1', <TaskReminderRule>[
      _rule(trigger: TaskReminderTrigger.atDue),
    ]);
    await reminderRepository.replaceForTask('task-2', <TaskReminderRule>[
      _rule(id: 'rule-2', taskId: 'task-2', trigger: TaskReminderTrigger.atDue),
    ]);
    await projection.reproject(first);

    await repository.delete(first.id);
    expect(scheduleRepository.items, isEmpty);

    await repository.deleteCompleted();
    expect(await taskRepository.getById(second.id), isNull);
  });
}

TaskItem _task({required DateTime? dueAtUtc}) {
  return TaskItem(
    id: 'task-1',
    displayNumber: 1,
    title: 'کار',
    priority: 1,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: dueAtUtc,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}

TaskReminderRule _rule({
  String id = 'rule-1',
  String taskId = 'task-1',
  required TaskReminderTrigger trigger,
}) {
  return TaskReminderRule(
    id: id,
    taskId: taskId,
    trigger: trigger,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}

final class _MemoryTaskRepository implements TaskRepository {
  final List<TaskItem> _items = <TaskItem>[];

  @override
  Stream<List<TaskItem>> watchAll() =>
      Stream.value(List<TaskItem>.from(_items));

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    return Stream.value(
      _items.where((item) => item.status == status).toList(growable: false),
    );
  }

  @override
  Future<TaskItem?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> create(TaskItem task) async {
    _items.add(task);
  }

  @override
  Future<void> update(TaskItem task) async {
    final index = _items.indexWhere((item) => item.id == task.id);
    _items[index] = task;
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    final current = (await getById(id))!;
    final next = switch (status) {
      TaskStatus.completed => current.copyWith(
        status: status,
        positionInStatus: targetPosition,
        updatedAtUtc: changedAtUtc,
        completedAtUtc: changedAtUtc,
        clearCanceledAt: true,
      ),
      TaskStatus.canceled => current.copyWith(
        status: status,
        positionInStatus: targetPosition,
        updatedAtUtc: changedAtUtc,
        canceledAtUtc: changedAtUtc,
        clearCompletedAt: true,
      ),
      TaskStatus.planned || TaskStatus.inProgress => current.copyWith(
        status: status,
        positionInStatus: targetPosition,
        updatedAtUtc: changedAtUtc,
        clearCompletedAt: true,
        clearCanceledAt: true,
      ),
    };
    await update(next);
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) async {}

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteCompleted() async {
    _items.removeWhere((item) => item.status == TaskStatus.completed);
  }
}

final class _MemoryTaskReminderRepository implements TaskReminderRepository {
  final Map<String, List<TaskReminderRule>> _items =
      <String, List<TaskReminderRule>>{};

  @override
  Stream<List<TaskReminderRule>> watchByTask(String taskId) {
    return Stream.value(
      List<TaskReminderRule>.from(_items[taskId] ?? const []),
    );
  }

  @override
  Future<List<TaskReminderRule>> getByTask(String taskId) async {
    return List<TaskReminderRule>.from(_items[taskId] ?? const []);
  }

  @override
  Future<void> replaceForTask(
    String taskId,
    List<TaskReminderRule> expected,
  ) async {
    _items[taskId] = List<TaskReminderRule>.from(expected);
  }

  @override
  Future<void> deleteByTask(String taskId) async {
    _items.remove(taskId);
  }
}

final class _MemoryScheduleRepository
    implements NotificationScheduleRepository {
  List<NotificationRequest> items = <NotificationRequest>[];

  @override
  Stream<List<NotificationRequest>> watchAll() => Stream.value(items);

  @override
  Future<List<NotificationRequest>> getAll() async => List.of(items);

  @override
  Future<NotificationRequest?> getById(String scheduleId) async {
    for (final item in items) {
      if (item.scheduleId == scheduleId) return item;
    }
    return null;
  }

  @override
  Future<void> upsert(NotificationRequest request) async {
    items.removeWhere((item) => item.scheduleId == request.scheduleId);
    items.add(request);
  }

  @override
  Future<void> delete(String scheduleId) async {
    items.removeWhere((item) => item.scheduleId == scheduleId);
  }

  @override
  Future<void> deleteByOwner(NotificationOwner owner) async {
    items.removeWhere((item) => item.owner == owner);
  }

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) async {
    items = List.of(expected);
  }
}

final class _MemoryScheduler implements NotificationScheduler {
  List<NotificationRequest> items = <NotificationRequest>[];

  @override
  Future<void> schedule(NotificationRequest request) async {
    items.removeWhere((item) => item.scheduleId == request.scheduleId);
    items.add(request);
  }

  @override
  Future<void> cancel(String scheduleId) async {
    items.removeWhere((item) => item.scheduleId == scheduleId);
  }

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {
    items.removeWhere((item) => item.owner == owner);
  }

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {
    items = List.of(expected);
  }
}
