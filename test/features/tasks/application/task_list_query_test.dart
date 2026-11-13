import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

const _tz = 'Asia/Tehran';

TaskItem _task(
  String id, {
  String? title,
  String? description,
  DateTime? startUtc,
  DateTime? dueUtc,
  int priority = 0,
  int number = 1,
  TaskStatus status = TaskStatus.planned,
  DateTime? createdUtc,
}) {
  final t = createdUtc ?? DateTime.utc(2026, 11, 1);
  return TaskItem(
    id: id,
    displayNumber: number,
    title: title ?? 'task $id',
    description: description,
    priority: priority,
    status: status,
    positionInStatus: 0,
    startAtUtc: startUtc,
    dueAtUtc: dueUtc,
    createdAtUtc: t,
    updatedAtUtc: t,
    completedAtUtc: status == TaskStatus.completed ? t : null,
    canceledAtUtc: status == TaskStatus.canceled ? t : null,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('taskListEntryOf: due (else start) as a Tehran wall clock', () {
    // 2026-11-13 11:30Z = 15:00 Tehran.
    final due = taskListEntryOf(
      _task('a', dueUtc: DateTime.utc(2026, 11, 13, 11, 30)),
      'Asia/Tehran',
    );
    expect(due.localInstant, DateTime.utc(2026, 11, 13, 15));
    final start = taskListEntryOf(
      _task('b', startUtc: DateTime.utc(2026, 11, 13, 20, 29)),
      'Asia/Tehran',
    );
    expect(start.localInstant, DateTime.utc(2026, 11, 13, 23, 59));
    expect(taskListEntryOf(_task('c'), 'Asia/Tehran').localInstant, isNull);
  });
  // 2026-11-04 14:30 Tehran (UTC+3:30) = 11:00 UTC.
  final now = DateTime.utc(2026, 11, 4, 11, 0);

  // Tehran wall clock -> UTC (Tehran has no DST in 2026: fixed +3:30).
  DateTime tehran(int d, int h, [int m = 0]) =>
      DateTime.utc(2026, 11, d, h, m).subtract(const Duration(minutes: 210));

  TaskListView view(
    List<TaskItem> tasks, {
    TaskSmartFilter filter = TaskSmartFilter.all,
    TaskSort sort = TaskSort.time,
    String query = '',
  }) => buildTaskListView(
    tasks: tasks,
    nowUtc: now,
    timeZoneId: _tz,
    filter: filter,
    sort: sort,
    query: query,
  );

  List<String> ids(TaskListView v, TaskSectionKind k) => [
    for (final s in v.sections)
      if (s.kind == k) ...[for (final e in s.entries) e.task.id],
  ];

  group('sections', () {
    final tasks = [
      _task('over', dueUtc: tehran(3, 20), number: 1),
      _task('today', dueUtc: tehran(4, 9), number: 2),
      _task('next', dueUtc: tehran(5, 10), number: 3),
      _task('none', number: 4),
      _task('done', status: TaskStatus.completed, number: 5),
      _task('canc', status: TaskStatus.canceled, number: 6),
    ];

    test('membership and section order', () {
      final v = view(tasks);
      expect(v.sections.map((s) => s.kind).toList(), [
        TaskSectionKind.overdue,
        TaskSectionKind.today,
        TaskSectionKind.upcoming,
        TaskSectionKind.untimed,
        TaskSectionKind.done,
      ]);
      expect(ids(v, TaskSectionKind.overdue), ['over']);
      expect(ids(v, TaskSectionKind.today), ['today']);
      expect(ids(v, TaskSectionKind.upcoming), ['next']);
      expect(ids(v, TaskSectionKind.untimed), ['none']);
      expect(ids(v, TaskSectionKind.done), ['done', 'canc']);
    });

    test('a task due earlier today is today, not overdue', () {
      final v = view([_task('a', dueUtc: tehran(4, 0, 5))]);
      expect(ids(v, TaskSectionKind.today), ['a']);
      expect(ids(v, TaskSectionKind.overdue), isEmpty);
    });

    test('a start-only task is placed by its start', () {
      final v = view([_task('s', startUtc: tehran(2, 8))]);
      expect(ids(v, TaskSectionKind.overdue), ['s']);
    });

    test('due wins over start', () {
      final v = view([
        _task('x', startUtc: tehran(2, 8), dueUtc: tehran(5, 8)),
      ]);
      expect(ids(v, TaskSectionKind.upcoming), ['x']);
    });

    test('localInstant is the task zone wall clock', () {
      final v = view([_task('a', dueUtc: tehran(4, 9, 15))]);
      expect(
        v.sections.single.entries.single.localInstant,
        DateTime.utc(2026, 11, 4, 9, 15),
      );
      final u = view([_task('n')]);
      expect(u.sections.single.entries.single.localInstant, isNull);
    });

    test('day boundary follows the task zone, not UTC', () {
      // 21:00 UTC on the 3rd is 00:30 Tehran on the 4th: today.
      final v = view([_task('a', dueUtc: DateTime.utc(2026, 11, 3, 21))]);
      expect(ids(v, TaskSectionKind.today), ['a']);
      // 20:00 UTC on the 3rd is 23:30 Tehran on the 3rd: overdue.
      final w = view([_task('b', dueUtc: DateTime.utc(2026, 11, 3, 20))]);
      expect(ids(w, TaskSectionKind.overdue), ['b']);
    });

    test('empty sections are omitted', () {
      expect(view([_task('n')]).sections.length, 1);
    });
  });

  test('counts ignore completed and canceled', () {
    final tasks = [
      _task('over', dueUtc: tehran(3, 20), number: 1),
      _task('today', dueUtc: tehran(4, 9), number: 2),
      _task('next', startUtc: tehran(5, 10), number: 3),
      _task('none', number: 4),
      _task(
        'doneT',
        status: TaskStatus.completed,
        dueUtc: tehran(4, 9),
        number: 5,
      ),
      _task(
        'doneO',
        status: TaskStatus.completed,
        dueUtc: tehran(3, 9),
        number: 6,
      ),
      _task(
        'canc',
        status: TaskStatus.canceled,
        dueUtc: tehran(3, 9),
        number: 7,
      ),
      _task(
        'prog',
        status: TaskStatus.inProgress,
        dueUtc: tehran(4, 18),
        number: 8,
      ),
    ];
    final v = view(tasks);
    expect(v.counts.today, 2);
    expect(v.counts.timed, 4);
    expect(v.counts.overdue, 1);
    expect(v.counts.all, 5);
    expect(v.activeCount, 5);
    expect(v.doneCount, 3);
  });

  group('filter', () {
    final tasks = [
      _task('over', dueUtc: tehran(3, 20), number: 1),
      _task('today', dueUtc: tehran(4, 9), number: 2),
      _task('next', dueUtc: tehran(5, 10), number: 3),
      _task('none', number: 4),
      _task('done', status: TaskStatus.completed, number: 5),
    ];
    List<TaskSectionKind> kinds(TaskSmartFilter f) =>
        view(tasks, filter: f).sections.map((s) => s.kind).toList();

    test(
      'today',
      () => expect(kinds(TaskSmartFilter.today), [TaskSectionKind.today]),
    );
    test(
      'overdue',
      () => expect(kinds(TaskSmartFilter.overdue), [TaskSectionKind.overdue]),
    );
    test('timed', () {
      expect(kinds(TaskSmartFilter.timed), [
        TaskSectionKind.overdue,
        TaskSectionKind.today,
        TaskSectionKind.upcoming,
      ]);
    });
    test('all', () => expect(kinds(TaskSmartFilter.all).length, 5));
    test('counts do not depend on the filter', () {
      expect(view(tasks, filter: TaskSmartFilter.today).counts.all, 4);
    });
  });

  group('sort', () {
    test('time: by time, then priority desc, then display number', () {
      final v = view([
        _task('b', dueUtc: tehran(4, 18), number: 2),
        _task('a', dueUtc: tehran(4, 16), number: 3),
        _task('c', dueUtc: tehran(4, 18), priority: 2, number: 4),
        _task('d', dueUtc: tehran(4, 18), number: 1),
      ]);
      expect(ids(v, TaskSectionKind.today), ['a', 'c', 'd', 'b']);
    });

    test('priority: 3 before 1, ties by time', () {
      final v = view([
        _task('low', dueUtc: tehran(4, 16), priority: 1, number: 1),
        _task('high', dueUtc: tehran(4, 20), priority: 3, number: 2),
        _task('low2', dueUtc: tehran(4, 15), priority: 1, number: 3),
      ], sort: TaskSort.priority);
      expect(ids(v, TaskSectionKind.today), ['high', 'low2', 'low']);
    });

    test('newest: created desc', () {
      final v = view([
        _task('old', createdUtc: DateTime.utc(2026, 10, 1), number: 1),
        _task('new', createdUtc: DateTime.utc(2026, 10, 9), number: 2),
        _task('mid', createdUtc: DateTime.utc(2026, 10, 5), number: 3),
      ], sort: TaskSort.newest);
      expect(ids(v, TaskSectionKind.untimed), ['new', 'mid', 'old']);
    });

    test('alphabetical: Persian titles', () {
      final v = view([
        _task('z', title: 'ماست', number: 1),
        _task('a', title: 'آب', number: 2),
        _task('b', title: 'بازی', number: 4),
      ], sort: TaskSort.alphabetical);
      expect(ids(v, TaskSectionKind.untimed), ['a', 'b', 'z']);
    });

    test('alphabetical differs from code-point order', () {
      final v = view([
        _task('k', title: 'کتاب', number: 1),
        _task('m', title: 'ماست', number: 2),
        _task('c', title: 'چای', number: 3),
        _task('n', title: 'نان', number: 4),
      ], sort: TaskSort.alphabetical);
      expect(ids(v, TaskSectionKind.untimed), ['c', 'k', 'm', 'n']);
    });

    test('time sort puts undated entries last (done section)', () {
      final v = view([
        _task('u', status: TaskStatus.completed, number: 1),
        _task(
          'd',
          status: TaskStatus.completed,
          dueUtc: tehran(3, 9),
          number: 2,
        ),
      ]);
      expect(ids(v, TaskSectionKind.done), ['d', 'u']);
    });

    test('start-only task is timed', () {
      final v = view([
        _task('s', startUtc: tehran(6, 8)),
        _task('n'),
      ], filter: TaskSmartFilter.timed);
      expect(ids(v, TaskSectionKind.upcoming), ['s']);
      expect(v.counts.timed, 1);
    });

    test('sort stays inside sections; done is completed before canceled', () {
      final v = view([
        _task('c1', status: TaskStatus.canceled, priority: 3, number: 1),
        _task('d1', status: TaskStatus.completed, number: 2),
        _task('o', dueUtc: tehran(3, 9), number: 3),
      ], sort: TaskSort.priority);
      expect(v.sections.first.kind, TaskSectionKind.overdue);
      expect(ids(v, TaskSectionKind.done), ['d1', 'c1']);
    });
  });

  group('search', () {
    test('normalizeTaskSearch', () {
      expect(normalizeTaskSearch('  كار   ييي  Ab '), 'کار ییی ab');
    });

    test('Arabic kaf matches Persian kaf in the title', () {
      final v = view([_task('a', title: 'کار خانه')], query: 'كار');
      expect(ids(v, TaskSectionKind.untimed), ['a']);
    });

    test('description matches', () {
      final v = view([
        _task('a', title: 'x', description: 'خرید نان'),
        _task('b', title: 'y'),
      ], query: 'نان');
      expect(ids(v, TaskSectionKind.untimed), ['a']);
    });

    test('empty query matches all; no match gives no sections', () {
      final tasks = [_task('a'), _task('b')];
      expect(view(tasks, query: '   ').sections.single.entries.length, 2);
      expect(view(tasks, query: 'zzz').sections, isEmpty);
    });

    test('diacritics and ZWNJ are normalised', () {
      final v = view([
        _task('a', title: 'کتاب', number: 1),
        _task('b', title: 'می روم', number: 2),
      ], query: 'كِتاب');
      expect(ids(v, TaskSectionKind.untimed), ['a']);
      final w = view([_task('b', title: 'می روم')], query: 'می\u200Cروم');
      expect(ids(w, TaskSectionKind.untimed), ['b']);
    });

    test('comparePersian follows the Persian alphabet', () {
      final l = ['گل', 'کتاب', 'چای', 'پنیر', 'باغ', 'آب']
        ..sort(comparePersian);
      expect(l, ['آب', 'باغ', 'پنیر', 'چای', 'کتاب', 'گل']);
      expect(comparePersian('می\u200Cروم', 'میروم'), 0);
      final m = ['میروم', 'می\u200Cروم', 'ماست', 'نان']..sort(comparePersian);
      expect(m.first, 'ماست');
      expect(m.last, 'نان');
      expect(comparePersian('ا', 'abc') < 0, isTrue);
      expect(comparePersian('abc', 'ا') > 0, isTrue);
      expect(comparePersian('', 'ا') < 0, isTrue);
      expect(comparePersian('ا', '') > 0, isTrue);
      expect(comparePersian('', ''), 0);
      expect(comparePersian('کتاب', 'گل') < 0, isTrue);
      expect(comparePersian('گل', 'کتاب') > 0, isTrue);
      expect(comparePersian('کـتَاب', 'کتاب'), 0);
    });

    test('taskMatches is case-insensitive', () {
      expect(taskMatches(_task('a', title: 'Buy Milk'), 'MILK'), isTrue);
    });
  });

  test('time base is the task zone, not the process zone', () {
    // Run under TZ=UTC and TZ=Asia/Tokyo too; the same instants must land in
    // the same sections.
    final v = view([
      _task('over', dueUtc: DateTime.utc(2026, 11, 3, 20)),
      _task('today', dueUtc: DateTime.utc(2026, 11, 3, 21)),
      _task('next', dueUtc: DateTime.utc(2026, 11, 4, 20, 30)),
    ]);
    expect(ids(v, TaskSectionKind.overdue), ['over']);
    expect(ids(v, TaskSectionKind.today), ['today']);
    expect(ids(v, TaskSectionKind.upcoming), ['next']);
  });
}
