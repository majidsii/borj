import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 26, 10);
  final updatedAt = DateTime.utc(2026, 7, 26, 11);

  TaskItem plannedTask({
    int displayNumber = 7,
    String title = 'کار',
    int priority = 1,
    int positionInStatus = 0,
  }) {
    return TaskItem(
      id: 'task-1',
      displayNumber: displayNumber,
      title: title,
      priority: priority,
      status: TaskStatus.planned,
      positionInStatus: positionInStatus,
      createdAtUtc: createdAt,
      updatedAtUtc: updatedAt,
    );
  }

  test('keeps canonical v2 fields and compatibility getters', () {
    final task = plannedTask(
      displayNumber: 42,
      title: '  خرید روزانه  ',
      priority: 2,
      positionInStatus: 4,
    );

    expect(task.id, 'task-1');
    expect(task.displayNumber, 42);
    expect(task.title, 'خرید روزانه');
    expect(task.priority, 2);
    expect(task.status, TaskStatus.planned);
    expect(task.positionInStatus, 4);
    expect(task.createdAtUtc, createdAt);
    expect(task.updatedAtUtc, updatedAt);
    expect(task.completedAtUtc, isNull);
    expect(task.canceledAtUtc, isNull);
    expect(task.isDone, isFalse);
    expect(task.isActive, isTrue);
    expect(task.sortOrder, 4);
  });

  test('rejects invalid identity number priority and position', () {
    expect(
      () => TaskItem(
        id: '   ',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(() => plannedTask(title: '   '), throwsA(isA<ValidationFailure>()));
    for (final value in <int>[0, -1]) {
      expect(
        () => plannedTask(displayNumber: value),
        throwsA(isA<ValidationFailure>()),
      );
    }
    for (final value in <int>[-1, 4]) {
      expect(
        () => plannedTask(priority: value),
        throwsA(isA<ValidationFailure>()),
      );
    }
    expect(
      () => plannedTask(positionInStatus: -1),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('rejects local timestamps in canonical timestamp fields', () {
    final local = DateTime(2026, 7, 26, 12);

    for (final build in <TaskItem Function()>[
      () => TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: local,
        updatedAtUtc: updatedAt,
      ),
      () => TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: local,
      ),
      () => TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.completed,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
        completedAtUtc: local,
      ),
      () => TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار',
        priority: 1,
        status: TaskStatus.canceled,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
        canceledAtUtc: local,
      ),
    ]) {
      expect(build, throwsA(isA<ValidationFailure>()));
    }
  });

  test('enforces terminal timestamps for every status', () {
    final terminalAt = DateTime.utc(2026, 7, 26, 12);

    final completed = TaskItem(
      id: 'task-completed',
      displayNumber: 1,
      title: 'تمام',
      priority: 1,
      status: TaskStatus.completed,
      positionInStatus: 0,
      createdAtUtc: createdAt,
      updatedAtUtc: terminalAt,
      completedAtUtc: terminalAt,
    );
    final canceled = TaskItem(
      id: 'task-canceled',
      displayNumber: 2,
      title: 'لغو',
      priority: 1,
      status: TaskStatus.canceled,
      positionInStatus: 0,
      createdAtUtc: createdAt,
      updatedAtUtc: terminalAt,
      canceledAtUtc: terminalAt,
    );

    expect(completed.isDone, isTrue);
    expect(completed.isActive, isFalse);
    expect(canceled.isDone, isFalse);
    expect(canceled.isActive, isFalse);

    expect(
      () => TaskItem(
        id: 'missing-completion',
        displayNumber: 3,
        title: 'کار',
        priority: 1,
        status: TaskStatus.completed,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: terminalAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => TaskItem(
        id: 'missing-cancel',
        displayNumber: 4,
        title: 'کار',
        priority: 1,
        status: TaskStatus.canceled,
        positionInStatus: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: terminalAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );

    for (final status in <TaskStatus>[
      TaskStatus.planned,
      TaskStatus.inProgress,
    ]) {
      expect(
        () => TaskItem(
          id: 'active-$status',
          displayNumber: 5,
          title: 'کار',
          priority: 1,
          status: status,
          positionInStatus: 0,
          createdAtUtc: createdAt,
          updatedAtUtc: terminalAt,
          completedAtUtc: terminalAt,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    }
  });

  test('copyWith transitions and preserves immutable fields', () {
    final task = plannedTask(displayNumber: 91);
    final completedAt = DateTime.utc(2026, 7, 26, 12);
    final reopenedAt = DateTime.utc(2026, 7, 26, 13);
    final canceledAt = DateTime.utc(2026, 7, 26, 14);
    final restartedAt = DateTime.utc(2026, 7, 26, 15);

    final completed = task.copyWith(
      status: TaskStatus.completed,
      positionInStatus: 3,
      updatedAtUtc: completedAt,
      completedAtUtc: completedAt,
    );
    final reopened = completed.copyWith(
      status: TaskStatus.planned,
      updatedAtUtc: reopenedAt,
      clearCompletedAt: true,
    );
    final canceled = reopened.copyWith(
      status: TaskStatus.canceled,
      updatedAtUtc: canceledAt,
      canceledAtUtc: canceledAt,
    );
    final restarted = canceled.copyWith(
      status: TaskStatus.inProgress,
      title: 'عنوان تازه',
      priority: 3,
      updatedAtUtc: restartedAt,
      clearCanceledAt: true,
    );

    expect(completed.completedAtUtc, completedAt);
    expect(reopened.completedAtUtc, isNull);
    expect(canceled.canceledAtUtc, canceledAt);
    expect(restarted.canceledAtUtc, isNull);
    expect(restarted.status, TaskStatus.inProgress);
    expect(restarted.isActive, isTrue);
    expect(restarted.id, task.id);
    expect(restarted.displayNumber, 91);
    expect(restarted.createdAtUtc, task.createdAtUtc);
    expect(restarted.positionInStatus, 3);
    expect(restarted.sortOrder, 3);
    expect(restarted.title, 'عنوان تازه');
    expect(restarted.priority, 3);
  });

  test('equality and hash include canonical v2 state', () {
    final first = plannedTask();
    final equal = plannedTask();
    final differentStatus = TaskItem(
      id: first.id,
      displayNumber: first.displayNumber,
      title: first.title,
      priority: first.priority,
      status: TaskStatus.inProgress,
      positionInStatus: first.positionInStatus,
      createdAtUtc: first.createdAtUtc,
      updatedAtUtc: first.updatedAtUtc,
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(differentStatus));
  });

  // Task 2.2 Gate 2.2.1 RED
  group('task planning fields', () {
    test('normalizes and keeps canonical planning fields', () {
      final task = TaskItem(
        id: 'planning-task',
        displayNumber: 12,
        title: '  برنامه‌ریزی انتشار  ',
        description: '  توضیح چندخطی\nبرای انتشار  ',
        priority: 2,
        status: TaskStatus.planned,
        positionInStatus: 0,
        startAtUtc: DateTime.utc(2026, 8, 4, 8),
        dueAtUtc: DateTime.utc(2026, 8, 4, 10),
        estimatedDurationMinutes: 90,
        createdAtUtc: DateTime.utc(2026, 8, 3, 12),
        updatedAtUtc: DateTime.utc(2026, 8, 3, 12),
      );

      expect(task.title, 'برنامه‌ریزی انتشار');
      expect(task.description, 'توضیح چندخطی\nبرای انتشار');
      expect(task.startAtUtc, DateTime.utc(2026, 8, 4, 8));
      expect(task.dueAtUtc, DateTime.utc(2026, 8, 4, 10));
      expect(task.estimatedDurationMinutes, 90);
    });

    test('normalizes a blank description to null', () {
      final task = plannedTask().copyWith(description: '   ');
      expect(task.description, isNull);
    });

    test('rejects non-UTC planning timestamps', () {
      final local = DateTime(2026, 8, 4, 8);

      expect(
        () => plannedTask().copyWith(startAtUtc: local),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => plannedTask().copyWith(dueAtUtc: local),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects a due time before the start time', () {
      expect(
        () => plannedTask().copyWith(
          startAtUtc: DateTime.utc(2026, 8, 4, 10),
          dueAtUtc: DateTime.utc(2026, 8, 4, 9, 59),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('allows equal start and due instants', () {
      final instant = DateTime.utc(2026, 8, 4, 10);
      final task = plannedTask().copyWith(
        startAtUtc: instant,
        dueAtUtc: instant,
      );

      expect(task.startAtUtc, instant);
      expect(task.dueAtUtc, instant);
    });

    test('requires a positive estimated duration', () {
      for (final value in <int>[0, -1]) {
        expect(
          () => plannedTask().copyWith(estimatedDurationMinutes: value),
          throwsA(isA<ValidationFailure>()),
        );
      }

      expect(
        plannedTask()
            .copyWith(estimatedDurationMinutes: 1)
            .estimatedDurationMinutes,
        1,
      );
    });

    test('copyWith explicitly clears every optional planning field', () {
      final task = plannedTask().copyWith(
        description: 'توضیح',
        startAtUtc: DateTime.utc(2026, 8, 4, 8),
        dueAtUtc: DateTime.utc(2026, 8, 4, 10),
        estimatedDurationMinutes: 90,
      );

      final cleared = task.copyWith(
        clearDescription: true,
        clearStartAt: true,
        clearDueAt: true,
        clearEstimatedDuration: true,
        updatedAtUtc: DateTime.utc(2026, 8, 3, 13),
      );

      expect(cleared.description, isNull);
      expect(cleared.startAtUtc, isNull);
      expect(cleared.dueAtUtc, isNull);
      expect(cleared.estimatedDurationMinutes, isNull);
      expect(cleared.id, task.id);
      expect(cleared.displayNumber, task.displayNumber);
      expect(cleared.createdAtUtc, task.createdAtUtc);
      expect(cleared.status, task.status);
      expect(cleared.positionInStatus, task.positionInStatus);
    });

    test('equality and hash include planning fields', () {
      final base = plannedTask();
      final withDescription = base.copyWith(description: 'توضیح');
      final withStart = base.copyWith(startAtUtc: DateTime.utc(2026, 8, 4, 8));
      final withDue = base.copyWith(dueAtUtc: DateTime.utc(2026, 8, 4, 10));
      final withDuration = base.copyWith(estimatedDurationMinutes: 30);

      expect(base, isNot(withDescription));
      expect(base, isNot(withStart));
      expect(base, isNot(withDue));
      expect(base, isNot(withDuration));
      expect(base.hashCode, isNot(withDescription.hashCode));
    });
  });
}
