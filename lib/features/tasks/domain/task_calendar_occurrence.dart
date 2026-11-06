import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/tasks/domain/task_item.dart';

enum TaskCalendarOccurrenceStatus {
  scheduled,
  moved,
  completed,
  skipped,
  canceled,
}

final class TaskCalendarOccurrence {
  const TaskCalendarOccurrence({
    required this.task,
    required this.originalLocalDateTime,
    required this.effectiveLocalDateTime,
    required this.instantUtc,
    required this.timeZoneId,
    required this.calendar,
    required this.sequence,
    required this.status,
    required this.recurring,
  });

  final TaskItem task;
  final RecurrenceLocalDateTime originalLocalDateTime;
  final RecurrenceLocalDateTime effectiveLocalDateTime;
  final DateTime instantUtc;
  final String timeZoneId;
  final RecurrenceCalendar calendar;
  final int sequence;
  final TaskCalendarOccurrenceStatus status;
  final bool recurring;

  String get occurrenceKey => '${task.id}@${originalLocalDateTime.storageKey}';

  bool get isCompleted => status == TaskCalendarOccurrenceStatus.completed;

  bool get isActionable =>
      status == TaskCalendarOccurrenceStatus.scheduled ||
      status == TaskCalendarOccurrenceStatus.moved ||
      status == TaskCalendarOccurrenceStatus.completed;
}
