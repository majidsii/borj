import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_board/task_board_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingTaskRepository repository;
  late DateTime changedAtUtc;
  late TaskBoardOperations operations;

  setUp(() {
    repository = _RecordingTaskRepository();
    changedAtUtc = DateTime.utc(2026, 8, 4, 12);
    operations = TaskBoardOperations(
      repository: repository,
      nowUtc: () => changedAtUtc,
    );
  });

  test('same-status move writes one complete canonical order', () async {
    final tasks = <TaskItem>[
      _task(id: 'a', position: 0),
      _task(id: 'b', position: 1),
      _task(id: 'c', position: 2),
    ];

    await operations.move(
      tasks: tasks,
      request: const TaskBoardMoveRequest(
        taskId: 'c',
        targetStatus: TaskStatus.planned,
        targetPosition: 0,
      ),
    );

    expect(repository.reorders, hasLength(1));
    expect(repository.reorders.single.status, TaskStatus.planned);
    expect(repository.reorders.single.orderedIds, <String>['c', 'a', 'b']);
    expect(repository.transitions, isEmpty);
  });

  test('same-status no-op does not write to repository', () async {
    final tasks = <TaskItem>[
      _task(id: 'a', position: 0),
      _task(id: 'b', position: 1),
    ];

    await operations.move(
      tasks: tasks,
      request: const TaskBoardMoveRequest(
        taskId: 'b',
        targetStatus: TaskStatus.planned,
        targetPosition: 1,
      ),
    );

    expect(repository.reorders, isEmpty);
    expect(repository.transitions, isEmpty);
  });

  test('cross-status move delegates one atomic transition', () async {
    final tasks = <TaskItem>[
      _task(id: 'planned', position: 0),
      _task(id: 'working', status: TaskStatus.inProgress, position: 0),
    ];

    await operations.move(
      tasks: tasks,
      request: const TaskBoardMoveRequest(
        taskId: 'planned',
        targetStatus: TaskStatus.inProgress,
        targetPosition: 99,
      ),
    );

    expect(repository.transitions, hasLength(1));
    final transition = repository.transitions.single;
    expect(transition.id, 'planned');
    expect(transition.status, TaskStatus.inProgress);
    expect(transition.targetPosition, 1);
    expect(transition.changedAtUtc, changedAtUtc);
    expect(repository.reorders, isEmpty);
  });

  test('negative positions clamp to the beginning', () async {
    final tasks = <TaskItem>[
      _task(id: 'a', position: 0),
      _task(id: 'b', position: 1),
    ];

    await operations.move(
      tasks: tasks,
      request: const TaskBoardMoveRequest(
        taskId: 'b',
        targetStatus: TaskStatus.planned,
        targetPosition: -10,
      ),
    );

    expect(repository.reorders.single.orderedIds, <String>['b', 'a']);
  });

  test('missing and duplicate board identities fail without writes', () async {
    final base = _task(id: 'duplicate', position: 0);

    await expectLater(
      operations.move(
        tasks: <TaskItem>[base],
        request: const TaskBoardMoveRequest(
          taskId: 'missing',
          targetStatus: TaskStatus.planned,
          targetPosition: 0,
        ),
      ),
      throwsA(isA<ValidationFailure>()),
    );

    await expectLater(
      operations.move(
        tasks: <TaskItem>[
          base,
          _task(id: 'duplicate', position: 1),
        ],
        request: const TaskBoardMoveRequest(
          taskId: 'duplicate',
          targetStatus: TaskStatus.planned,
          targetPosition: 0,
        ),
      ),
      throwsA(isA<ValidationFailure>()),
    );

    expect(repository.reorders, isEmpty);
    expect(repository.transitions, isEmpty);
  });
}

TaskItem _task({
  required String id,
  TaskStatus status = TaskStatus.planned,
  required int position,
}) {
  final now = DateTime.utc(2026, 8, 4, 9).add(Duration(minutes: position));
  return TaskItem(
    id: id,
    displayNumber: position + 1,
    title: id,
    priority: 1,
    status: status,
    positionInStatus: position,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}

final class _RecordingTaskRepository implements TaskRepository {
  final List<_TransitionCall> transitions = <_TransitionCall>[];
  final List<_ReorderCall> reorders = <_ReorderCall>[];

  @override
  Stream<List<TaskItem>> watchAll() => Stream<List<TaskItem>>.empty();

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) =>
      Stream<List<TaskItem>>.empty();

  @override
  Future<TaskItem?> getById(String id) async => null;

  @override
  Future<void> create(TaskItem task) async {}

  @override
  Future<void> update(TaskItem task) async {}

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    transitions.add(
      _TransitionCall(
        id: id,
        status: status,
        targetPosition: targetPosition,
        changedAtUtc: changedAtUtc,
      ),
    );
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) async {
    reorders.add(
      _ReorderCall(
        status: status,
        orderedIds: List<String>.unmodifiable(orderedIds),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteCompleted() async {}
}

final class _TransitionCall {
  const _TransitionCall({
    required this.id,
    required this.status,
    required this.targetPosition,
    required this.changedAtUtc,
  });

  final String id;
  final TaskStatus status;
  final int targetPosition;
  final DateTime changedAtUtc;
}

final class _ReorderCall {
  const _ReorderCall({required this.status, required this.orderedIds});

  final TaskStatus status;
  final List<String> orderedIds;
}
