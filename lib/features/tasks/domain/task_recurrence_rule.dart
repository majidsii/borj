import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';

final class TaskRecurrenceRule {
  TaskRecurrenceRule({
    required String id,
    required String taskId,
    required this.rule,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : id = id.trim(),
       taskId = taskId.trim() {
    if (this.id.isEmpty) {
      throw const ValidationFailure('شناسه قانون تکرار نمی‌تواند خالی باشد.');
    }
    if (this.taskId.isEmpty) {
      throw const ValidationFailure(
        'شناسه کار تکرارشونده نمی‌تواند خالی باشد.',
      );
    }
    _requireUtc(createdAtUtc);
    _requireUtc(updatedAtUtc);
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure(
        'زمان ویرایش قانون تکرار نمی‌تواند قبل از ایجاد آن باشد.',
      );
    }
  }

  final String id;
  final String taskId;
  final RecurrenceRule rule;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  TaskRecurrenceRule copyWith({RecurrenceRule? rule, DateTime? updatedAtUtc}) {
    return TaskRecurrenceRule(
      id: id,
      taskId: taskId,
      rule: rule ?? this.rule,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}

void _requireUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure(
      'زمان قانون تکرار باید به‌صورت UTC ذخیره شود.',
    );
  }
}
