import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskTimeEntry', () {
    final start = DateTime.utc(2026, 8, 6, 8);

    test(
      'running timer derives elapsed time from persisted UTC resume point',
      () {
        final entry = TaskTimeEntry.running(
          id: 'timer-1',
          taskId: 'task-1',
          startedAtUtc: start,
        );

        expect(entry.isRunning, isTrue);
        expect(entry.activeSlot, 1);
        expect(
          entry.elapsedSecondsAt(start.add(const Duration(seconds: 75))),
          75,
        );
      },
    );

    test('pause freezes elapsed seconds and clears resume point', () {
      final paused = TaskTimeEntry.running(
        id: 'timer-1',
        taskId: 'task-1',
        startedAtUtc: start,
      ).pause(start.add(const Duration(seconds: 90)));

      expect(paused.state, TaskTimerState.paused);
      expect(paused.lastResumedAtUtc, isNull);
      expect(paused.accumulatedSeconds, 90);
      expect(paused.elapsedSecondsAt(start.add(const Duration(hours: 3))), 90);
    });

    test('resume and stop preserve accumulated intervals', () {
      final paused = TaskTimeEntry.running(
        id: 'timer-1',
        taskId: 'task-1',
        startedAtUtc: start,
      ).pause(start.add(const Duration(seconds: 60)));
      final resumed = paused.resume(start.add(const Duration(minutes: 5)));
      final stopped = resumed.stop(start.add(const Duration(minutes: 7)));

      expect(stopped.state, TaskTimerState.stopped);
      expect(stopped.activeSlot, isNull);
      expect(stopped.endedAtUtc, start.add(const Duration(minutes: 7)));
      expect(stopped.accumulatedSeconds, 180);
    });

    test('manual entry normalizes note and exact duration', () {
      final entry = TaskTimeEntry.manual(
        id: 'manual-1',
        taskId: 'task-1',
        startedAtUtc: start,
        endedAtUtc: start.add(const Duration(minutes: 45)),
        savedAtUtc: start.add(const Duration(hours: 1)),
        note: '  جلسه طراحی  ',
      );

      expect(entry.isManual, isTrue);
      expect(entry.note, 'جلسه طراحی');
      expect(entry.accumulatedSeconds, 2700);
    });

    test('manual update keeps identity and created timestamp', () {
      final original = TaskTimeEntry.manual(
        id: 'manual-1',
        taskId: 'task-1',
        startedAtUtc: start,
        endedAtUtc: start.add(const Duration(minutes: 30)),
        savedAtUtc: start.add(const Duration(hours: 1)),
      );
      final updated = original.updateManual(
        startedAtUtc: start.add(const Duration(minutes: 10)),
        endedAtUtc: start.add(const Duration(minutes: 50)),
        savedAtUtc: start.add(const Duration(hours: 2)),
        note: 'اصلاح‌شده',
      );

      expect(updated.id, original.id);
      expect(updated.createdAtUtc, original.createdAtUtc);
      expect(updated.accumulatedSeconds, 2400);
      expect(updated.note, 'اصلاح‌شده');
    });

    test('rejects local timestamps', () {
      expect(
        () => TaskTimeEntry.running(
          id: 'timer-1',
          taskId: 'task-1',
          startedAtUtc: DateTime(2026, 8, 6, 8),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects inconsistent running lifecycle', () {
      expect(
        () => TaskTimeEntry(
          id: 'timer-1',
          taskId: 'task-1',
          source: TaskTimeEntrySource.timer,
          state: TaskTimerState.running,
          startedAtUtc: start,
          accumulatedSeconds: 0,
          createdAtUtc: start,
          updatedAtUtc: start,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('storage enums parse canonical values and reject unknown values', () {
      expect(
        TaskTimeEntrySource.parseStorage('manual'),
        TaskTimeEntrySource.manual,
      );
      expect(TaskTimerState.parseStorage('paused'), TaskTimerState.paused);
      expect(
        () => TaskTimerState.parseStorage('sleeping'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
