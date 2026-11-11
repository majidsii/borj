import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_board/task_board_operations.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as timezone;

final tasksFilterProvider = StateProvider<TaskSmartFilter>(
  (ref) => TaskSmartFilter.all,
);

final tasksSortProvider = StateProvider<TaskSort>((ref) => TaskSort.time);

final tasksQueryProvider = StateProvider<String>((ref) => '');

/// The Tasks list, rebuilt on every data change, filter/sort/query change and
/// minute tick (the day boundary decides overdue/today/upcoming).
final taskListViewProvider = Provider<AsyncValue<TaskListView>>((ref) {
  final tasks = ref.watch(taskItemsProvider);
  final zone = ref.watch(taskCalendarTimeZoneProvider);
  final tick = ref.watch(minuteTickProvider);
  final filter = ref.watch(tasksFilterProvider);
  final sort = ref.watch(tasksSortProvider);
  final query = ref.watch(tasksQueryProvider);
  final inputs = <AsyncValue<Object?>>[tasks, zone, tick];
  for (final v in inputs) {
    if (v.hasError) {
      return AsyncValue.error(v.error!, v.stackTrace ?? StackTrace.current);
    }
  }
  if (!tasks.hasValue || !zone.hasValue || !tick.hasValue) {
    return const AsyncValue.loading();
  }
  try {
    return AsyncValue.data(
      buildTaskListView(
        tasks: tasks.requireValue,
        nowUtc: tick.requireValue,
        timeZoneId: zone.requireValue,
        filter: filter,
        sort: sort,
        query: query,
      ),
    );
  } on timezone.LocationNotFoundException catch (error, stack) {
    return AsyncValue.error(error, stack);
  }
});

/// Mutations used by the Tasks screens. Mirrors the legacy panel's behaviour
/// (create at planned/0, toggle = completed/planned at 0, priority cycles
/// 0..3) with times taken from [AppClock].
final class TaskActions {
  factory TaskActions({
    required TaskRepository repository,
    required AppClock clock,
    IdGenerator idGenerator = const UuidV7IdGenerator(),
  }) {
    return TaskActions._(repository, clock, idGenerator);
  }

  const TaskActions._(this._repository, this._clock, this._ids);

  final TaskRepository _repository;
  final AppClock _clock;
  final IdGenerator _ids;

  Future<void> create({
    required String title,
    required int priority,
    DateTime? dueAtUtc,
  }) async {
    await createAndReturnId(
      title: title,
      priority: priority,
      dueAtUtc: dueAtUtc,
    );
  }

  Future<String> createAndReturnId({
    required String title,
    required int priority,
    DateTime? dueAtUtc,
  }) async {
    final now = _clock.nowUtc().toUtc();
    final id = _ids.next();
    // The repository assigns the real displayNumber and position.
    await _repository.create(
      TaskItem(
        id: id,
        displayNumber: 1,
        title: title,
        priority: priority,
        status: TaskStatus.planned,
        positionInStatus: 0,
        dueAtUtc: dueAtUtc?.toUtc(),
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await _repository.transition(
      id: id,
      status: TaskStatus.planned,
      targetPosition: 0,
      changedAtUtc: now,
    );
    return id;
  }

  Future<void> toggleDone(TaskItem t) {
    return setStatus(
      t,
      t.status == TaskStatus.completed
          ? TaskStatus.planned
          : TaskStatus.completed,
    );
  }

  Future<void> setStatus(TaskItem t, TaskStatus s) {
    return _repository.transition(
      id: t.id,
      status: s,
      targetPosition: 0,
      changedAtUtc: _clock.nowUtc().toUtc(),
    );
  }

  Future<void> cyclePriority(TaskItem t) {
    return _repository.update(
      t.copyWith(
        priority: (t.priority + 1) % 4,
        updatedAtUtc: _clock.nowUtc().toUtc(),
      ),
    );
  }

  /// Deletes the task and returns it (as stored) so the caller can offer undo.
  Future<TaskItem?> delete(String id) async {
    final task = await _repository.getById(id);
    if (task == null) return null;
    await _repository.delete(id);
    return task;
  }

  /// Undo of [delete] / [deleteCompleted]: same id, fields, display number and
  /// position.
  Future<void> restore(TaskItem t) async {
    final repository = _repository;
    if (repository is TaskRestorer) {
      await (repository as TaskRestorer).restore(t);
      return;
    }
    await _repository.create(t);
    await _repository.transition(
      id: t.id,
      status: t.status,
      targetPosition: t.positionInStatus,
      changedAtUtc: _clock.nowUtc().toUtc(),
    );
  }

  Future<List<TaskItem>> deleteCompleted() async {
    final completed =
        (await _repository.watchByStatus(TaskStatus.completed).first).toList()
          ..sort((a, b) => a.positionInStatus.compareTo(b.positionInStatus));
    if (completed.isEmpty) return const <TaskItem>[];
    await _repository.deleteCompleted();
    return completed;
  }

  Future<void> move(
    String taskId,
    TaskStatus status,
    int targetPosition,
  ) async {
    final tasks = await _repository.watchAll().first;
    await TaskBoardOperations(
      repository: _repository,
      nowUtc: _clock.nowUtc,
    ).move(
      tasks: tasks,
      request: TaskBoardMoveRequest(
        taskId: taskId,
        targetStatus: status,
        targetPosition: targetPosition,
      ),
    );
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
});
