import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';

enum RecurrenceOccurrenceStatus { scheduled, moved, skipped, canceled }

final class RecurrenceOccurrence {
  const RecurrenceOccurrence({
    required this.originalLocalDateTime,
    required this.effectiveLocalDateTime,
    required this.instantUtc,
    required this.timeZoneId,
    required this.calendar,
    required this.sequence,
    required this.status,
  });

  final RecurrenceLocalDateTime originalLocalDateTime;
  final RecurrenceLocalDateTime effectiveLocalDateTime;
  final DateTime instantUtc;
  final String timeZoneId;
  final RecurrenceCalendar calendar;
  final int sequence;
  final RecurrenceOccurrenceStatus status;

  @override
  bool operator ==(Object other) {
    return other is RecurrenceOccurrence &&
        other.originalLocalDateTime == originalLocalDateTime &&
        other.effectiveLocalDateTime == effectiveLocalDateTime &&
        other.instantUtc == instantUtc &&
        other.timeZoneId == timeZoneId &&
        other.calendar == calendar &&
        other.sequence == sequence &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
    originalLocalDateTime,
    effectiveLocalDateTime,
    instantUtc,
    timeZoneId,
    calendar,
    sequence,
    status,
  );
}
