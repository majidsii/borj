import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
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
  TaskStatus status = TaskStatus.planned,
}) {
  final t = DateTime.utc(2026, 11, 1);
  return TaskItem(
    id: id,
    displayNumber: id.hashCode & 0xffff,
    title: 'task $id',
    priority: 0,
    status: status,
    positionInStatus: 0,
    startAtUtc: startUtc,
    dueAtUtc: dueUtc,
    estimatedDurationMinutes: minutes,
    createdAtUtc: t,
    updatedAtUtc: t,
    completedAtUtc: status == TaskStatus.completed ? t : null,
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
    DateTime? at,
  }) => TodayAgendaBuilderTestHelper(
    builder.build(
      tasks: tasks,
      rules: rules,
      exceptions: const [],
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

  test(
    'untimed active one-offs; completed or canceled untimed are left out',
    () {
      final a = agenda([
        _task('free'),
        _task('freeDone', status: TaskStatus.completed),
        _task('freeCanceled', status: TaskStatus.canceled),
      ]);
      expect(a.untimedIds, ['free']);
    },
  );

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
}

final class TodayAgendaBuilderTestHelper {
  TodayAgendaBuilderTestHelper(this.value);
  final TodayAgenda value;
  List<String> get timedIds => [for (final e in value.timed) e.taskId];
  List<String> get untimedIds => [for (final e in value.untimed) e.taskId];
}
