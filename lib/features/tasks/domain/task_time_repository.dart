import 'package:borj/features/tasks/domain/task_time_entry.dart';

abstract interface class TaskTimeRepository {
  Stream<List<TaskTimeEntry>> watchAll();

  Stream<List<TaskTimeEntry>> watchByTask(String taskId);

  Stream<TaskTimeEntry?> watchActive();

  Future<List<TaskTimeEntry>> getByTask(String taskId);

  Future<TaskTimeEntry?> getById(String id);

  Future<TaskTimeEntry?> getActive();

  Future<void> insert(TaskTimeEntry entry);

  Future<void> update(TaskTimeEntry entry);

  Future<void> delete(String id);
}
