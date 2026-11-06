import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_status.dart';

final class TaskItem {
  TaskItem({
    required this.id,
    required this.displayNumber,
    required String title,
    String? description,
    required this.priority,
    required this.status,
    required this.positionInStatus,
    this.startAtUtc,
    this.dueAtUtc,
    this.estimatedDurationMinutes,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
    this.canceledAtUtc,
  }) : title = title.trim(),
       description = _normalizeOptionalText(description) {
    if (id.trim().isEmpty) {
      throw const ValidationFailure('شناسه کار نمی‌تواند خالی باشد.');
    }
    if (displayNumber <= 0) {
      throw const ValidationFailure('شماره نمایش کار نامعتبر است.');
    }
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان کار نمی‌تواند خالی باشد.');
    }
    if (priority < 0 || priority > 3) {
      throw const ValidationFailure('اولویت کار نامعتبر است.');
    }
    if (positionInStatus < 0) {
      throw const ValidationFailure('ترتیب کار در وضعیت نامعتبر است.');
    }

    final startAt = startAtUtc;
    if (startAt != null) {
      _validateUtc(startAt);
    }
    final dueAt = dueAtUtc;
    if (dueAt != null) {
      _validateUtc(dueAt);
    }
    if (startAt != null && dueAt != null && dueAt.isBefore(startAt)) {
      throw const ValidationFailure(
        'زمان سررسید نمی‌تواند قبل از زمان شروع باشد.',
      );
    }
    final estimatedDuration = estimatedDurationMinutes;
    if (estimatedDuration != null && estimatedDuration <= 0) {
      throw const ValidationFailure('مدت تخمینی کار باید بیشتر از صفر باشد.');
    }

    _validateUtc(createdAtUtc);
    _validateUtc(updatedAtUtc);

    final completedAt = completedAtUtc;
    if (completedAt != null) {
      _validateUtc(completedAt);
    }
    final canceledAt = canceledAtUtc;
    if (canceledAt != null) {
      _validateUtc(canceledAt);
    }

    _validateStatusTimestamps(
      status: status,
      completedAtUtc: completedAt,
      canceledAtUtc: canceledAt,
    );
  }

  final String id;
  final int displayNumber;
  final String title;
  final String? description;
  final int priority;
  final TaskStatus status;
  final int positionInStatus;
  final DateTime? startAtUtc;
  final DateTime? dueAtUtc;
  final int? estimatedDurationMinutes;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime? canceledAtUtc;

  bool get isDone => status == TaskStatus.completed;

  bool get isActive =>
      status == TaskStatus.planned || status == TaskStatus.inProgress;

  int get sortOrder => positionInStatus;

  TaskItem copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    int? priority,
    TaskStatus? status,
    int? positionInStatus,
    DateTime? startAtUtc,
    bool clearStartAt = false,
    DateTime? dueAtUtc,
    bool clearDueAt = false,
    int? estimatedDurationMinutes,
    bool clearEstimatedDuration = false,
    DateTime? updatedAtUtc,
    DateTime? completedAtUtc,
    bool clearCompletedAt = false,
    DateTime? canceledAtUtc,
    bool clearCanceledAt = false,
  }) {
    return TaskItem(
      id: id,
      displayNumber: displayNumber,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      positionInStatus: positionInStatus ?? this.positionInStatus,
      startAtUtc: clearStartAt ? null : startAtUtc ?? this.startAtUtc,
      dueAtUtc: clearDueAt ? null : dueAtUtc ?? this.dueAtUtc,
      estimatedDurationMinutes: clearEstimatedDuration
          ? null
          : estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      completedAtUtc: clearCompletedAt
          ? null
          : completedAtUtc ?? this.completedAtUtc,
      canceledAtUtc: clearCanceledAt
          ? null
          : canceledAtUtc ?? this.canceledAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskItem &&
            other.id == id &&
            other.displayNumber == displayNumber &&
            other.title == title &&
            other.description == description &&
            other.priority == priority &&
            other.status == status &&
            other.positionInStatus == positionInStatus &&
            other.startAtUtc == startAtUtc &&
            other.dueAtUtc == dueAtUtc &&
            other.estimatedDurationMinutes == estimatedDurationMinutes &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc &&
            other.completedAtUtc == completedAtUtc &&
            other.canceledAtUtc == canceledAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayNumber,
    title,
    description,
    priority,
    status,
    positionInStatus,
    startAtUtc,
    dueAtUtc,
    estimatedDurationMinutes,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
    canceledAtUtc,
  );

  @override
  String toString() {
    return 'TaskItem(id: $id, displayNumber: $displayNumber, title: $title, '
        'description: $description, priority: $priority, status: $status, '
        'positionInStatus: $positionInStatus, startAtUtc: $startAtUtc, '
        'dueAtUtc: $dueAtUtc, '
        'estimatedDurationMinutes: $estimatedDurationMinutes)';
  }
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

void _validateUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure('زمان کار باید به‌صورت UTC ذخیره شود.');
  }
}

void _validateStatusTimestamps({
  required TaskStatus status,
  required DateTime? completedAtUtc,
  required DateTime? canceledAtUtc,
}) {
  switch (status) {
    case TaskStatus.completed:
      if (completedAtUtc == null || canceledAtUtc != null) {
        throw const ValidationFailure(
          'زمان تکمیل کار با وضعیت آن سازگار نیست.',
        );
      }
      break;
    case TaskStatus.canceled:
      if (canceledAtUtc == null || completedAtUtc != null) {
        throw const ValidationFailure('زمان لغو کار با وضعیت آن سازگار نیست.');
      }
      break;
    case TaskStatus.planned:
    case TaskStatus.inProgress:
      if (completedAtUtc != null || canceledAtUtc != null) {
        throw const ValidationFailure(
          'کار فعال نمی‌تواند زمان پایان داشته باشد.',
        );
      }
      break;
  }
}
