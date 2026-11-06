// Task 2.2 Heavy UI RED
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_planning_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  test('formats Jalali local date and time with Persian digits', () {
    final local = Jalali(
      1405,
      5,
      13,
    ).toDateTime().copyWith(hour: 11, minute: 30);

    expect(taskJalaliDateTimeLabel(local), '۱۳ مرداد ۱۴۰۵، ۱۱:۳۰');
  });

  test('start due and duration labels are concise and nullable', () {
    final startLocal = Jalali(
      1405,
      5,
      13,
    ).toDateTime().copyWith(hour: 11, minute: 30);
    final dueLocal = startLocal.copyWith(hour: 15, minute: 0);
    final task = _task(
      startAtUtc: startLocal.toUtc(),
      dueAtUtc: dueLocal.toUtc(),
      estimatedDurationMinutes: 90,
    );

    expect(taskStartLabel(task), 'شروع: ۱۳ مرداد ۱۴۰۵، ۱۱:۳۰');
    expect(taskDueLabel(task), 'سررسید: ۱۳ مرداد ۱۴۰۵، ۱۵:۰۰');
    expect(taskEstimatedDurationLabel(task), 'تخمین: ۱ ساعت و ۳۰ دقیقه');

    final empty = _task();
    expect(taskStartLabel(empty), isNull);
    expect(taskDueLabel(empty), isNull);
    expect(taskEstimatedDurationLabel(empty), isNull);
  });

  test('duration labels cover minutes exact hours and mixed values', () {
    expect(
      taskEstimatedDurationLabel(_task(estimatedDurationMinutes: 45)),
      'تخمین: ۴۵ دقیقه',
    );
    expect(
      taskEstimatedDurationLabel(_task(estimatedDurationMinutes: 120)),
      'تخمین: ۲ ساعت',
    );
    expect(
      taskEstimatedDurationLabel(_task(estimatedDurationMinutes: 135)),
      'تخمین: ۲ ساعت و ۱۵ دقیقه',
    );
  });
}

TaskItem _task({
  DateTime? startAtUtc,
  DateTime? dueAtUtc,
  int? estimatedDurationMinutes,
}) {
  return TaskItem(
    id: 'task',
    displayNumber: 1,
    title: 'کار',
    priority: 0,
    status: TaskStatus.planned,
    positionInStatus: 0,
    startAtUtc: startAtUtc,
    dueAtUtc: dueAtUtc,
    estimatedDurationMinutes: estimatedDurationMinutes,
    createdAtUtc: DateTime.utc(2026, 8, 4),
    updatedAtUtc: DateTime.utc(2026, 8, 4),
  );
}
