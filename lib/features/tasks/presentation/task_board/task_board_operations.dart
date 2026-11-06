import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';

final class TaskBoardMoveRequest {
  const TaskBoardMoveRequest({
    required this.taskId,
    required this.targetStatus,
    required this.targetPosition,
  });

  final String taskId;
  final TaskStatus targetStatus;

  /// Final zero-based position after the move is applied.
  final int targetPosition;
}

final class TaskBoardOperations {
  factory TaskBoardOperations({
    required TaskRepository repository,
    required DateTime Function() nowUtc,
  }) {
    return TaskBoardOperations._(repository, nowUtc);
  }

  const TaskBoardOperations._(this._repository, this._nowUtc);

  final TaskRepository _repository;
  final DateTime Function() _nowUtc;

  Future<void> move({
    required List<TaskItem> tasks,
    required TaskBoardMoveRequest request,
  }) async {
    final task = _findTask(tasks, request.taskId);
    final targetTasks = _orderedStatusTasks(tasks, request.targetStatus);

    if (task.status != request.targetStatus) {
      await _repository.transition(
        id: task.id,
        status: request.targetStatus,
        targetPosition: _clamp(request.targetPosition, targetTasks.length),
        changedAtUtc: _nowUtc().toUtc(),
      );
      return;
    }

    final orderedIds = targetTasks
        .map((item) => item.id)
        .toList(growable: true);
    final sourceIndex = orderedIds.indexOf(task.id);
    if (sourceIndex < 0) {
      throw const ValidationFailure('کار در ستون وضعیت فعلی پیدا نشد.');
    }

    orderedIds.removeAt(sourceIndex);
    final targetIndex = _clamp(request.targetPosition, orderedIds.length);
    orderedIds.insert(targetIndex, task.id);

    final unchanged = targetTasks
        .map((item) => item.id)
        .toList(growable: false);
    if (_sameOrder(orderedIds, unchanged)) {
      return;
    }

    await _repository.reorderWithinStatus(
      status: task.status,
      orderedIds: orderedIds,
    );
  }
}

TaskItem _findTask(List<TaskItem> tasks, String id) {
  TaskItem? found;
  for (final task in tasks) {
    if (task.id != id) continue;
    if (found != null) {
      throw const ValidationFailure('شناسه کار در برد تکراری است.');
    }
    found = task;
  }

  if (found == null) {
    throw const ValidationFailure('کار موردنظر در برد پیدا نشد.');
  }
  return found;
}

List<TaskItem> _orderedStatusTasks(List<TaskItem> tasks, TaskStatus status) {
  final result = tasks
      .where((task) => task.status == status)
      .toList(growable: false);
  result.sort((left, right) {
    final position = left.positionInStatus.compareTo(right.positionInStatus);
    if (position != 0) return position;
    final created = left.createdAtUtc.compareTo(right.createdAtUtc);
    if (created != 0) return created;
    return left.id.compareTo(right.id);
  });
  return result;
}

bool _sameOrder(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

int _clamp(int value, int maximum) {
  if (value < 0) return 0;
  if (value > maximum) return maximum;
  return value;
}
