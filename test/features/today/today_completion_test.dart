import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../support/test_database.dart';

const _tz = 'Asia/Tehran';

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

final class _TehranZone implements DeviceTimeZoneSource {
  const _TehranZone();

  @override
  Future<String> localTimeZoneName() async => _tz;
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  // 2026-11-04 14:30 Tehran (UTC+3:30).
  final nowUtc = DateTime.utc(2026, 11, 4, 11, 0);
  late ProviderContainer container;

  setUp(() {
    final database = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
        deviceTimeZoneSourceProvider.overrideWithValue(const _TehranZone()),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
  });

  TaskItem task(String id, {DateTime? startUtc, DateTime? dueUtc}) {
    final t = DateTime.utc(2026, 11, 1);
    return TaskItem(
      id: id,
      displayNumber: 1,
      title: 'task $id',
      priority: 0,
      status: TaskStatus.planned,
      positionInStatus: 0,
      startAtUtc: startUtc,
      dueAtUtc: dueUtc,
      createdAtUtc: t,
      updatedAtUtc: t,
    );
  }

  Future<TodayAgenda> agendaNow() async {
    final tasks = await container.read(taskRepositoryProvider).watchAll().first;
    final recurrence = container.read(taskRecurrenceRepositoryProvider);
    return const TodayAgendaBuilder().build(
      tasks: tasks,
      rules: await recurrence.watchRules().first,
      exceptions: await recurrence.watchExceptions().first,
      completions: await recurrence.watchCompletions().first,
      nowUtc: nowUtc,
      timeZoneId: _tz,
    );
  }

  test('one-off: toggle completes, toggling again reopens', () async {
    final repository = container.read(taskRepositoryProvider);
    await repository.create(
      task('a', dueUtc: DateTime.utc(2026, 11, 4, 11, 30)),
    );
    final completion = container.read(todayCompletionProvider);

    final open = (await agendaNow()).timed.single;
    expect(open.done, isFalse);
    await completion.toggle(open);
    expect((await repository.getById('a'))!.status, TaskStatus.completed);

    final done = (await agendaNow()).timed.single;
    expect(done.done, isTrue);
    await completion.toggle(done);
    expect((await repository.getById('a'))!.status, TaskStatus.planned);
  });

  test('recurring: toggle records the occurrence, again clears it', () async {
    final repository = container.read(taskRepositoryProvider);
    await repository.create(
      task('r', startUtc: DateTime.utc(2026, 11, 1, 5, 30)), // 09:00 Tehran
    );
    await container
        .read(taskRecurrenceServiceProvider)
        .replaceRule(
          taskId: 'r',
          rule: RecurrenceRule.daily(
            anchorLocalDateTime: RecurrenceLocalDateTime(
              year: 2026,
              month: 11,
              day: 1,
              hour: 9,
            ),
            timeZone: const RecurrenceTimeZone.floating(),
          ),
        );
    final recurrence = container.read(taskRecurrenceRepositoryProvider);
    final completion = container.read(todayCompletionProvider);
    final today9 = RecurrenceLocalDateTime(
      year: 2026,
      month: 11,
      day: 4,
      hour: 9,
    );

    final open = (await agendaNow()).timed.single;
    expect(open.recurring, isTrue);
    expect(open.originalLocalDateTime, today9);
    await completion.toggle(open);
    final stored = await recurrence.watchCompletions().first;
    expect(stored.map((c) => c.originalLocalDateTime), [today9]);

    final done = (await agendaNow()).timed.single;
    expect(done.done, isTrue);
    await completion.toggle(done);
    expect(await recurrence.watchCompletions().first, isEmpty);
  });

  test('changedAtUtc comes from the clock', () async {
    final repository = container.read(taskRepositoryProvider);
    await repository.create(
      task('c', dueUtc: DateTime.utc(2026, 11, 4, 11, 30)),
    );
    await container
        .read(todayCompletionProvider)
        .toggle((await agendaNow()).timed.single);
    final stored = await repository.getById('c');
    expect(stored!.completedAtUtc, container.read(appClockProvider).nowUtc());
    expect(stored.completedAtUtc, nowUtc);
  });
}
