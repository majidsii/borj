import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create mode starts with empty optional fields and supplied priority',
    () {
      final draft = TaskDetailsDraft.create(
        nowLocal: DateTime(2026, 8, 4, 9),
        priority: 2,
      );

      expect(draft.title, isEmpty);
      expect(draft.description, isEmpty);
      expect(draft.priority, 2);
      expect(draft.startLocal, isNull);
      expect(draft.dueLocal, isNull);
      expect(draft.estimatedHours, 0);
      expect(draft.estimatedMinutes, 0);
      final errors = draft.validate();
      expect(errors.keys, <TaskDetailsField>[TaskDetailsField.title]);
      expect(errors[TaskDetailsField.title], isNotEmpty);
    },
  );

  test('edit mode converts UTC fields to local and splits duration', () {
    final task = TaskItem(
      id: 'task-edit',
      displayNumber: 27,
      title: 'کار موجود',
      description: 'توضیح موجود',
      priority: 3,
      status: TaskStatus.inProgress,
      positionInStatus: 4,
      startAtUtc: DateTime.utc(2026, 8, 10, 5, 15),
      dueAtUtc: DateTime.utc(2026, 8, 10, 8, 45),
      estimatedDurationMinutes: 195,
      createdAtUtc: DateTime.utc(2026, 8, 1, 8),
      updatedAtUtc: DateTime.utc(2026, 8, 2, 9),
    );

    final draft = TaskDetailsDraft.fromTask(task);

    expect(draft.title, task.title);
    expect(draft.description, task.description);
    expect(draft.priority, task.priority);
    expect(draft.startLocal, task.startAtUtc!.toLocal());
    expect(draft.startLocal!.isUtc, isFalse);
    expect(draft.dueLocal, task.dueAtUtc!.toLocal());
    expect(draft.dueLocal!.isUtc, isFalse);
    expect(draft.estimatedHours, 3);
    expect(draft.estimatedMinutes, 15);
  });

  test('new projection normalizes text local time and duration', () {
    final startLocal = DateTime(2026, 8, 11, 9, 30);
    final dueLocal = DateTime(2026, 8, 11, 11);
    final savedAtUtc = DateTime.utc(2026, 8, 4, 10);

    final draft = TaskDetailsDraft(
      title: '  برنامه‌ریزی انتشار  ',
      description: '   ',
      priority: 2,
      startLocal: startLocal,
      dueLocal: dueLocal,
      estimatedHours: 1,
      estimatedMinutes: 30,
    );

    final task = draft.buildNewTask(id: 'task-new', savedAtUtc: savedAtUtc);

    expect(task.id, 'task-new');
    expect(task.displayNumber, 1);
    expect(task.title, 'برنامه‌ریزی انتشار');
    expect(task.description, isNull);
    expect(task.priority, 2);
    expect(task.status, TaskStatus.planned);
    expect(task.positionInStatus, 0);
    expect(task.startAtUtc, startLocal.toUtc());
    expect(task.startAtUtc!.isUtc, isTrue);
    expect(task.dueAtUtc, dueLocal.toUtc());
    expect(task.dueAtUtc!.isUtc, isTrue);
    expect(task.estimatedDurationMinutes, 90);
    expect(task.createdAtUtc, savedAtUtc);
    expect(task.updatedAtUtc, savedAtUtc);
    expect(task.completedAtUtc, isNull);
    expect(task.canceledAtUtc, isNull);
  });

  test('due before start maps only to the due field', () {
    final draft = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 4, 9))
      ..title = 'کار'
      ..startLocal = DateTime(2026, 8, 10, 12)
      ..dueLocal = DateTime(2026, 8, 10, 11, 59);

    final errors = draft.validate();

    expect(errors.keys, <TaskDetailsField>[TaskDetailsField.dueAt]);
    expect(errors[TaskDetailsField.dueAt], isNotEmpty);
  });

  test(
    'duration uses explicit non-negative hours and minute range 0 to 59',
    () {
      final emptyDuration = TaskDetailsDraft.create(
        nowLocal: DateTime(2026, 8, 4, 9),
      )..title = 'کار';

      final withoutDuration = emptyDuration.buildNewTask(
        id: 'without-duration',
        savedAtUtc: DateTime.utc(2026, 8, 4, 10),
      );
      expect(withoutDuration.estimatedDurationMinutes, isNull);

      for (final values in <(int, int)>[(0, -1), (0, 60), (1, 75), (-1, 0)]) {
        final draft = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 4, 9))
          ..title = 'کار'
          ..estimatedHours = values.$1
          ..estimatedMinutes = values.$2;

        final errors = draft.validate();

        expect(
          errors.keys,
          contains(TaskDetailsField.estimatedDuration),
          reason: 'hours=${values.$1}, minutes=${values.$2}',
        );
      }

      final valid = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 4, 9))
        ..title = 'کار'
        ..estimatedHours = 1
        ..estimatedMinutes = 59;

      expect(valid.validate(), isEmpty);
      expect(
        valid
            .buildNewTask(
              id: 'valid-duration',
              savedAtUtc: DateTime.utc(2026, 8, 4, 10),
            )
            .estimatedDurationMinutes,
        119,
      );
    },
  );

  test('blank title is a field error and blocks projection', () {
    final draft = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 4, 9))
      ..title = '   ';

    expect(draft.validate().keys, contains(TaskDetailsField.title));
    expect(
      () => draft.buildNewTask(
        id: 'invalid',
        savedAtUtc: DateTime.utc(2026, 8, 4, 10),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('update projection preserves identity workflow order and terminals', () {
    final completedAtUtc = DateTime.utc(2026, 8, 3, 14);
    final existing = TaskItem(
      id: 'task-completed',
      displayNumber: 71,
      title: 'عنوان قدیمی',
      description: 'شرح قدیمی',
      priority: 1,
      status: TaskStatus.completed,
      positionInStatus: 6,
      startAtUtc: DateTime.utc(2026, 8, 2, 8),
      dueAtUtc: DateTime.utc(2026, 8, 2, 9),
      estimatedDurationMinutes: 60,
      createdAtUtc: DateTime.utc(2026, 8, 1, 7),
      updatedAtUtc: completedAtUtc,
      completedAtUtc: completedAtUtc,
    );
    final savedAtUtc = DateTime.utc(2026, 8, 4, 11);
    final startLocal = DateTime(2026, 8, 12, 10);
    final dueLocal = DateTime(2026, 8, 12, 13, 45);

    final draft = TaskDetailsDraft.fromTask(existing)
      ..title = '  عنوان تازه  '
      ..description = '  شرح تازه  '
      ..priority = 3
      ..startLocal = startLocal
      ..dueLocal = dueLocal
      ..estimatedHours = 3
      ..estimatedMinutes = 45;

    final updated = draft.applyTo(task: existing, savedAtUtc: savedAtUtc);

    expect(updated.id, existing.id);
    expect(updated.displayNumber, existing.displayNumber);
    expect(updated.createdAtUtc, existing.createdAtUtc);
    expect(updated.status, existing.status);
    expect(updated.positionInStatus, existing.positionInStatus);
    expect(updated.completedAtUtc, existing.completedAtUtc);
    expect(updated.canceledAtUtc, existing.canceledAtUtc);
    expect(updated.title, 'عنوان تازه');
    expect(updated.description, 'شرح تازه');
    expect(updated.priority, 3);
    expect(updated.startAtUtc, startLocal.toUtc());
    expect(updated.dueAtUtc, dueLocal.toUtc());
    expect(updated.estimatedDurationMinutes, 225);
    expect(updated.updatedAtUtc, savedAtUtc);
  });

  test('update projection explicitly clears every optional planning field', () {
    final existing = TaskItem(
      id: 'task-clear',
      displayNumber: 19,
      title: 'کار',
      description: 'شرح',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 2,
      startAtUtc: DateTime.utc(2026, 8, 10, 8),
      dueAtUtc: DateTime.utc(2026, 8, 10, 10),
      estimatedDurationMinutes: 120,
      createdAtUtc: DateTime.utc(2026, 8, 1, 7),
      updatedAtUtc: DateTime.utc(2026, 8, 1, 8),
    );

    final draft = TaskDetailsDraft.fromTask(existing)
      ..description = '   '
      ..startLocal = null
      ..dueLocal = null
      ..estimatedHours = 0
      ..estimatedMinutes = 0;

    final cleared = draft.applyTo(
      task: existing,
      savedAtUtc: DateTime.utc(2026, 8, 4, 12),
    );

    expect(cleared.description, isNull);
    expect(cleared.startAtUtc, isNull);
    expect(cleared.dueAtUtc, isNull);
    expect(cleared.estimatedDurationMinutes, isNull);
    expect(cleared.id, existing.id);
    expect(cleared.displayNumber, existing.displayNumber);
    expect(cleared.createdAtUtc, existing.createdAtUtc);
    expect(cleared.status, existing.status);
    expect(cleared.positionInStatus, existing.positionInStatus);
  });
}
