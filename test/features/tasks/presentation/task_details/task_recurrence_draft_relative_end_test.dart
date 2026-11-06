import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskRecurrenceDraft relativeDraft(int days) {
    return TaskRecurrenceDraft(
      enabled: true,
      frequency: RecurrenceFrequency.daily,
      interval: 1,
      calendar: RecurrenceCalendar.gregorian,
      timeZoneMode: RecurrenceTimeZoneMode.floating,
      fixedTimeZoneId: 'Asia/Tehran',
      weeklyDays: const <RecurrenceWeekday>{},
      monthlyDaysText: '',
      includeLastDay: false,
      annualDatesText: '',
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      endKind: RecurrenceEndKind.until,
      untilLocal: null,
      afterCount: 10,
      relativeEndDaysAfterAnchor: days,
    );
  }

  test('relative end follows the supplied recurrence anchor', () {
    final draft = relativeDraft(10);

    expect(
      draft.effectiveUntilLocal(DateTime(2026, 8, 10, 9)),
      DateTime(2026, 8, 20, 9),
    );

    expect(
      draft.effectiveUntilLocal(DateTime(2026, 8, 15, 14, 30)),
      DateTime(2026, 8, 25, 14, 30),
    );
  });

  test('manual absolute until breaks the relative link', () {
    final draft = relativeDraft(10);
    final manual = DateTime(2026, 12, 1, 18);

    draft.setManualUntilLocal(manual);

    expect(draft.relativeEndDaysAfterAnchor, isNull);
    expect(draft.untilLocal, manual);
    expect(draft.effectiveUntilLocal(DateTime(2026, 8, 10, 9)), manual);
  });
}
