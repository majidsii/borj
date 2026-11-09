import 'dart:async';

import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as timezone;

import '../../support/test_database.dart';

final class _ElapsedClock implements AppClock {
  _ElapsedClock(this.start, this.elapsed);

  final DateTime start;
  final Duration Function() elapsed;

  @override
  DateTime nowUtc() => start.add(elapsed());

  @override
  DateTime nowLocal() => nowUtc();
}

final class _CountingBuilder extends TodayAgendaBuilder {
  _CountingBuilder();
  int calls = 0;

  @override
  TodayAgenda build({
    required List<TaskItem> tasks,
    required List<TaskRecurrenceRule> rules,
    required List<TaskRecurrenceException> exceptions,
    required List<TaskOccurrenceCompletion> completions,
    required DateTime nowUtc,
    required String timeZoneId,
  }) {
    calls++;
    return super.build(
      tasks: tasks,
      rules: rules,
      exceptions: exceptions,
      completions: completions,
      nowUtc: nowUtc,
      timeZoneId: timeZoneId,
    );
  }
}

Money _irt(int v) => Money(minorUnits: v, currencyCode: 'IRT', scale: 0);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  // 2026-11-04 14:30 Tehran (UTC+3:30).
  final nowUtc = DateTime.utc(2026, 11, 4, 11, 0);
  late StreamController<DateTime> ticks;
  late ProviderContainer container;
  late _CountingBuilder counting;

  setUp(() {
    final database = openTestDatabase();
    ticks = StreamController<DateTime>();
    counting = _CountingBuilder();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
        ),
        taskCalendarTimeZoneProvider.overrideWith(
          (ref) => Future.value('Asia/Tehran'),
        ),
        minuteTickProvider.overrideWith((ref) => ticks.stream),
        todayAgendaBuilderProvider.overrideWithValue(counting),
      ],
    );
    addTearDown(() async {
      container.dispose();
      unawaited(ticks.close());
      await database.close();
    });
  });

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 500 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue, reason: 'condition not reached in time');
  }

  TaskItem task(String id, {DateTime? dueUtc}) {
    final t = DateTime.utc(2026, 11, 1);
    return TaskItem(
      id: id,
      displayNumber: 1,
      title: 'task $id',
      priority: 0,
      status: TaskStatus.planned,
      positionInStatus: 0,
      dueAtUtc: dueUtc,
      createdAtUtc: t,
      updatedAtUtc: t,
    );
  }

  InstallmentPlan plan(String id, int created, {int paid = 0, int count = 4}) =>
      InstallmentPlan(
        id: id,
        title: 'plan $id',
        perInstallment: _irt(1000),
        installmentCount: count,
        paidCount: paid,
        createdAtUtc: DateTime.utc(2026, 11, created),
        updatedAtUtc: DateTime.utc(2026, 11, created),
      );

  group('todayAgendaProvider', () {
    test(
      'follows the zone day; the task leaves when the day changes',
      () async {
        await container
            .read(taskRepositoryProvider)
            .create(task('a', dueUtc: DateTime.utc(2026, 11, 4, 11, 30)));
        container.listen(todayAgendaProvider, (_, _) {});
        ticks.add(nowUtc);
        await until(
          () => container.read(todayAgendaProvider).value?.timed.length == 1,
        );
        final first = container.read(todayAgendaProvider).requireValue;
        expect(first.day, DateTime(2026, 11, 4));
        expect(first.timed.single.localStart, DateTime(2026, 11, 4, 15, 0));
        expect(
          container.read(todayNowProvider).value,
          DateTime(2026, 11, 4, 14, 30),
        );

        // 2026-11-05 00:01 Tehran.
        ticks.add(DateTime.utc(2026, 11, 4, 20, 31));
        await until(
          () =>
              container.read(todayAgendaProvider).value?.day ==
              DateTime(2026, 11, 5),
        );
        expect(container.read(todayAgendaProvider).requireValue.timed, isEmpty);
        expect(
          container.read(todayNowProvider).value,
          DateTime(2026, 11, 5, 0, 1),
        );
      },
    );

    test('a tick within the same zone day does not recompute', () async {
      container.listen(todayAgendaProvider, (_, _) {});
      ticks.add(nowUtc);
      await until(() => container.read(todayAgendaProvider).hasValue);
      final before = counting.calls;
      expect(before, greaterThan(0));

      ticks.add(DateTime.utc(2026, 11, 4, 11, 1)); // 14:31
      await until(
        () =>
            container.read(todayNowProvider).value ==
            DateTime(2026, 11, 4, 14, 31),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counting.calls, before);

      // A task stream event does recompute.
      await container.read(taskRepositoryProvider).create(task('x'));
      await until(() => counting.calls > before);
    });
  });

  group('unknown time zone', () {
    test('todayNowProvider and todayAgendaProvider return an error', () async {
      final database = openTestDatabase();
      addTearDown(database.close);
      final bad = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
          ),
          taskCalendarTimeZoneProvider.overrideWith(
            (ref) => Future.value('Mars/Olympus'),
          ),
          minuteTickProvider.overrideWith((ref) => Stream.value(nowUtc)),
        ],
      );
      addTearDown(bad.dispose);
      bad.listen(todayNowProvider, (_, _) {});
      bad.listen(todayAgendaProvider, (_, _) {});
      await until(() => bad.read(todayNowProvider).hasError);
      expect(
        bad.read(todayNowProvider).error,
        isA<timezone.LocationNotFoundException>(),
      );
      await until(() => bad.read(todayAgendaProvider).hasError);
    });
  });

  group('minuteTickProvider', () {
    test('ticks at UTC minute boundaries and cancels on dispose', () {
      FakeAsync().run((async) {
        final start = DateTime.utc(2026, 11, 4, 11, 0, 30);
        final container = ProviderContainer(
          overrides: [
            appClockProvider.overrideWithValue(
              _ElapsedClock(start, () => async.elapsed),
            ),
          ],
        );
        final ticks = <DateTime>[];
        container.listen<AsyncValue<DateTime>>(
          minuteTickProvider,
          (_, next) => next.whenData(ticks.add),
          fireImmediately: true,
        );
        async.flushMicrotasks();
        expect(ticks, [start]);

        async.elapse(const Duration(seconds: 29));
        expect(ticks, hasLength(1));
        async.elapse(const Duration(seconds: 1)); // +30 s: 11:01:00
        expect(ticks.last, DateTime.utc(2026, 11, 4, 11, 1));
        expect(ticks, hasLength(2));
        async.elapse(const Duration(seconds: 60)); // +90 s: 11:02:00
        expect(ticks.last, DateTime.utc(2026, 11, 4, 11, 2));
        expect(ticks, hasLength(3));

        container.dispose();
        async.flushMicrotasks();
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('emits the clock nowUtc immediately', () async {
      final fresh = ProviderContainer(
        overrides: [
          appClockProvider.overrideWithValue(
            FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
          ),
        ],
      );
      addTearDown(fresh.dispose);
      fresh.listen(minuteTickProvider, (_, _) {});
      await until(() => fresh.read(minuteTickProvider).hasValue);
      expect(fresh.read(minuteTickProvider).requireValue, nowUtc);
      expect(fresh.read(minuteTickProvider).requireValue.isUtc, isTrue);
    });
  });

  group('todayInstallmentProvider', () {
    test(
      'the older active plan; paid-off plans are skipped; none is null',
      () async {
        container.listen(todayInstallmentProvider, (_, _) {});
        await until(() => container.read(todayInstallmentProvider).hasValue);
        expect(container.read(todayInstallmentProvider).value, isNull);

        final finance = container.read(financeRepositoryProvider);
        await finance.addInstallmentPlan(plan('paid', 1, paid: 4));
        await finance.addInstallmentPlan(plan('newer', 3, paid: 1));
        await finance.addInstallmentPlan(plan('older', 2, paid: 2));
        await until(
          () => container.read(installmentPlansProvider).value?.length == 3,
        );

        final value = container.read(todayInstallmentProvider).requireValue!;
        expect(value.planId, 'older');
        expect(value.title, 'plan older');
        expect(value.nextNumber, 3);
        expect(value.count, 4);
        expect(value.amount, _irt(1000));
        expect(value.progress, 0.5);

        await finance.deleteInstallmentPlan('older');
        await finance.deleteInstallmentPlan('newer');
        await finance.deleteInstallmentPlan('paid');
        await until(
          () => container.read(todayInstallmentProvider).value == null,
        );
      },
    );
  });

  group('todayInstallmentProvider ties', () {
    test('equal createdAt falls back to the smaller id', () async {
      container.listen(todayInstallmentProvider, (_, _) {});
      final finance = container.read(financeRepositoryProvider);
      await finance.addInstallmentPlan(plan('z', 2));
      await finance.addInstallmentPlan(plan('m', 2));
      await finance.addInstallmentPlan(plan('a', 2));
      await until(
        () => container.read(installmentPlansProvider).value?.length == 3,
      );
      expect(container.read(todayInstallmentProvider).value?.planId, 'a');
    });
  });

  group('todayIsNewUserProvider', () {
    test('true when empty, false after a task', () async {
      container.listen(todayIsNewUserProvider, (_, _) {});
      await until(() => container.read(todayIsNewUserProvider).hasValue);
      expect(container.read(todayIsNewUserProvider).value, isTrue);
      await container.read(taskRepositoryProvider).create(task('a'));
      await until(() => container.read(todayIsNewUserProvider).value == false);
    });

    test('false with only a transaction', () async {
      container.listen(todayIsNewUserProvider, (_, _) {});
      await until(() => container.read(todayIsNewUserProvider).hasValue);
      expect(container.read(todayIsNewUserProvider).value, isTrue);
      await container
          .read(financeRepositoryProvider)
          .addTransaction(
            FinanceTransaction.create(
              id: 'tx',
              type: FinanceTransactionType.expense,
              title: 'coffee',
              category: 'food',
              amount: _irt(500),
              occurredAtUtc: nowUtc,
              createdAtUtc: nowUtc,
            ),
          );
      await until(() => container.read(todayIsNewUserProvider).value == false);
    });
  });
}
