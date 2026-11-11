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

/// Ids deleted in the UI whose database delete has not been committed yet
/// (the undo window). Hidden from every task list.
final class PendingTaskDeletions extends StateNotifier<Set<String>> {
  PendingTaskDeletions() : super(const <String>{});

  void add(Iterable<String> ids) => state = {...state, ...ids};

  void remove(Iterable<String> ids) {
    final next = {...state}..removeAll(ids);
    state = next;
  }
}

final pendingTaskDeletionsProvider =
    StateNotifierProvider<PendingTaskDeletions, Set<String>>(
      (ref) => PendingTaskDeletions(),
    );

/// [taskItemsProvider] minus the tasks pending deletion.
final visibleTaskItemsProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final tasks = ref.watch(taskItemsProvider);
  final pending = ref.watch(pendingTaskDeletionsProvider);
  if (pending.isEmpty) return tasks;
  return tasks.whenData(
    (list) => list.where((t) => !pending.contains(t.id)).toList(),
  );
});

/// A delete that is hidden but not yet applied. Call exactly one of [undo]
/// or [commit]; whichever comes first wins and later calls do nothing.
final class PendingDeletion {
  PendingDeletion._(this.tasks, this._pending, this._repository);

  /// The tasks hidden by this deletion (as stored).
  final List<TaskItem> tasks;
  final PendingTaskDeletions _pending;
  final TaskRepository _repository;
  bool _settled = false;

  Iterable<String> get _ids => tasks.map((t) => t.id);

  void undo() {
    if (_settled) return;
    _settled = true;
    _pending.remove(_ids);
  }

  Future<void> commit() async {
    if (_settled) return;
    _settled = true;
    try {
      for (final id in _ids) {
        await _repository.delete(id);
      }
    } finally {
      _pending.remove(_ids);
    }
  }
}

/// The Tasks list, rebuilt on every data change, filter/sort/query change and
/// minute tick (the day boundary decides overdue/today/upcoming).
final taskListViewProvider = Provider<AsyncValue<TaskListView>>((ref) {
  final tasks = ref.watch(visibleTaskItemsProvider);
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
    required PendingTaskDeletions pending,
    required AppClock clock,
    IdGenerator idGenerator = const UuidV7IdGenerator(),
  }) {
    return TaskActions._(repository, clock, idGenerator, pending);
  }

  const TaskActions._(this._repository, this._clock, this._ids, this._pending);

  final TaskRepository _repository;
  final AppClock _clock;
  final IdGenerator _ids;
  final PendingTaskDeletions _pending;

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

  /// Hides the task now; the database delete happens on
  /// [PendingDeletion.commit]. Null when the task does not exist.
  Future<PendingDeletion?> delete(String id) async {
    final task = await _repository.getById(id);
    if (task == null) return null;
    _pending.add([id]);
    return PendingDeletion._([task], _pending, _repository);
  }

  /// Hides every completed task now; commit deletes exactly those tasks.
  Future<PendingDeletion> deleteCompleted() async {
    final completed =
        (await _repository.watchByStatus(TaskStatus.completed).first).toList()
          ..sort((a, b) => a.positionInStatus.compareTo(b.positionInStatus));
    _pending.add(completed.map((t) => t.id));
    return PendingDeletion._(completed, _pending, _repository);
  }

  /// Moves a task. Throws the repository's failure when the move is invalid
  /// (for example an unknown task id); callers decide how to surface it.
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
    pending: ref.read(pendingTaskDeletionsProvider.notifier),
  );
});
