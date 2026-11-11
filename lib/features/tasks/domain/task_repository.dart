import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchAll();

  Stream<List<TaskItem>> watchByStatus(TaskStatus status);

  Future<TaskItem?> getById(String id);

  Future<void> create(TaskItem task);

  Future<void> update(TaskItem task);

  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  });

  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  });

  Future<void> delete(String id);

  Future<void> deleteCompleted();
}

/// Re-inserts a previously deleted task with its original `displayNumber`,
/// timestamps and fields, at [TaskItem.positionInStatus] (clamped) in its
/// status. Used by undo. If the display number is taken, the next free one is
/// allocated instead (display numbers are never reused).
abstract interface class TaskRestorer {
  Future<void> restore(TaskItem task);
}
