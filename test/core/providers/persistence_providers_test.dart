import 'dart:async';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/finance/data/drift_finance_repository.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:borj/features/tasks/data/drift_task_reminder_repository.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/data/drift_task_time_repository.dart';
import 'package:borj/features/tasks/data/reminder_aware_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = openTestDatabase();
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('repository providers use the overridden database', () {
    final taskRepository = container.read(taskRepositoryProvider);
    final financeRepository = container.read(financeRepositoryProvider);

    expect(taskRepository, isA<ReminderAwareTaskRepository>());
    expect(
      container.read(baseTaskRepositoryProvider),
      isA<DriftTaskRepository>(),
    );
    expect(
      container.read(taskReminderRepositoryProvider),
      isA<DriftTaskReminderRepository>(),
    );
    expect(
      container.read(taskRecurrenceRepositoryProvider),
      isA<DriftTaskRecurrenceRepository>(),
    );
    expect(
      container.read(taskTimeRepositoryProvider),
      isA<DriftTaskTimeRepository>(),
    );
    expect(financeRepository, isA<DriftFinanceRepository>());
    expect(identical(container.read(appDatabaseProvider), database), isTrue);
  });

  test('taskItemsProvider emits persisted tasks', () async {
    final now = DateTime.utc(2026, 7, 26, 10);
    final nextItems = _waitForData<List<TaskItem>>(
      container,
      taskItemsProvider,
      (items) => items.length == 1 && items.single.id == 'provider-task',
    );

    await container
        .read(taskRepositoryProvider)
        .create(
          TaskItem(
            id: 'provider-task',
            displayNumber: 1,
            title: 'تسک ذخیره‌شده',
            priority: 2,
            status: TaskStatus.planned,
            positionInStatus: 0,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );

    final items = await nextItems;
    expect(items.single.title, 'تسک ذخیره‌شده');
  });

  test(
    'timer providers emit persisted active and task-scoped entries',
    () async {
      final now = DateTime.utc(2026, 8, 6, 8);
      await container
          .read(taskRepositoryProvider)
          .create(
            TaskItem(
              id: 'timer-provider-task',
              displayNumber: 1,
              title: 'تایمر Provider',
              priority: 1,
              status: TaskStatus.planned,
              positionInStatus: 0,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      final activeFuture = _waitForData<TaskTimeEntry?>(
        container,
        activeTaskTimerProvider,
        (entry) => entry?.taskId == 'timer-provider-task',
      );
      final entriesFuture = _waitForData<List<TaskTimeEntry>>(
        container,
        taskTimeEntriesByTaskProvider('timer-provider-task'),
        (entries) => entries.length == 1,
      );

      await container
          .read(taskTimerServiceProvider)
          .start('timer-provider-task');

      expect((await activeFuture)!.taskId, 'timer-provider-task');
      expect((await entriesFuture).single.isRunning, isTrue);
    },
  );

  test('financeTransactionsProvider emits repository data', () async {
    final now = DateTime.utc(2026, 7, 26, 11);
    final nextItems = _waitForData<List<FinanceTransaction>>(
      container,
      financeTransactionsProvider,
      (items) => items.length == 1 && items.single.id == 'provider-income',
    );

    await container
        .read(financeRepositoryProvider)
        .addTransaction(
          FinanceTransaction.create(
            id: 'provider-income',
            type: FinanceTransactionType.income,
            title: 'حقوق',
            category: 'درآمد',
            amount: _money('1250'),
            occurredAtUtc: now,
            createdAtUtc: now,
          ),
        );

    final items = await nextItems;
    expect(items.single.amount, _money('1250'));
  });

  test('debt and installment providers emit live values', () async {
    final now = DateTime.utc(2026, 7, 26, 12);

    final nextDebts = _waitForData<List<Debt>>(
      container,
      debtsProvider,
      (items) => items.length == 1 && items.single.id == 'provider-debt',
    );
    final nextPlans = _waitForData<List<InstallmentPlan>>(
      container,
      installmentPlansProvider,
      (items) => items.length == 1 && items.single.id == 'provider-plan',
    );

    final repository = container.read(financeRepositoryProvider);

    await repository.addDebt(
      Debt(
        id: 'provider-debt',
        title: 'بدهی',
        total: _money('20'),
        paid: Money.zeroIRT,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    await repository.addInstallmentPlan(
      InstallmentPlan(
        id: 'provider-plan',
        title: 'اقساط',
        perInstallment: _money('250'),
        installmentCount: 4,
        paidCount: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    expect((await nextDebts).single.total, _money('20'));
    expect((await nextPlans).single.perInstallment, _money('250'));
  });

  test('financeReportServiceProvider is stable per container', () {
    final first = container.read(financeReportServiceProvider);
    final second = container.read(financeReportServiceProvider);

    expect(identical(first, second), isTrue);
  });
}

Future<T> _waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
  bool Function(T value) predicate,
) {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;

  subscription = container.listen<AsyncValue<T>>(provider, (previous, next) {
    next.whenData((value) {
      if (!completer.isCompleted && predicate(value)) {
        completer.complete(value);
      }
    });
  }, fireImmediately: true);

  return completer.future
      .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          subscription.close();
          throw TimeoutException('Provider did not emit the expected value.');
        },
      )
      .whenComplete(subscription.close);
}

Money _money(String value) {
  return Money.parseMajorUnits(
    value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}
