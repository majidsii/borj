import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/features/tasks/application/task_recurrence_service.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/domain/today_entry.dart';

/// Completes or reopens a Today entry: one-off tasks change status;
/// recurring occurrences record or clear their completion.
final class TodayCompletion {
  TodayCompletion({
    required this._repository,
    required this._recurrence,
    required this._clock,
  });

  final TaskRepository _repository;
  final TaskRecurrenceService _recurrence;
  final AppClock _clock;

  Future<void> toggle(TodayEntry entry) {
    if (entry.recurring) {
      return _recurrence.setCompleted(
        taskId: entry.taskId,
        originalLocalDateTime: entry.originalLocalDateTime!,
        completed: !entry.done,
      );
    }
    return _repository.transition(
      id: entry.taskId,
      status: entry.done ? TaskStatus.planned : TaskStatus.completed,
      targetPosition: 0,
      changedAtUtc: _clock.nowUtc(),
    );
  }
}
