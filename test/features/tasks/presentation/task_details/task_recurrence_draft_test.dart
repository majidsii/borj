import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final savedAt = DateTime.utc(2026, 8, 6, 8);

  test('disabled draft builds no task recurrence rule', () {
    final draft = TaskRecurrenceDraft.disabled();

    expect(
      draft.build(
        taskId: 'task',
        anchorLocal: null,
        savedAtUtc: savedAt,
        nextId: () => 'id',
      ),
      isNull,
    );
  });

  test('weekly draft requires an anchor and selected weekday', () {
    final draft = TaskRecurrenceDraft.disabled()
      ..enabled = true
      ..frequency = RecurrenceFrequency.weekly;

    expect(draft.validate(anchorLocal: null), contains('شروع یا سررسید'));

    expect(
      draft.validate(anchorLocal: DateTime(2026, 8, 7, 9)),
      contains('روز هفته'),
    );
  });

  test('builds a Jalali weekly rule with floating timezone', () {
    final draft = TaskRecurrenceDraft.disabled()
      ..enabled = true
      ..frequency = RecurrenceFrequency.weekly
      ..calendar = RecurrenceCalendar.jalali
      ..interval = 2
      ..weeklyDays.addAll(<RecurrenceWeekday>{
        RecurrenceWeekday.saturday,
        RecurrenceWeekday.monday,
      })
      ..endKind = RecurrenceEndKind.afterCount
      ..afterCount = 8;

    final result = draft.build(
      taskId: 'task',
      anchorLocal: DateTime(2026, 8, 8, 9, 30),
      savedAtUtc: savedAt,
      nextId: () => 'rule',
    )!;

    expect(result.id, 'rule');
    expect(result.rule.calendar, RecurrenceCalendar.jalali);
    expect(result.rule.interval, 2);
    expect(result.rule.weeklyDays, hasLength(2));
    expect(result.rule.end.count, 8);
  });

  test('monthly CSV accepts multiple unique days and last day', () {
    final draft = TaskRecurrenceDraft.disabled()
      ..enabled = true
      ..frequency = RecurrenceFrequency.monthly
      ..monthlyDaysText = '5, 20, 20, 31'
      ..includeLastDay = true;

    final result = draft.build(
      taskId: 'task',
      anchorLocal: DateTime(2026, 8, 8, 9),
      savedAtUtc: savedAt,
      nextId: () => 'rule',
    )!;

    expect(result.rule.monthlySelectors, hasLength(4));
  });
}
