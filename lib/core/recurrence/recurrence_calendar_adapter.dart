import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';

final class RecurrenceYearMonth {
  const RecurrenceYearMonth({required this.year, required this.month});

  final int year;
  final int month;
}

abstract interface class RecurrenceCalendarAdapter {
  RecurrenceCalendar get calendar;

  bool isValidDate({required int year, required int month, required int day});

  int daysInMonth({required int year, required int month});

  int weekday(RecurrenceLocalDateTime value);

  RecurrenceLocalDateTime addDays(RecurrenceLocalDateTime value, int days);

  RecurrenceYearMonth shiftMonth({
    required int year,
    required int month,
    required int delta,
  });

  RecurrenceLocalDateTime toGregorianCivil(RecurrenceLocalDateTime value);

  RecurrenceLocalDateTime fromGregorianCivil(RecurrenceLocalDateTime value);
}
