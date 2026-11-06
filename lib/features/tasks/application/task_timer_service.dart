import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:borj/features/tasks/domain/task_time_repository.dart';

final class TaskTimerService {
  factory TaskTimerService({
    required TaskTimeRepository repository,
    required AppClock clock,
    required String Function() nextId,
  }) {
    return TaskTimerService._(repository, clock, nextId);
  }

  const TaskTimerService._(this._repository, this._clock, this._nextId);

  final TaskTimeRepository _repository;
  final AppClock _clock;
  final String Function() _nextId;

  Future<TaskTimeEntry> start(String taskId) async {
    final normalizedTaskId = taskId.trim();
    if (normalizedTaskId.isEmpty) {
      throw const ValidationFailure('شناسه کار برای تایمر نامعتبر است.');
    }
    if (await _repository.getActive() != null) {
      throw const ValidationFailure('ابتدا تایمر فعال فعلی را پایان دهید.');
    }
    final now = _clock.nowUtc().toUtc();
    final entry = TaskTimeEntry.running(
      id: _nextId(),
      taskId: normalizedTaskId,
      startedAtUtc: now,
    );
    await _repository.insert(entry);
    return entry;
  }

  Future<TaskTimeEntry> pause() async {
    final active = await _requireActive();
    final updated = active.pause(_clock.nowUtc().toUtc());
    await _repository.update(updated);
    return updated;
  }

  Future<TaskTimeEntry> resume() async {
    final active = await _requireActive();
    final updated = active.resume(_clock.nowUtc().toUtc());
    await _repository.update(updated);
    return updated;
  }

  Future<TaskTimeEntry> stop() async {
    final active = await _requireActive();
    final updated = active.stop(_clock.nowUtc().toUtc());
    await _repository.update(updated);
    return updated;
  }

  Future<TaskTimeEntry> addManual({
    required String taskId,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    String? note,
  }) async {
    final savedAt = _clock.nowUtc().toUtc();
    final entry = TaskTimeEntry.manual(
      id: _nextId(),
      taskId: taskId,
      startedAtUtc: startedAtUtc.toUtc(),
      endedAtUtc: endedAtUtc.toUtc(),
      savedAtUtc: savedAt,
      note: note,
    );
    await _ensureNoOverlap(entry);
    await _repository.insert(entry);
    return entry;
  }

  Future<TaskTimeEntry> addManualDuration({
    required String taskId,
    required int durationMinutes,
    String? note,
  }) {
    if (durationMinutes <= 0) {
      throw const ValidationFailure('مدت دستی باید بیشتر از صفر باشد.');
    }
    final end = _clock.nowUtc().toUtc();
    return addManual(
      taskId: taskId,
      startedAtUtc: end.subtract(Duration(minutes: durationMinutes)),
      endedAtUtc: end,
      note: note,
    );
  }

  Future<TaskTimeEntry> updateManual({
    required String id,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    String? note,
  }) async {
    final current = await _repository.getById(id);
    if (current == null) {
      throw const ValidationFailure('ثبت زمان برای ویرایش پیدا نشد.');
    }
    final updated = current.updateManual(
      startedAtUtc: startedAtUtc.toUtc(),
      endedAtUtc: endedAtUtc.toUtc(),
      savedAtUtc: _clock.nowUtc().toUtc(),
      note: note,
    );
    await _ensureNoOverlap(updated, excludingId: id);
    await _repository.update(updated);
    return updated;
  }

  Future<TaskTimeEntry> updateManualDuration({
    required String id,
    required int durationMinutes,
    String? note,
  }) async {
    if (durationMinutes <= 0) {
      throw const ValidationFailure('مدت دستی باید بیشتر از صفر باشد.');
    }
    final current = await _repository.getById(id);
    if (current == null) {
      throw const ValidationFailure('ثبت زمان برای ویرایش پیدا نشد.');
    }
    final end = current.endedAtUtc!;
    return updateManual(
      id: id,
      startedAtUtc: end.subtract(Duration(minutes: durationMinutes)),
      endedAtUtc: end,
      note: note,
    );
  }

  Future<void> delete(String id) async {
    final entry = await _repository.getById(id);
    if (entry == null) return;
    if (entry.isActive) {
      throw const ValidationFailure(
        'برای حذف، ابتدا تایمر فعال را پایان دهید.',
      );
    }
    await _repository.delete(id);
  }

  Future<TaskTimeEntry> _requireActive() async {
    final entry = await _repository.getActive();
    if (entry == null) {
      throw const ValidationFailure('هیچ تایمر فعالی وجود ندارد.');
    }
    return entry;
  }

  Future<void> _ensureNoOverlap(
    TaskTimeEntry candidate, {
    String? excludingId,
  }) async {
    final entries = await _repository.getByTask(candidate.taskId);
    for (final existing in entries) {
      if (existing.id == excludingId) continue;
      final existingEnd = existing.endedAtUtc;
      if (existingEnd == null) {
        final now = _clock.nowUtc().toUtc();
        if (_overlaps(
          candidate.startedAtUtc,
          candidate.endedAtUtc!,
          existing.startedAtUtc,
          now,
        )) {
          throw const ValidationFailure(
            'بازه ثبت دستی با تایمر فعال هم‌پوشانی دارد.',
          );
        }
        continue;
      }
      if (_overlaps(
        candidate.startedAtUtc,
        candidate.endedAtUtc!,
        existing.startedAtUtc,
        existingEnd,
      )) {
        throw const ValidationFailure(
          'بازه ثبت دستی با ثبت زمان دیگری هم‌پوشانی دارد.',
        );
      }
    }
  }
}

bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}
