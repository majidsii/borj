import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';

final class TaskRecurrenceException {
  TaskRecurrenceException({
    required String id,
    required String taskId,
    required this.exception,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : id = id.trim(),
       taskId = taskId.trim() {
    if (this.id.isEmpty) {
      throw const ValidationFailure('شناسه استثنای تکرار نمی‌تواند خالی باشد.');
    }
    if (this.taskId.isEmpty) {
      throw const ValidationFailure('شناسه کار استثنا نمی‌تواند خالی باشد.');
    }
    _requireUtc(createdAtUtc);
    _requireUtc(updatedAtUtc);
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure(
        'زمان ویرایش استثنا نمی‌تواند قبل از ایجاد آن باشد.',
      );
    }
  }

  final String id;
  final String taskId;
  final RecurrenceException exception;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}

void _requireUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure(
      'زمان استثنای تکرار باید به‌صورت UTC ذخیره شود.',
    );
  }
}
