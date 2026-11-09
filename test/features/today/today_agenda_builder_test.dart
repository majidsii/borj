import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

const _tz = 'Asia/Tehran';

TaskItem _task(
  String id, {
  DateTime? startUtc,
  DateTime? dueUtc,
  int? minutes,
  int? number,
  TaskStatus status = TaskStatus.planned,
  DateTime? completedUtc,
}) {
  final t = DateTime.utc(2026, 11, 1);
  return TaskItem(
    id: id,
    displayNumber: number ?? (id.hashCode & 0xffff) + 1,
    title: 'task $id',
    priority: 0,
    status: status,
    positionInStatus: 0,
    startAtUtc: startUtc,
    dueAtUtc: dueUtc,
    estimatedDurationMinutes: minutes,
    createdAtUtc: t,
    updatedAtUtc: t,
    completedAtUtc: status == TaskStatus.completed ? (completedUtc ?? t) : null,
    canceledAtUtc: status == TaskStatus.canceled ? t : null,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);
  const builder = TodayAgendaBuilder();
  // 2026-11-04 14:30 Tehran (UTC+3:30) = 11:00 UTC.
  final nowUtc = DateTime.utc(2026, 11, 4, 11, 0);
  // The same instant as the task calendar zone's wall clock.
  final wallNow = DateTime(2026, 11, 4, 14, 30);

  TodayAgendaBuilderTestHelper agenda(
    List<TaskItem> tasks, {
    List<TaskRecurrenceRule> rules = const [],
    List<TaskOccurrenceCompletion> completions = const [],
    List<TaskRecurrenceException> exceptions = const [],
    DateTime? at,
  }) => TodayAgendaBuilderTestHelper(
    builder.build(
      tasks: tasks,
      rules: rules,
      exceptions: exceptions,
      completions: completions,
      nowUtc: at ?? nowUtc,
      timeZoneId: _tz,
    ),
  );

  test('timed entries of the local day, sorted by time', () {
    final a = agenda([
      _task('late', dueUtc: DateTime.utc(2026, 11, 4, 14, 30)), // 18:00 local
      _task(
        'early',
        startUtc: DateTime.utc(2026, 11, 4, 5, 30),
        minutes: 60,
      ), // 09:00
      _task('tomorrow', dueUtc: DateTime.utc(2026, 11, 4, 21, 0)), // 00:30 next
      _task(
        'yesterday',
        dueUtc: DateTime.utc(2026, 11, 3, 19, 0),
      ), // 22:30 prev
    ]);
    expect(a.timedIds, ['early', 'late']);
    expect(a.value.timed.first.localStart, DateTime(2026, 11, 4, 9, 0));
    expect(a.value.timed.first.durationMinutes, 60);
  });

  test('untimed: active and completed-today stay (done); completed earlier or '
      'canceled are left out', () {
    final a = agenda([
      _task('free'),
      // 2026-11-04 00:30 Tehran = 2026-11-03 21:00 UTC: today.
      _task(
        'doneToday',
        status: TaskStatus.completed,
        completedUtc: DateTime.utc(2026, 11, 3, 21, 0),
      ),
      // 23:59 Tehran on the 3rd: yesterday.
      _task(
        'doneYesterday',
        status: TaskStatus.completed,
        completedUtc: DateTime.utc(2026, 11, 3, 20, 29),
      ),
      _task('freeCanceled', status: TaskStatus.canceled),
    ]);
    expect(a.untimedIds, ['free', 'doneToday']);
    expect(a.value.untimed.map((e) => e.done), [false, true]);
  });

  test('a completed one-off today stays, marked done; canceled is dropped', () {
    final a = agenda([
      _task(
        'done',
        dueUtc: DateTime.utc(2026, 11, 4, 6, 0),
        status: TaskStatus.completed,
      ),
      _task(
        'gone',
        dueUtc: DateTime.utc(2026, 11, 4, 7, 0),
        status: TaskStatus.canceled,
      ),
    ]);
    expect(a.timedIds, ['done']);
    expect(a.value.timed.single.done, isTrue);
  });

  test('nextAfter: first unfinished timed entry at or after now', () {
    final a = agenda([
      _task('past', dueUtc: DateTime.utc(2026, 11, 4, 8, 0)), // 11:30
      _task('next', dueUtc: DateTime.utc(2026, 11, 4, 11, 30)), // 15:00
      _task('later', dueUtc: DateTime.utc(2026, 11, 4, 14, 30)), // 18:00
    ]);
    expect(a.value.nextAfter(wallNow)?.taskId, 'next');
  });

  test('nextAfter skips done entries and includes an entry starting now', () {
    final a = agenda([
      _task(
        'doneNow',
        dueUtc: DateTime.utc(2026, 11, 4, 11, 0), // 14:30
        status: TaskStatus.completed,
      ),
      _task('atNow', dueUtc: DateTime.utc(2026, 11, 4, 11, 0)), // 14:30
    ]);
    expect(a.value.nextAfter(wallNow)?.taskId, 'atNow');
    expect(a.value.nextAfter(DateTime(2026, 11, 4, 14, 31)), isNull);
  });

  test('the day follows the task calendar zone, not UTC', () {
    // 22:00 UTC on Nov 3 is 01:30 on Nov 4 in Tehran.
    final a = agenda(
      [_task('t', dueUtc: DateTime.utc(2026, 11, 4, 5, 0))], // 08:30 Nov 4
      at: DateTime.utc(2026, 11, 3, 22, 0),
    );
    expect(a.value.day, DateTime(2026, 11, 4));
    expect(a.timedIds, ['t']);
  });

  test('empty agenda', () {
    final a = agenda(const []);
    expect(a.value.isEmpty, isTrue);
    expect(a.value.day, DateTime(2026, 11, 4));
  });

  test('recurring occurrence today carries its key and completion', () {
    final task = _task(
      'rec',
      startUtc: DateTime.utc(2026, 11, 1, 5, 30), // 09:00 Tehran
    );
    final today9 = RecurrenceLocalDateTime(
      year: 2026,
      month: 11,
      day: 4,
      hour: 9,
    );
    final t = DateTime.utc(2026, 11, 1);
    final rule = TaskRecurrenceRule(
      id: 'rule',
      taskId: task.id,
      rule: RecurrenceRule.daily(
        anchorLocalDateTime: RecurrenceLocalDateTime(
          year: 2026,
          month: 11,
          day: 1,
          hour: 9,
        ),
        timeZone: const RecurrenceTimeZone.floating(),
      ),
      createdAtUtc: t,
      updatedAtUtc: t,
    );
    final completion = TaskOccurrenceCompletion(
      taskId: task.id,
      originalLocalDateTime: today9,
      completedAtUtc: nowUtc,
      createdAtUtc: nowUtc,
      updatedAtUtc: nowUtc,
    );

    final a = agenda([task], rules: [rule], completions: [completion]);
    final e = a.value.timed.single;
    expect(e.recurring, isTrue);
    expect(e.done, isTrue);
    expect(e.originalLocalDateTime, today9);
    expect(e.localStart, DateTime(2026, 11, 4, 9, 0));
    expect(a.untimedIds, isEmpty);

    // Without the completion the same entry is not done.
    final open = agenda([task], rules: [rule]);
    expect(open.value.timed.single.done, isFalse);
  });

  test('equal start times order by displayNumber, then taskId', () {
    final due = DateTime.utc(2026, 11, 4, 6, 0); // 09:30
    final a = agenda(
      [
        _task('b', dueUtc: due, number: 7),
        _task('a', dueUtc: due, number: 7),
        _task('z', dueUtc: due, number: 5),
        _task('first', dueUtc: due, number: 2),
      ].reversed.toList(),
    );
    expect(a.timedIds, ['first', 'z', 'a', 'b']);
  });

  test('00:00 and 23:59 local are in; next-day 00:00 is out', () {
    final a = agenda([
      _task('mid', dueUtc: DateTime.utc(2026, 11, 3, 20, 30)), // 00:00 Nov 4
      _task('last', dueUtc: DateTime.utc(2026, 11, 4, 20, 29)), // 23:59
      _task('next', dueUtc: DateTime.utc(2026, 11, 4, 20, 30)), // 00:00 Nov 5
      _task('before', dueUtc: DateTime.utc(2026, 11, 3, 20, 29)), // 23:59 Nov 3
    ]);
    expect(a.timedIds, ['mid', 'last']);
    expect(a.value.timed.first.localStart, DateTime(2026, 11, 4, 0, 0));
    expect(a.value.timed.last.localStart, DateTime(2026, 11, 4, 23, 59));
  });

  group('recurrence exceptions', () {
    final created = DateTime.utc(2026, 11, 1);
    final task = _task(
      'rec',
      startUtc: DateTime.utc(2026, 11, 1, 5, 30), // 09:00 Tehran
    );
    final rule = TaskRecurrenceRule(
      id: 'rule',
      taskId: 'rec',
      rule: RecurrenceRule.daily(
        anchorLocalDateTime: RecurrenceLocalDateTime(
          year: 2026,
          month: 11,
          day: 1,
          hour: 9,
        ),
        timeZone: const RecurrenceTimeZone.floating(),
      ),
      createdAtUtc: created,
      updatedAtUtc: created,
    );
    TaskRecurrenceException exception(RecurrenceException e) =>
        TaskRecurrenceException(
          id: 'ex',
          taskId: 'rec',
          exception: e,
          createdAtUtc: created,
          updatedAtUtc: created,
        );
    RecurrenceLocalDateTime at(int day, int hour) =>
        RecurrenceLocalDateTime(year: 2026, month: 11, day: day, hour: hour);

    test('control: the occurrence is at 09:00 without exceptions', () {
      final a = agenda([task], rules: [rule]);
      expect(a.value.timed.single.localStart, DateTime(2026, 11, 4, 9, 0));
    });

    test('moved into today appears at its moved time', () {
      final a = agenda(
        [task],
        rules: [rule],
        exceptions: [
          exception(
            RecurrenceException.move(
              originalLocalDateTime: at(5, 9),
              movedToLocalDateTime: at(4, 16),
            ),
          ),
        ],
      );
      final starts = [for (final e in a.value.timed) e.localStart];
      expect(starts, [
        DateTime(2026, 11, 4, 9, 0),
        DateTime(2026, 11, 4, 16, 0),
      ]);
      expect(a.value.timed.last.originalLocalDateTime, at(5, 9));
    });

    test('moved out of today is absent', () {
      final a = agenda(
        [task],
        rules: [rule],
        exceptions: [
          exception(
            RecurrenceException.move(
              originalLocalDateTime: at(4, 9),
              movedToLocalDateTime: at(6, 10),
            ),
          ),
        ],
      );
      expect(a.value.timed, isEmpty);
    });

    test('same task, same minute: ordered by occurrence key', () {
      // Nov 5 09:00 is moved onto Nov 4 09:00, beside Nov 4's own 09:00.
      final moved = exception(
        RecurrenceException.move(
          originalLocalDateTime: at(5, 9),
          movedToLocalDateTime: at(4, 9),
        ),
      );
      for (final rules in [
        [rule],
        [rule].reversed.toList(),
      ]) {
        final a = agenda([task], rules: rules, exceptions: [moved]);
        expect(
          [for (final e in a.value.timed) e.originalLocalDateTime],
          [at(4, 9), at(5, 9)],
        );
      }
    });

    test('a skipped occurrence is absent', () {
      final a = agenda(
        [task],
        rules: [rule],
        exceptions: [
          exception(RecurrenceException.skip(originalLocalDateTime: at(4, 9))),
        ],
      );
      expect(a.value.timed, isEmpty);
    });
  });
}

final class TodayAgendaBuilderTestHelper {
  TodayAgendaBuilderTestHelper(this.value);
  final TodayAgenda value;
  List<String> get timedIds => [for (final e in value.timed) e.taskId];
  List<String> get untimedIds => [for (final e in value.untimed) e.taskId];
}
