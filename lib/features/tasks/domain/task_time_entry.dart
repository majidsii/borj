import 'package:borj/core/errors/app_failure.dart';

enum TaskTimeEntrySource {
  timer('timer'),
  manual('manual');

  const TaskTimeEntrySource(this.storageValue);

  final String storageValue;

  static TaskTimeEntrySource parseStorage(String value) {
    return values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () =>
          throw ValidationFailure('نوع ثبت زمان ذخیره‌شده نامعتبر است.'),
    );
  }
}

enum TaskTimerState {
  running('running'),
  paused('paused'),
  stopped('stopped');

  const TaskTimerState(this.storageValue);

  final String storageValue;

  static TaskTimerState parseStorage(String value) {
    return values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () =>
          throw ValidationFailure('وضعیت تایمر ذخیره‌شده نامعتبر است.'),
    );
  }
}

final class TaskTimeEntry {
  TaskTimeEntry({
    required this.id,
    required this.taskId,
    required this.source,
    required this.state,
    required this.startedAtUtc,
    required this.accumulatedSeconds,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.lastResumedAtUtc,
    this.endedAtUtc,
    this.activeSlot,
    String? note,
  }) : note = _normalizeOptionalText(note) {
    if (id.trim().isEmpty || taskId.trim().isEmpty) {
      throw const ValidationFailure('شناسه ثبت زمان نامعتبر است.');
    }
    for (final value in <DateTime>[
      startedAtUtc,
      createdAtUtc,
      updatedAtUtc,
      ?lastResumedAtUtc,
      ?endedAtUtc,
    ]) {
      _validateUtc(value);
    }
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure('زمان به‌روزرسانی ثبت زمان نامعتبر است.');
    }
    if (accumulatedSeconds < 0) {
      throw const ValidationFailure('مدت ثبت‌شده نمی‌تواند منفی باشد.');
    }
    if (activeSlot != null && activeSlot != 1) {
      throw const ValidationFailure('جایگاه تایمر فعال نامعتبر است.');
    }
    final end = endedAtUtc;
    if (end != null && !end.isAfter(startedAtUtc)) {
      throw const ValidationFailure('پایان ثبت زمان باید بعد از شروع آن باشد.');
    }
    _validateLifecycle();
  }

  factory TaskTimeEntry.running({
    required String id,
    required String taskId,
    required DateTime startedAtUtc,
  }) {
    return TaskTimeEntry(
      id: id,
      taskId: taskId,
      source: TaskTimeEntrySource.timer,
      state: TaskTimerState.running,
      startedAtUtc: startedAtUtc,
      lastResumedAtUtc: startedAtUtc,
      accumulatedSeconds: 0,
      activeSlot: 1,
      createdAtUtc: startedAtUtc,
      updatedAtUtc: startedAtUtc,
    );
  }

  factory TaskTimeEntry.manual({
    required String id,
    required String taskId,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required DateTime savedAtUtc,
    String? note,
  }) {
    final seconds = endedAtUtc.difference(startedAtUtc).inSeconds;
    return TaskTimeEntry(
      id: id,
      taskId: taskId,
      source: TaskTimeEntrySource.manual,
      state: TaskTimerState.stopped,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedAtUtc,
      accumulatedSeconds: seconds,
      note: note,
      createdAtUtc: savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }

  final String id;
  final String taskId;
  final TaskTimeEntrySource source;
  final TaskTimerState state;
  final DateTime startedAtUtc;
  final DateTime? lastResumedAtUtc;
  final DateTime? endedAtUtc;
  final int accumulatedSeconds;
  final int? activeSlot;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get isActive => state != TaskTimerState.stopped;
  bool get isRunning => state == TaskTimerState.running;
  bool get isPaused => state == TaskTimerState.paused;
  bool get isStopped => state == TaskTimerState.stopped;
  bool get isManual => source == TaskTimeEntrySource.manual;

  int elapsedSecondsAt(DateTime nowUtc) {
    _validateUtc(nowUtc);
    if (!isRunning) return accumulatedSeconds;
    final resumedAt = lastResumedAtUtc!;
    if (nowUtc.isBefore(resumedAt)) {
      throw const ValidationFailure(
        'زمان فعلی نمی‌تواند قبل از شروع تایمر باشد.',
      );
    }
    return accumulatedSeconds + nowUtc.difference(resumedAt).inSeconds;
  }

  Duration elapsedAt(DateTime nowUtc) {
    return Duration(seconds: elapsedSecondsAt(nowUtc));
  }

  TaskTimeEntry pause(DateTime pausedAtUtc) {
    if (!isRunning) {
      throw const ValidationFailure('فقط تایمر در حال اجرا متوقف می‌شود.');
    }
    final total = elapsedSecondsAt(pausedAtUtc);
    return _copy(
      state: TaskTimerState.paused,
      clearLastResumedAt: true,
      accumulatedSeconds: total,
      updatedAtUtc: pausedAtUtc,
    );
  }

  TaskTimeEntry resume(DateTime resumedAtUtc) {
    _validateUtc(resumedAtUtc);
    if (!isPaused) {
      throw const ValidationFailure('فقط تایمر متوقف‌شده ادامه پیدا می‌کند.');
    }
    if (resumedAtUtc.isBefore(updatedAtUtc)) {
      throw const ValidationFailure('زمان ادامه تایمر نامعتبر است.');
    }
    return _copy(
      state: TaskTimerState.running,
      lastResumedAtUtc: resumedAtUtc,
      updatedAtUtc: resumedAtUtc,
    );
  }

  TaskTimeEntry stop(DateTime stoppedAtUtc) {
    _validateUtc(stoppedAtUtc);
    if (!isActive) {
      throw const ValidationFailure('این تایمر قبلاً پایان یافته است.');
    }
    if (stoppedAtUtc.isBefore(updatedAtUtc)) {
      throw const ValidationFailure('زمان پایان تایمر نامعتبر است.');
    }
    final total = isRunning
        ? elapsedSecondsAt(stoppedAtUtc)
        : accumulatedSeconds;
    if (total <= 0) {
      throw const ValidationFailure(
        'برای پایان تایمر باید حداقل یک ثانیه ثبت شده باشد.',
      );
    }
    return _copy(
      state: TaskTimerState.stopped,
      clearLastResumedAt: true,
      endedAtUtc: stoppedAtUtc,
      accumulatedSeconds: total,
      clearActiveSlot: true,
      updatedAtUtc: stoppedAtUtc,
    );
  }

  TaskTimeEntry updateManual({
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required DateTime savedAtUtc,
    String? note,
  }) {
    if (!isManual || !isStopped) {
      throw const ValidationFailure(
        'فقط ثبت دستی پایان‌یافته قابل ویرایش است.',
      );
    }
    return TaskTimeEntry(
      id: id,
      taskId: taskId,
      source: source,
      state: state,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedAtUtc,
      accumulatedSeconds: endedAtUtc.difference(startedAtUtc).inSeconds,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }

  TaskTimeEntry _copy({
    TaskTimerState? state,
    DateTime? lastResumedAtUtc,
    bool clearLastResumedAt = false,
    DateTime? endedAtUtc,
    int? accumulatedSeconds,
    bool clearActiveSlot = false,
    DateTime? updatedAtUtc,
  }) {
    return TaskTimeEntry(
      id: id,
      taskId: taskId,
      source: source,
      state: state ?? this.state,
      startedAtUtc: startedAtUtc,
      lastResumedAtUtc: clearLastResumedAt
          ? null
          : lastResumedAtUtc ?? this.lastResumedAtUtc,
      endedAtUtc: endedAtUtc ?? this.endedAtUtc,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      activeSlot: clearActiveSlot ? null : activeSlot,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  void _validateLifecycle() {
    switch (state) {
      case TaskTimerState.running:
        if (source != TaskTimeEntrySource.timer ||
            lastResumedAtUtc == null ||
            endedAtUtc != null ||
            activeSlot != 1) {
          throw const ValidationFailure(
            'اطلاعات تایمر در حال اجرا ناسازگار است.',
          );
        }
        if (lastResumedAtUtc!.isBefore(startedAtUtc) ||
            lastResumedAtUtc!.isBefore(updatedAtUtc)) {
          throw const ValidationFailure('زمان ادامه تایمر نامعتبر است.');
        }
        break;
      case TaskTimerState.paused:
        if (source != TaskTimeEntrySource.timer ||
            lastResumedAtUtc != null ||
            endedAtUtc != null ||
            activeSlot != 1) {
          throw const ValidationFailure(
            'اطلاعات تایمر متوقف‌شده ناسازگار است.',
          );
        }
        break;
      case TaskTimerState.stopped:
        if (lastResumedAtUtc != null ||
            endedAtUtc == null ||
            activeSlot != null ||
            accumulatedSeconds <= 0) {
          throw const ValidationFailure(
            'اطلاعات ثبت زمان پایان‌یافته ناسازگار است.',
          );
        }
        if (source == TaskTimeEntrySource.manual &&
            accumulatedSeconds !=
                endedAtUtc!.difference(startedAtUtc).inSeconds) {
          throw const ValidationFailure('مدت ثبت دستی با بازه آن سازگار نیست.');
        }
        break;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskTimeEntry &&
            other.id == id &&
            other.taskId == taskId &&
            other.source == source &&
            other.state == state &&
            other.startedAtUtc == startedAtUtc &&
            other.lastResumedAtUtc == lastResumedAtUtc &&
            other.endedAtUtc == endedAtUtc &&
            other.accumulatedSeconds == accumulatedSeconds &&
            other.activeSlot == activeSlot &&
            other.note == note &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    source,
    state,
    startedAtUtc,
    lastResumedAtUtc,
    endedAtUtc,
    accumulatedSeconds,
    activeSlot,
    note,
    createdAtUtc,
    updatedAtUtc,
  );
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

void _validateUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure('زمان ثبت‌شده باید UTC باشد.');
  }
}
