import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
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

final class _TehranZone implements DeviceTimeZoneSource {
  const _TehranZone();

  @override
  Future<String> localTimeZoneName() async => 'Asia/Tehran';
}

final class _NoopScheduler implements NotificationScheduler {
  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<void> cancel(String scheduleId) async {}

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {}

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {}
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
        deviceTimeZoneSourceProvider.overrideWithValue(const _TehranZone()),
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

  Future<void> seedChildren(String id) async {
    final due = DateTime.utc(2026, 11, 12, 6);
    final t = await byId(id);
    await container
        .read(taskRepositoryProvider)
        .update(t.copyWith(dueAtUtc: due, startAtUtc: due));
    await container.read(taskReminderRepositoryProvider).replaceForTask(id, [
      TaskReminderRule(
        id: 'rem-$id',
        taskId: id,
        trigger: TaskReminderTrigger.atDue,
        createdAtUtc: _now,
        updatedAtUtc: _now,
      ),
    ]);
    await container
        .read(taskRecurrenceServiceProvider)
        .replaceRule(
          taskId: id,
          rule: RecurrenceRule.daily(
            anchorLocalDateTime: RecurrenceLocalDateTime(
              year: 2026,
              month: 11,
              day: 11,
              hour: 9,
            ),
            timeZone: const RecurrenceTimeZone.floating(),
          ),
        );
  }

  Future<void> settle() async {
    await container.read(taskItemsProvider.future);
    await container.read(taskCalendarTimeZoneProvider.future);
    await container.read(minuteTickProvider.future);
    await Future<void>.delayed(Duration.zero);
  }

  List<String> listIds() => [
    for (final s in container.read(taskListViewProvider).requireValue.sections)
      for (final e in s.entries) e.task.id,
  ];

  test('delete hides everywhere; undo restores with children intact', () async {
    final id = await actions().createAndReturnId(title: 'a', priority: 1);
    await seedChildren(id);
    final number = (await byId(id)).displayNumber;
    final l1 = container.listen(taskListViewProvider, (_, _) {});
    final l2 = container.listen(todayAgendaProvider, (_, _) {});
    final l3 = container.listen(todayIsNewUserProvider, (_, _) {});
    addTearDown(() {
      l1.close();
      l2.close();
      l3.close();
    });
    await settle();
    await container.read(taskRecurrenceRulesProvider.future);
    await container.read(taskRecurrenceExceptionsProvider.future);
    await container.read(taskOccurrenceCompletionsProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(listIds(), [id]);
    expect(container.read(todayAgendaProvider).requireValue.timed, isNotEmpty);

    final handle = await actions().delete(id);
    await settle();
    expect(listIds(), isEmpty);
    expect(container.read(todayAgendaProvider).requireValue.timed, isEmpty);
    expect(container.read(todayIsNewUserProvider).requireValue, isFalse);
    expect((await all()).any((t) => t.id == id), isTrue);

    handle!.undo();
    await settle();
    expect(listIds(), [id]);
    expect(container.read(todayAgendaProvider).requireValue.timed, isNotEmpty);
    expect((await byId(id)).displayNumber, number);
    expect(
      await container.read(taskReminderRepositoryProvider).getByTask(id),
      hasLength(1),
    );
    final bundle = await container
        .read(taskRecurrenceRepositoryProvider)
        .getByTask(id);
    expect(bundle.rule, isNotNull);

    // undone handle: commit is a no-op
    await handle.commit();
    expect((await all()).any((t) => t.id == id), isTrue);
  });

  test('commit deletes from the repository; twice is a no-op', () async {
    final id = await actions().createAndReturnId(title: 'a', priority: 1);
    await seedChildren(id);
    final handle = await actions().delete(id);
    await handle!.commit();
    expect((await all()).any((t) => t.id == id), isFalse);
    // Committed ids stay hidden: no flicker before the stream re-emits.
    expect(container.read(pendingTaskDeletionsProvider), {id});
    expect(
      await container.read(taskReminderRepositoryProvider).getByTask(id),
      isEmpty,
    );
    await handle.commit();
    handle.undo();
    expect((await all()), isEmpty);
    await expectContiguous();
  });

  test('delete of an unknown id returns null', () async {
    expect(await actions().delete('missing'), isNull);
  });

  test('max-number delete then create then undo: distinct numbers', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(title: 'b', priority: 0);
    final maxNumber = (await byId(b)).displayNumber;
    final handle = await actions().delete(b);
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    expect((await byId(c)).displayNumber, maxNumber + 1);
    handle!.undo();
    final numbers = (await all()).map((t) => t.displayNumber).toList();
    expect(numbers.toSet().length, 3);
    expect((await byId(b)).displayNumber, maxNumber);
    expect((await byId(a)).displayNumber, lessThan(maxNumber));
  });

  test('deleteCompleted hides exactly the completed tasks', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    final b = await actions().createAndReturnId(title: 'b', priority: 0);
    final c = await actions().createAndReturnId(title: 'c', priority: 0);
    await actions().toggleDone(await byId(a));
    await actions().toggleDone(await byId(b));
    final handle = await actions().deleteCompleted();
    expect({for (final t in handle.tasks) t.id}, {a, b});
    expect(container.read(pendingTaskDeletionsProvider), {a, b});
    expect((await all()).length, 3);

    // A task completed during the window is not deleted by commit.
    await actions().toggleDone(await byId(c));
    await handle.commit();
    expect((await all()).map((t) => t.id), [c]);
    await expectContiguous();

    final none = await actions().deleteCompleted();
    expect(none.tasks.map((t) => t.id), [c]);
    none.undo();
    expect((await all()).length, 1);
  });

  test('deleteCompleted undo keeps everything', () async {
    final a = await actions().createAndReturnId(title: 'a', priority: 0);
    await actions().toggleDone(await byId(a));
    final handle = await actions().deleteCompleted();
    handle.undo();
    await handle.commit();
    expect((await all()).map((t) => t.id), [a]);
    expect(container.read(pendingTaskDeletionsProvider), isEmpty);
  });

  test('move with an unknown task rethrows', () async {
    expect(
      () => actions().move('missing', TaskStatus.planned, 0),
      throwsA(anything),
    );
  });

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
