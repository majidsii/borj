import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_engine.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_occurrence.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:timezone/timezone.dart' as timezone;

final class TaskOccurrenceProjector {
  const TaskOccurrenceProjector({this.engine = const RecurrenceEngine()});

  final RecurrenceEngine engine;

  List<TaskCalendarOccurrence> project({
    required List<TaskItem> tasks,
    required List<TaskRecurrenceRule> rules,
    required List<TaskRecurrenceException> exceptions,
    required List<TaskOccurrenceCompletion> completions,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
    required String floatingTimeZoneId,
    int maximumOccurrences = 10000,
  }) {
    if (!rangeStartUtc.isUtc || !rangeEndUtc.isUtc) {
      throw ArgumentError('Task occurrence projection requires UTC range.');
    }
    if (!rangeStartUtc.isBefore(rangeEndUtc)) {
      throw ArgumentError('Task occurrence range must be non-empty.');
    }

    final ruleByTask = <String, TaskRecurrenceRule>{
      for (final rule in rules) rule.taskId: rule,
    };
    final exceptionsByTask = <String, List<TaskRecurrenceException>>{};
    for (final exception in exceptions) {
      exceptionsByTask
          .putIfAbsent(exception.taskId, () => <TaskRecurrenceException>[])
          .add(exception);
    }
    final completionKeys = <String>{
      for (final completion in completions) completion.occurrenceKey,
    };

    final output = <TaskCalendarOccurrence>[];
    for (final task in tasks) {
      final series = ruleByTask[task.id];
      if (series == null) {
        final oneOff = _projectOneOff(
          task: task,
          rangeStartUtc: rangeStartUtc,
          rangeEndUtc: rangeEndUtc,
          floatingTimeZoneId: floatingTimeZoneId,
        );
        if (oneOff != null) output.add(oneOff);
        continue;
      }

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.canceled) {
        continue;
      }

      final recurrenceOccurrences = engine.expand(
        rule: series.rule,
        rangeStartUtc: rangeStartUtc,
        rangeEndUtc: rangeEndUtc,
        floatingTimeZoneId: floatingTimeZoneId,
        exceptions:
            (exceptionsByTask[task.id] ?? const <TaskRecurrenceException>[])
                .map((item) => item.exception)
                .toList(growable: false),
        maximumOccurrences: maximumOccurrences,
      );

      for (final occurrence in recurrenceOccurrences) {
        final occurrenceKey =
            '${task.id}@${occurrence.originalLocalDateTime.storageKey}';
        output.add(
          TaskCalendarOccurrence(
            task: task,
            originalLocalDateTime: occurrence.originalLocalDateTime,
            effectiveLocalDateTime: occurrence.effectiveLocalDateTime,
            instantUtc: occurrence.instantUtc,
            timeZoneId: occurrence.timeZoneId,
            calendar: occurrence.calendar,
            sequence: occurrence.sequence,
            status:
                completionKeys.contains(occurrenceKey) &&
                    occurrence.status != RecurrenceOccurrenceStatus.skipped &&
                    occurrence.status != RecurrenceOccurrenceStatus.canceled
                ? TaskCalendarOccurrenceStatus.completed
                : _statusFromCore(occurrence.status),
            recurring: true,
          ),
        );
      }
    }

    output.sort((left, right) {
      final time = left.instantUtc.compareTo(right.instantUtc);
      if (time != 0) return time;
      final display = left.task.displayNumber.compareTo(
        right.task.displayNumber,
      );
      if (display != 0) return display;
      return left.occurrenceKey.compareTo(right.occurrenceKey);
    });
    return List<TaskCalendarOccurrence>.unmodifiable(output);
  }

  TaskCalendarOccurrence? _projectOneOff({
    required TaskItem task,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
    required String floatingTimeZoneId,
  }) {
    final instantUtc = task.dueAtUtc ?? task.startAtUtc;
    if (instantUtc == null ||
        instantUtc.isBefore(rangeStartUtc) ||
        !instantUtc.isBefore(rangeEndUtc)) {
      return null;
    }

    final location = timezone.getLocation(floatingTimeZoneId);
    final local = timezone.TZDateTime.from(instantUtc, location);
    final civil = RecurrenceLocalDateTime(
      year: local.year,
      month: local.month,
      day: local.day,
      hour: local.hour,
      minute: local.minute,
    );

    final status = switch (task.status) {
      TaskStatus.completed => TaskCalendarOccurrenceStatus.completed,
      TaskStatus.canceled => TaskCalendarOccurrenceStatus.canceled,
      TaskStatus.planned ||
      TaskStatus.inProgress => TaskCalendarOccurrenceStatus.scheduled,
    };

    return TaskCalendarOccurrence(
      task: task,
      originalLocalDateTime: civil,
      effectiveLocalDateTime: civil,
      instantUtc: instantUtc,
      timeZoneId: floatingTimeZoneId,
      calendar: RecurrenceCalendar.gregorian,
      sequence: 1,
      status: status,
      recurring: false,
    );
  }
}

TaskCalendarOccurrenceStatus _statusFromCore(
  RecurrenceOccurrenceStatus status,
) {
  return switch (status) {
    RecurrenceOccurrenceStatus.scheduled =>
      TaskCalendarOccurrenceStatus.scheduled,
    RecurrenceOccurrenceStatus.moved => TaskCalendarOccurrenceStatus.moved,
    RecurrenceOccurrenceStatus.skipped => TaskCalendarOccurrenceStatus.skipped,
    RecurrenceOccurrenceStatus.canceled =>
      TaskCalendarOccurrenceStatus.canceled,
  };
}
