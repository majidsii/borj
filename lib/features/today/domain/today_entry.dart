import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:flutter/foundation.dart';

/// One task on Today: a timed occurrence of the local day, or an untimed
/// active task. All times are wall-clock times in the task calendar zone.
@immutable
final class TodayEntry {
  const TodayEntry({
    required this.taskId,
    required this.title,
    required this.done,
    required this.recurring,
    this.localStart,
    this.durationMinutes,
    this.originalLocalDateTime,
  });

  final String taskId;
  final String title;
  final bool done;
  final bool recurring;

  /// Zone wall-clock start (minute precision); null for untimed tasks.
  final DateTime? localStart;
  final int? durationMinutes;

  /// The occurrence key of a recurring entry (for completion).
  final RecurrenceLocalDateTime? originalLocalDateTime;

  bool get timed => localStart != null;

  /// Identity within one agenda: a recurring task can appear twice on one day
  /// (its tomorrow occurrence moved into today), so the task id alone is not
  /// unique. One-offs have no occurrence key.
  String get key {
    final o = originalLocalDateTime;
    if (o == null) return '$taskId@one-off';
    String two(int v) => v.toString().padLeft(2, '0');
    return '$taskId@${o.year}-${two(o.month)}-${two(o.day)}'
        'T${two(o.hour)}:${two(o.minute)}';
  }

  @override
  bool operator ==(Object other) =>
      other is TodayEntry &&
      other.taskId == taskId &&
      other.title == title &&
      other.done == done &&
      other.recurring == recurring &&
      other.localStart == localStart &&
      other.durationMinutes == durationMinutes &&
      other.originalLocalDateTime == originalLocalDateTime;

  @override
  int get hashCode => Object.hash(
    taskId,
    title,
    done,
    recurring,
    localStart,
    durationMinutes,
    originalLocalDateTime,
  );
}

@immutable
final class TodayAgenda {
  const TodayAgenda({
    required this.day,
    required this.timed,
    required this.untimed,
  });

  factory TodayAgenda.empty(DateTime day) =>
      TodayAgenda(day: day, timed: const [], untimed: const []);

  /// Midnight of the day, as a wall-clock value in the task calendar zone.
  final DateTime day;
  final List<TodayEntry> timed;
  final List<TodayEntry> untimed;

  bool get isEmpty => timed.isEmpty && untimed.isEmpty;

  /// The first timed, unfinished entry starting at or after [zoneNow] (a zone
  /// wall-clock value; minute precision).
  TodayEntry? nextAfter(DateTime zoneNow) {
    final minute = DateTime(
      zoneNow.year,
      zoneNow.month,
      zoneNow.day,
      zoneNow.hour,
      zoneNow.minute,
    );
    for (final e in timed) {
      if (!e.done && !e.localStart!.isBefore(minute)) return e;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is TodayAgenda &&
      other.day == day &&
      listEquals(other.timed, timed) &&
      listEquals(other.untimed, untimed);

  @override
  int get hashCode =>
      Object.hash(day, Object.hashAll(timed), Object.hashAll(untimed));
}
