import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tasks and exact finance data survive closing and reopening', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-shakhsi-restart-',
    );
    final file = File('${directory.path}/restart.sqlite');

    try {
      final first = AppDatabase(NativeDatabase(file));
      final firstTasks = DriftTaskRepository(first);
      final firstFinance = DriftFinanceRepository(
        first,
        idGenerator: SequenceIdGenerator(prefix: 'restart'),
      );

      final createdAt = DateTime.utc(2026, 7, 26, 8);
      final changedAt = DateTime.utc(2026, 7, 26, 9);
      final paymentAt = DateTime.utc(2026, 7, 26, 10);

      await firstTasks.create(
        TaskItem(
          id: 'task-a',
          displayNumber: 1,
          title: 'عنوان اولیه',
          priority: 1,
          status: TaskStatus.planned,
          positionInStatus: 0,
          createdAtUtc: createdAt,
          updatedAtUtc: createdAt,
        ),
      );
      await firstTasks.create(
        TaskItem(
          id: 'task-b',
          displayNumber: 2,
          title: 'کار انجام‌شده',
          priority: 3,
          status: TaskStatus.planned,
          positionInStatus: 1,
          createdAtUtc: createdAt,
          updatedAtUtc: createdAt,
        ),
      );
      await firstTasks.create(
        TaskItem(
          id: 'task-deleted',
          displayNumber: 3,
          title: 'کار حذف‌شدنی',
          priority: 0,
          status: TaskStatus.planned,
          positionInStatus: 2,
          createdAtUtc: createdAt,
          updatedAtUtc: createdAt,
        ),
      );

      await firstTasks.update(
        TaskItem(
          id: 'task-a',
          displayNumber: 1,
          title: 'کار ماندگار و ویرایش‌شده',
          priority: 2,
          status: TaskStatus.planned,
          positionInStatus: 0,
          createdAtUtc: createdAt,
          updatedAtUtc: changedAt,
        ),
      );
      await firstTasks.transition(
        id: 'task-b',
        status: TaskStatus.completed,
        targetPosition: 0,
        changedAtUtc: changedAt,
      );
      await firstTasks.delete('task-deleted');
      await firstTasks.reorderWithinStatus(
        status: TaskStatus.planned,
        orderedIds: const <String>['task-a'],
      );
      await firstTasks.reorderWithinStatus(
        status: TaskStatus.completed,
        orderedIds: const <String>['task-b'],
      );

      await firstFinance.addTransaction(
        FinanceTransaction.create(
          id: 'transaction-exact',
          type: FinanceTransactionType.income,
          title: 'درآمد دقیق',
          category: 'حقوق',
          amount: _money('1234567'),
          occurredAtUtc: createdAt,
          createdAtUtc: createdAt,
        ),
      );

      await firstFinance.addDebt(
        Debt(
          id: 'debt-restart',
          title: 'بدهی ماندگار',
          total: _money('10000000'),
          paid: _money('2500001'),
          createdAtUtc: createdAt,
          updatedAtUtc: changedAt,
        ),
      );
      await firstFinance.recordDebtPayment(
        debtId: 'debt-restart',
        amount: _money('1000001'),
        paidAt: paymentAt,
      );

      await firstFinance.addInstallmentPlan(
        InstallmentPlan(
          id: 'plan-restart',
          title: 'اقساط ماندگار',
          perInstallment: _money('3000000'),
          installmentCount: 12,
          paidCount: 1,
          createdAtUtc: createdAt,
          updatedAtUtc: changedAt,
        ),
      );
      await firstFinance.payNextInstallment(
        planId: 'plan-restart',
        paidAt: paymentAt,
      );

      expect(first.schemaVersion, 9);
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      try {
        final reopenedTasks = await DriftTaskRepository(
          second,
        ).watchAll().first;
        final reopenedFinance = DriftFinanceRepository(
          second,
          idGenerator: SequenceIdGenerator(prefix: 'reopened'),
        );
        final reopenedTransactions = await reopenedFinance
            .watchTransactions()
            .first;
        final reopenedDebts = await reopenedFinance.watchDebts().first;
        final reopenedPlans = await reopenedFinance
            .watchInstallmentPlans()
            .first;

        expect(reopenedTasks.map((task) => task.id).toList(), const <String>[
          'task-a',
          'task-b',
        ]);
        expect(reopenedTasks.first.title, 'کار ماندگار و ویرایش‌شده');
        expect(reopenedTasks.first.priority, 2);
        expect(reopenedTasks.last.isDone, isTrue);
        expect(reopenedTasks.last.completedAtUtc, changedAt);

        expect(reopenedTransactions, hasLength(1));
        expect(reopenedTransactions.single.amount.minorUnits, 1234567);
        expect(reopenedTransactions.single.amount.scale, Money.financeScale);
        expect(
          reopenedTransactions.single.amount.currencyCode,
          Money.tomanCurrencyCode,
        );

        expect(reopenedDebts, hasLength(1));
        expect(reopenedDebts.single.total.minorUnits, 10000000);
        expect(reopenedDebts.single.paid.minorUnits, 3500002);
        expect(reopenedDebts.single.remaining.minorUnits, 6499998);

        expect(reopenedPlans, hasLength(1));
        expect(reopenedPlans.single.installmentCount, 12);
        expect(reopenedPlans.single.paidCount, 2);
        expect(reopenedPlans.single.perInstallment.minorUnits, 3000000);
      } finally {
        await second.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  test('file-backed database keeps schema version nine', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-shakhsi-schema-',
    );
    final file = File('${directory.path}/schema.sqlite');

    try {
      final first = AppDatabase(NativeDatabase(file));
      expect(first.schemaVersion, 9);
      await first.close();

      final reopened = AppDatabase(NativeDatabase(file));
      try {
        expect(reopened.schemaVersion, 9);
        final versionRows = await reopened
            .customSelect('PRAGMA user_version')
            .get();
        expect(versionRows.single.read<int>('user_version'), 9);
      } finally {
        await reopened.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}

Money _money(String value) {
  return Money.parseMajorUnits(
    value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}
