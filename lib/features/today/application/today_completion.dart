import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/features/tasks/application/task_recurrence_service.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/domain/today_entry.dart';

/// Completes or reopens a Today entry: one-off tasks change status;
/// recurring occurrences record or clear their completion.
final class TodayCompletion {
  TodayCompletion({
    required this.repository,
    required this.recurrence,
    required this.clock,
  });

  final TaskRepository repository;
  final TaskRecurrenceService recurrence;
  final AppClock clock;

  Future<void> toggle(TodayEntry entry) {
    if (entry.recurring) {
      return recurrence.setCompleted(
        taskId: entry.taskId,
        originalLocalDateTime: entry.originalLocalDateTime!,
        completed: !entry.done,
      );
    }
    return repository.transition(
      id: entry.taskId,
      status: entry.done ? TaskStatus.planned : TaskStatus.completed,
      targetPosition: 0,
      changedAtUtc: clock.nowUtc(),
    );
  }
}
