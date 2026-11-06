import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_calendar_adapter.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';

final class GregorianRecurrenceCalendar implements RecurrenceCalendarAdapter {
  const GregorianRecurrenceCalendar();

  @override
  RecurrenceCalendar get calendar => RecurrenceCalendar.gregorian;

  @override
  bool isValidDate({required int year, required int month, required int day}) {
    if (year < 1 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    return day <= daysInMonth(year: year, month: month);
  }

  @override
  int daysInMonth({required int year, required int month}) {
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError.value(
        '$year-$month',
        'yearMonth',
        'Gregorian year and month are invalid.',
      );
    }
    return DateTime.utc(year, month + 1, 0).day;
  }

  @override
  int weekday(RecurrenceLocalDateTime value) {
    _requireValid(value);
    return DateTime.utc(value.year, value.month, value.day).weekday;
  }

  @override
  RecurrenceLocalDateTime addDays(RecurrenceLocalDateTime value, int days) {
    _requireValid(value);
    final shifted = DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).add(Duration(days: days));
    return RecurrenceLocalDateTime(
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      hour: value.hour,
      minute: value.minute,
    );
  }

  @override
  RecurrenceYearMonth shiftMonth({
    required int year,
    required int month,
    required int delta,
  }) {
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError.value(
        '$year-$month',
        'yearMonth',
        'Gregorian year and month are invalid.',
      );
    }
    final zeroBased = (year * 12) + (month - 1) + delta;
    final shiftedYear = zeroBased ~/ 12;
    final shiftedMonth = (zeroBased % 12) + 1;
    if (shiftedYear < 1) {
      throw ArgumentError.value(
        delta,
        'delta',
        'Shifted Gregorian year must remain positive.',
      );
    }
    return RecurrenceYearMonth(year: shiftedYear, month: shiftedMonth);
  }

  @override
  RecurrenceLocalDateTime toGregorianCivil(RecurrenceLocalDateTime value) {
    _requireValid(value);
    return value;
  }

  @override
  RecurrenceLocalDateTime fromGregorianCivil(RecurrenceLocalDateTime value) {
    _requireValid(value);
    return value;
  }

  void _requireValid(RecurrenceLocalDateTime value) {
    if (!isValidDate(year: value.year, month: value.month, day: value.day)) {
      throw ArgumentError.value(
        value,
        'value',
        'Gregorian recurrence date is invalid.',
      );
    }
  }
}
