import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_calendar_adapter.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:shamsi_date/shamsi_date.dart';

final class JalaliRecurrenceCalendar implements RecurrenceCalendarAdapter {
  const JalaliRecurrenceCalendar();

  @override
  RecurrenceCalendar get calendar => RecurrenceCalendar.jalali;

  @override
  bool isValidDate({required int year, required int month, required int day}) {
    if (year < 1 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    try {
      Jalali(year, month, day);
      return true;
    } on DateException {
      return false;
    }
  }

  @override
  int daysInMonth({required int year, required int month}) {
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError.value(
        '$year-$month',
        'yearMonth',
        'Jalali year and month are invalid.',
      );
    }
    return Jalali(year, month, 1).monthLength;
  }

  @override
  int weekday(RecurrenceLocalDateTime value) {
    _requireValid(value);
    return Jalali(value.year, value.month, value.day).toGregorian().weekDay;
  }

  @override
  RecurrenceLocalDateTime addDays(RecurrenceLocalDateTime value, int days) {
    _requireValid(value);
    final shifted = Jalali(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).addDays(days);
    return RecurrenceLocalDateTime(
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      hour: shifted.hour,
      minute: shifted.minute,
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
        'Jalali year and month are invalid.',
      );
    }
    final zeroBased = (year * 12) + (month - 1) + delta;
    final shiftedYear = zeroBased ~/ 12;
    final shiftedMonth = (zeroBased % 12) + 1;
    if (shiftedYear < 1) {
      throw ArgumentError.value(
        delta,
        'delta',
        'Shifted Jalali year must remain positive.',
      );
    }
    return RecurrenceYearMonth(year: shiftedYear, month: shiftedMonth);
  }

  @override
  RecurrenceLocalDateTime toGregorianCivil(RecurrenceLocalDateTime value) {
    _requireValid(value);
    final gregorian = Jalali(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).toGregorian();
    return RecurrenceLocalDateTime(
      year: gregorian.year,
      month: gregorian.month,
      day: gregorian.day,
      hour: gregorian.hour,
      minute: gregorian.minute,
    );
  }

  @override
  RecurrenceLocalDateTime fromGregorianCivil(RecurrenceLocalDateTime value) {
    final jalali = Gregorian(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).toJalali();
    return RecurrenceLocalDateTime(
      year: jalali.year,
      month: jalali.month,
      day: jalali.day,
      hour: jalali.hour,
      minute: jalali.minute,
    );
  }

  void _requireValid(RecurrenceLocalDateTime value) {
    if (!isValidDate(year: value.year, month: value.month, day: value.day)) {
      throw ArgumentError.value(
        value,
        'value',
        'Jalali recurrence date is invalid.',
      );
    }
  }
}
