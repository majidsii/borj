import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_repository.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:shamsi_date/shamsi_date.dart';

final class TaskRecurrenceService {
  factory TaskRecurrenceService({
    required TaskRecurrenceRepository repository,
    required DateTime Function() nowUtc,
    required String Function() nextId,
    Future<void> Function(String taskId)? onChanged,
  }) {
    return TaskRecurrenceService._(repository, nowUtc, nextId, onChanged);
  }

  const TaskRecurrenceService._(
    this._repository,
    this._nowUtc,
    this._nextId,
    this._onChanged,
  );

  final TaskRecurrenceRepository _repository;
  final DateTime Function() _nowUtc;
  final String Function() _nextId;
  final Future<void> Function(String taskId)? _onChanged;

  Future<void> replaceRule({
    required String taskId,
    required RecurrenceRule? rule,
  }) async {
    final now = _nowUtc().toUtc();
    final existing = await _repository.getByTask(taskId);
    final wrapped = rule == null
        ? null
        : TaskRecurrenceRule(
            id: existing.rule?.id ?? _nextId(),
            taskId: taskId,
            rule: rule,
            createdAtUtc: existing.rule?.createdAtUtc ?? now,
            updatedAtUtc: now,
          );
    await _repository.replaceRule(taskId: taskId, rule: wrapped);
    await _notifyChanged(taskId);
  }

  Future<void> skip({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) {
    return _writeException(
      taskId: taskId,
      exception: RecurrenceException.skip(
        originalLocalDateTime: originalLocalDateTime,
      ),
    );
  }

  Future<void> cancel({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) {
    return _writeException(
      taskId: taskId,
      exception: RecurrenceException.cancel(
        originalLocalDateTime: originalLocalDateTime,
      ),
    );
  }

  Future<void> move({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
    required RecurrenceLocalDateTime movedToLocalDateTime,
  }) {
    return _writeException(
      taskId: taskId,
      exception: RecurrenceException.move(
        originalLocalDateTime: originalLocalDateTime,
        movedToLocalDateTime: movedToLocalDateTime,
      ),
    );
  }

  Future<void> moveToDeviceLocal({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
    required DateTime movedGregorianLocal,
  }) async {
    if (movedGregorianLocal.isUtc) {
      throw ArgumentError.value(
        movedGregorianLocal,
        'movedGregorianLocal',
        'Moved occurrence must be supplied as local time.',
      );
    }
    final bundle = await _repository.getByTask(taskId);
    final rule = bundle.rule;
    if (rule == null) {
      throw StateError('Task recurrence rule was not found.');
    }

    final moved = switch (rule.rule.calendar) {
      RecurrenceCalendar.gregorian => RecurrenceLocalDateTime(
        year: movedGregorianLocal.year,
        month: movedGregorianLocal.month,
        day: movedGregorianLocal.day,
        hour: movedGregorianLocal.hour,
        minute: movedGregorianLocal.minute,
      ),
      RecurrenceCalendar.jalali => _jalaliLocal(movedGregorianLocal),
    };

    await move(
      taskId: taskId,
      originalLocalDateTime: originalLocalDateTime,
      movedToLocalDateTime: moved,
    );
  }

  Future<void> restore({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) async {
    await _repository.deleteException(
      taskId: taskId,
      originalLocalDateTime: originalLocalDateTime,
    );
    await _notifyChanged(taskId);
  }

  Future<void> setCompleted({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
    required bool completed,
  }) async {
    if (!completed) {
      await _repository.clearCompletion(
        taskId: taskId,
        originalLocalDateTime: originalLocalDateTime,
      );
      await _notifyChanged(taskId);
      return;
    }

    final now = _nowUtc().toUtc();
    final bundle = await _repository.getByTask(taskId);
    TaskOccurrenceCompletion? existing;
    for (final item in bundle.completions) {
      if (item.originalLocalDateTime == originalLocalDateTime) {
        existing = item;
        break;
      }
    }

    await _repository.setCompletion(
      TaskOccurrenceCompletion(
        taskId: taskId,
        originalLocalDateTime: originalLocalDateTime,
        completedAtUtc: now,
        createdAtUtc: existing?.createdAtUtc ?? now,
        updatedAtUtc: now,
      ),
    );
    await _notifyChanged(taskId);
  }

  Future<void> _writeException({
    required String taskId,
    required RecurrenceException exception,
  }) async {
    final now = _nowUtc().toUtc();
    final bundle = await _repository.getByTask(taskId);
    TaskRecurrenceException? existing;
    for (final item in bundle.exceptions) {
      if (item.exception.originalLocalDateTime ==
          exception.originalLocalDateTime) {
        existing = item;
        break;
      }
    }

    await _repository.upsertException(
      TaskRecurrenceException(
        id: existing?.id ?? _nextId(),
        taskId: taskId,
        exception: exception,
        createdAtUtc: existing?.createdAtUtc ?? now,
        updatedAtUtc: now,
      ),
    );
    await _notifyChanged(taskId);
  }

  Future<void> _notifyChanged(String taskId) async {
    final callback = _onChanged;
    if (callback != null) {
      await callback(taskId);
    }
  }
}

RecurrenceLocalDateTime _jalaliLocal(DateTime value) {
  final jalali = Jalali.fromDateTime(value);
  return RecurrenceLocalDateTime(
    year: jalali.year,
    month: jalali.month,
    day: jalali.day,
    hour: value.hour,
    minute: value.minute,
  );
}
