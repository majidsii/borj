import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:timezone/timezone.dart' as timezone;

final class RecurrenceTimeZoneResolution {
  const RecurrenceTimeZoneResolution({
    required this.effectiveGregorianLocalDateTime,
    required this.instantUtc,
  });

  final RecurrenceLocalDateTime effectiveGregorianLocalDateTime;
  final DateTime instantUtc;
}

abstract interface class RecurrenceTimeZoneResolver {
  RecurrenceTimeZoneResolution resolve({
    required RecurrenceLocalDateTime gregorianLocalDateTime,
    required String timeZoneId,
  });
}

final class TimezoneRecurrenceResolver implements RecurrenceTimeZoneResolver {
  const TimezoneRecurrenceResolver({this.maximumGapSearchMinutes = 360});

  final int maximumGapSearchMinutes;

  @override
  RecurrenceTimeZoneResolution resolve({
    required RecurrenceLocalDateTime gregorianLocalDateTime,
    required String timeZoneId,
  }) {
    final normalizedTimeZoneId = timeZoneId.trim();
    if (normalizedTimeZoneId.isEmpty) {
      throw const ValidationFailure(
        'شناسه منطقه زمانی تکرار نمی‌تواند خالی باشد.',
      );
    }
    if (maximumGapSearchMinutes < 1) {
      throw const ValidationFailure(
        'محدوده جست‌وجوی شکاف زمانی باید مثبت باشد.',
      );
    }

    final timezone.Location location;
    try {
      location = timezone.getLocation(normalizedTimeZoneId);
    } on timezone.LocationNotFoundException {
      throw ValidationFailure('منطقه زمانی $normalizedTimeZoneId شناخته نشد.');
    }

    var requested = gregorianLocalDateTime;
    for (
      var minuteOffset = 0;
      minuteOffset <= maximumGapSearchMinutes;
      minuteOffset += 1
    ) {
      final matches = _exactMatches(requested: requested, location: location);
      if (matches.isNotEmpty) {
        matches.sort();
        return RecurrenceTimeZoneResolution(
          effectiveGregorianLocalDateTime: requested,
          instantUtc: matches.first,
        );
      }
      requested = _addCivilMinute(requested);
    }

    throw ValidationFailure(
      'زمان محلی در منطقه $normalizedTimeZoneId قابل حل نیست.',
    );
  }

  List<DateTime> _exactMatches({
    required RecurrenceLocalDateTime requested,
    required timezone.Location location,
  }) {
    final wallClockUtc = DateTime.utc(
      requested.year,
      requested.month,
      requested.day,
      requested.hour,
      requested.minute,
    );

    final offsets = <Duration>{};
    for (final hourOffset in const <int>[-48, -24, -12, 0, 12, 24, 48]) {
      final sampleInstant = wallClockUtc.add(Duration(hours: hourOffset));
      final sample = timezone.TZDateTime.from(sampleInstant, location);
      offsets.add(sample.timeZoneOffset);
    }

    final matches = <DateTime>[];
    for (final offset in offsets) {
      final instantUtc = wallClockUtc.subtract(offset);
      final resolved = timezone.TZDateTime.from(instantUtc, location);
      if (_sameCivil(resolved, requested)) {
        matches.add(instantUtc);
      }
    }

    return matches;
  }

  bool _sameCivil(
    timezone.TZDateTime resolved,
    RecurrenceLocalDateTime requested,
  ) {
    return resolved.year == requested.year &&
        resolved.month == requested.month &&
        resolved.day == requested.day &&
        resolved.hour == requested.hour &&
        resolved.minute == requested.minute;
  }

  RecurrenceLocalDateTime _addCivilMinute(RecurrenceLocalDateTime value) {
    final shifted = DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).add(const Duration(minutes: 1));
    return RecurrenceLocalDateTime(
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      hour: shifted.hour,
      minute: shifted.minute,
    );
  }
}
