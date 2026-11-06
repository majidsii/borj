import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';

final class TaskOccurrenceCompletion {
  TaskOccurrenceCompletion({
    required String taskId,
    required this.originalLocalDateTime,
    required this.completedAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : taskId = taskId.trim() {
    if (this.taskId.isEmpty) {
      throw const ValidationFailure(
        'شناسه کار برای تکمیل رخداد نمی‌تواند خالی باشد.',
      );
    }
    _requireUtc(completedAtUtc);
    _requireUtc(createdAtUtc);
    _requireUtc(updatedAtUtc);
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure(
        'زمان ویرایش تکمیل رخداد نمی‌تواند قبل از ایجاد آن باشد.',
      );
    }
  }

  final String taskId;
  final RecurrenceLocalDateTime originalLocalDateTime;
  final DateTime completedAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  String get occurrenceKey => '$taskId@${originalLocalDateTime.storageKey}';
}

void _requireUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure(
      'زمان تکمیل رخداد باید به‌صورت UTC ذخیره شود.',
    );
  }
}
