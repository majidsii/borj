import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 6, 8);

  test('task recurrence rule trims identity and keeps shared rule', () {
    final shared = RecurrenceRule.daily(
      anchorLocalDateTime: _local(2026, 8, 6, 9),
    );
    final result = TaskRecurrenceRule(
      id: ' rule-1 ',
      taskId: ' task-1 ',
      rule: shared,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    expect(result.id, 'rule-1');
    expect(result.taskId, 'task-1');
    expect(identical(result.rule, shared), isTrue);
  });

  test('task recurrence timestamps must use UTC', () {
    expect(
      () => TaskRecurrenceRule(
        id: 'r',
        taskId: 't',
        rule: RecurrenceRule.daily(anchorLocalDateTime: _local(2026, 8, 6, 9)),
        createdAtUtc: DateTime(2026, 8, 6),
        updatedAtUtc: now,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('occurrence completion identity uses original local time', () {
    final completion = TaskOccurrenceCompletion(
      taskId: 'task-7',
      originalLocalDateTime: _local(1405, 5, 15, 9, 30),
      completedAtUtc: now,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    expect(completion.occurrenceKey, 'task-7@1405-05-15T09:30');
  });
}

RecurrenceLocalDateTime _local(
  int year,
  int month,
  int day,
  int hour, [
  int minute = 0,
]) {
  return RecurrenceLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
  );
}
