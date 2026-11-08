import 'package:borj/features/tasks/application/task_occurrence_projector.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/domain/today_entry.dart';
import 'package:timezone/timezone.dart' as timezone;

export 'package:borj/features/today/domain/today_entry.dart';

/// Builds Today's agenda. Every time in the result is a wall-clock value in
/// [timeZoneId], held in a naive `DateTime`, so the device zone never matters.
final class TodayAgendaBuilder {
  const TodayAgendaBuilder({this.projector = const TaskOccurrenceProjector()});

  final TaskOccurrenceProjector projector;

  TodayAgenda build({
    required List<TaskItem> tasks,
    required List<TaskRecurrenceRule> rules,
    required List<TaskRecurrenceException> exceptions,
    required List<TaskOccurrenceCompletion> completions,
    required DateTime nowUtc,
    required String timeZoneId,
  }) {
    final location = timezone.getLocation(timeZoneId);
    final zonedNow = timezone.TZDateTime.from(nowUtc.toUtc(), location);
    final day = DateTime(zonedNow.year, zonedNow.month, zonedNow.day);
    final startUtc = timezone.TZDateTime(
      location,
      zonedNow.year,
      zonedNow.month,
      zonedNow.day,
    ).toUtc();
    final endUtc = timezone.TZDateTime(
      location,
      zonedNow.year,
      zonedNow.month,
      zonedNow.day + 1,
    ).toUtc();

    final occurrences = projector.project(
      tasks: tasks,
      rules: rules,
      exceptions: exceptions,
      completions: completions,
      rangeStartUtc: startUtc,
      rangeEndUtc: endUtc,
      floatingTimeZoneId: timeZoneId,
    );

    final timed = <TodayEntry>[
      for (final o in occurrences)
        if (o.status != TaskCalendarOccurrenceStatus.skipped &&
            o.status != TaskCalendarOccurrenceStatus.canceled)
          _entry(o, location),
    ]..sort((a, b) => a.localStart!.compareTo(b.localStart!));

    final ruleTaskIds = {for (final r in rules) r.taskId};
    final untimed = <TodayEntry>[
      for (final t in tasks)
        if (!ruleTaskIds.contains(t.id) &&
            t.startAtUtc == null &&
            t.dueAtUtc == null &&
            (t.status == TaskStatus.planned ||
                t.status == TaskStatus.inProgress))
          TodayEntry(
            taskId: t.id,
            title: t.title,
            done: false,
            recurring: false,
          ),
    ];

    return TodayAgenda(day: day, timed: timed, untimed: untimed);
  }

  TodayEntry _entry(TaskCalendarOccurrence o, timezone.Location location) {
    final local = timezone.TZDateTime.from(o.instantUtc, location);
    return TodayEntry(
      taskId: o.task.id,
      title: o.task.title,
      done: o.isCompleted,
      recurring: o.recurring,
      localStart: DateTime(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      ),
      durationMinutes: o.task.estimatedDurationMinutes,
      originalLocalDateTime: o.recurring ? o.originalLocalDateTime : null,
    );
  }
}
