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
