import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../support/test_database.dart';

final _now = DateTime.utc(2026, 11, 11, 9);
final _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: _now, localValue: _now),
        ),
        taskCalendarTimeZoneProvider.overrideWith(
          (ref) => Future.value('Asia/Tehran'),
        ),
        minuteTickProvider.overrideWith((ref) => Stream.value(_now)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  TaskActions actions() => container.read(taskActionsProvider);

  Future<List<TaskItem>> all() =>
      container.read(taskRepositoryProvider).watchAll().first;

  Future<TaskItem> byId(String id) async =>
      (await all()).firstWhere((t) => t.id == id);

  Future<void> expectContiguous() async {
    final tasks = await all();
    for (final status in TaskStatus.values) {
      final positions =
          tasks
              .where((t) => t.status == status)
              .map((t) => t.positionInStatus)
              .toList()
            ..sort();
      expect(positions, List<int>.generate(positions.length, (i) => i));
    }
  }

  Future<List<String>> idsIn(TaskStatus status) async {
    final tasks = (await all()).where((t) => t.status == status).toList()
      ..sort((a, b) => a.positionInStatus.compareTo(b.positionInStatus));
    return [for (final t in tasks) t.id];
  }

  test('create stores a planned task with a UUID v7 id', () async {
    final due = DateTime.utc(2026, 11, 12, 20, 29);
    final id = await actions().createAndReturnId(
      title: '  خرید  ',
      priority: 2,
      dueAtUtc: due,
    );
    expect(id, matches(_uuidV7));
    final t = await byId(id);
    expect(t.title, 'خرید');
    expect(t.priority, 2);
    expect(t.status, TaskStatus.planned);
    expect(t.positionInStatus, 0);
    expect(t.dueAtUtc, due);
    expect(t.createdAtUtc, _now);
    expect(t.updatedAtUtc, _now);

    await actions().create(title: 'دوم', priority: 0);
    expect((await all()).length, 2);
    await expectContiguous();
  });

  test('toggleDone moves planned to completed and back', () async {
    final id = await actions().createAndReturnId(title: 'a', priority: 0);
    await actions().toggleDone(await byId(id));
    var t = await byId(id);
    expect(t.status, TaskStatus.completed);
    expect(t.completedAtUtc, _now);

    await actions().toggleDone(t);
    t = await byId(id);
    expect(t.status, TaskStatus.planned);
    expect(t.completedAtUtc, isNull);
    await expectContiguous();
  });

  test('setStatus keeps positions contiguous', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(title: 'b', priority: 0);
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    await actions().setStatus(await byId(b), TaskStatus.inProgress);
    expect((await byId(b)).status, TaskStatus.inProgress);
    await expectContiguous();
    await actions().setStatus(await byId(a), TaskStatus.canceled);
    final canceled = await byId(a);
    expect(canceled.status, TaskStatus.canceled);
    expect(canceled.canceledAtUtc, _now);
    await expectContiguous();
    expect(await idsIn(TaskStatus.planned), [c]);
  });

  test('cyclePriority goes 0 1 2 3 0', () async {
    final id = await actions().createAndReturnId(title: 'a', priority: 0);
    final seen = <int>[];
    for (var i = 0; i < 4; i++) {
      await actions().cyclePriority(await byId(id));
      seen.add((await byId(id)).priority);
    }
    expect(seen, [1, 2, 3, 0]);
  });

  test('delete returns the task; restore keeps id, fields, number and '
      'position', () async {
    final due = DateTime.utc(2026, 11, 12, 6);
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(
      title: 'b',
      priority: 3,
      dueAtUtc: due,
    );
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    // newest created goes to position 0 of planned; re-read the real order.
    final before = await idsIn(TaskStatus.planned);
    final original = await byId(b);
    final index = before.indexOf(b);

    final deleted = await actions().delete(b);
    expect(deleted, isNotNull);
    expect(deleted!.id, b);
    expect((await all()).any((t) => t.id == b), isFalse);
    await expectContiguous();

    // Another task created meanwhile must not take the freed number.
    final d = await actions().createAndReturnId(title: 'd', priority: 0);
    expect((await byId(d)).displayNumber, isNot(original.displayNumber));

    await actions().restore(deleted);
    final restored = await byId(b);
    expect(restored.displayNumber, original.displayNumber);
    expect(restored.title, 'b');
    expect(restored.priority, 3);
    expect(restored.dueAtUtc, due);
    expect(restored.status, TaskStatus.planned);
    expect(restored.createdAtUtc, original.createdAtUtc);
    expect(restored.positionInStatus, index);
    expect((await idsIn(TaskStatus.planned)).indexOf(b), index);
    expect({a, c}.every((id) => before.contains(id)), isTrue);
    await expectContiguous();
  });

  test('delete of an unknown id returns null', () async {
    expect(await actions().delete('missing'), isNull);
  });

  test('restore keeps the completed timestamp and status', () async {
    final id = await actions().createAndReturnId(title: 'a', priority: 1);
    await actions().toggleDone(await byId(id));
    final done = await byId(id);
    await actions().delete(id);
    await actions().restore(done);
    final t = await byId(id);
    expect(t.status, TaskStatus.completed);
    expect(t.completedAtUtc, done.completedAtUtc);
    expect(t.displayNumber, done.displayNumber);
    await expectContiguous();
  });

  test('deleteCompleted returns the deleted list and restoring brings them '
      'back', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(title: 'b', priority: 0);
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    await actions().toggleDone(await byId(a));
    await actions().toggleDone(await byId(b));
    final doneBefore = await idsIn(TaskStatus.completed);
    final numbers = {for (final t in await all()) t.id: t.displayNumber};

    final deleted = await actions().deleteCompleted();
    expect({for (final t in deleted) t.id}, {a, b});
    expect((await all()).map((t) => t.id), [c]);

    for (final t in deleted) {
      await actions().restore(t);
    }
    expect(await idsIn(TaskStatus.completed), doneBefore);
    for (final t in await all()) {
      expect(t.displayNumber, numbers[t.id]);
    }
    await expectContiguous();
  });

  test(
    'deleteCompleted with nothing completed returns an empty list',
    () async {
      await actions().create(title: 'a', priority: 0);
      expect(await actions().deleteCompleted(), isEmpty);
      expect((await all()).length, 1);
    },
  );

  test('move across statuses transitions to the target position', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(title: 'b', priority: 0);
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    await actions().setStatus(await byId(c), TaskStatus.inProgress);
    await actions().move(a, TaskStatus.inProgress, 1);
    expect(await idsIn(TaskStatus.inProgress), [c, a]);
    expect(await idsIn(TaskStatus.planned), [b]);
    await expectContiguous();
    await actions().move(b, TaskStatus.inProgress, 99);
    expect(await idsIn(TaskStatus.inProgress), [c, a, b]);
    await expectContiguous();
  });

  test('move within a status reorders; unchanged order is a no-op', () async {
    await actions().create(title: 'a', priority: 0);
    await actions().create(title: 'b', priority: 0);
    await actions().create(title: 'c', priority: 0);
    final order = await idsIn(TaskStatus.planned);
    await actions().move(order[0], TaskStatus.planned, 2);
    expect(await idsIn(TaskStatus.planned), [order[1], order[2], order[0]]);

    final stamp = (await all()).map((t) => t.updatedAtUtc).toList();
    final current = await idsIn(TaskStatus.planned);
    await actions().move(current[1], TaskStatus.planned, 1);
    expect(await idsIn(TaskStatus.planned), current);
    expect((await all()).map((t) => t.updatedAtUtc).toList(), stamp);
    await expectContiguous();
  });

  test('taskListViewProvider reflects filter, sort and query', () async {
    await actions().create(title: 'alpha', priority: 0);
    await actions().create(title: 'beta', priority: 3);
    final sub = container.listen(taskListViewProvider, (_, _) {});
    addTearDown(sub.close);

    Future<TaskListView> view() async {
      await container.read(taskItemsProvider.future);
      await container.read(taskCalendarTimeZoneProvider.future);
      await container.read(minuteTickProvider.future);
      return container.read(taskListViewProvider).requireValue;
    }

    List<String> titles(TaskListView v) => [
      for (final s in v.sections)
        for (final e in s.entries) e.task.title,
    ];

    var v = await view();
    expect(titles(v).toSet(), {'alpha', 'beta'});

    container.read(tasksSortProvider.notifier).state = TaskSort.alphabetical;
    v = await view();
    expect(titles(v), ['alpha', 'beta']);

    container.read(tasksSortProvider.notifier).state = TaskSort.priority;
    v = await view();
    expect(titles(v), ['beta', 'alpha']);

    container.read(tasksQueryProvider.notifier).state = 'alp';
    v = await view();
    expect(titles(v), ['alpha']);

    container.read(tasksQueryProvider.notifier).state = '';
    container.read(tasksFilterProvider.notifier).state = TaskSmartFilter.timed;
    v = await view();
    expect(titles(v), isEmpty);
  });

  test('state providers have the documented defaults', () {
    expect(container.read(tasksFilterProvider), TaskSmartFilter.all);
    expect(container.read(tasksSortProvider), TaskSort.time);
    expect(container.read(tasksQueryProvider), '');
  });
}
