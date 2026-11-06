import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/data/drift_finance_repository.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftFinanceRepository repository;

  setUp(() {
    database = openTestDatabase();
    repository = DriftFinanceRepository(
      database,
      idGenerator: SequenceIdGenerator(prefix: 'finance'),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('transactions round-trip exact eight-decimal money', () async {
    final now = DateTime.utc(2026, 7, 26, 10);
    const exact = Money(
      minorUnits: 123456712345678,
      currencyCode: Money.tomanCurrencyCode,
      scale: Money.financeScale,
    );

    final emission = repository.watchTransactions().firstWhere(
      (items) => items.length == 2,
    );

    await repository.addTransaction(
      FinanceTransaction.create(
        id: 'expense-1',
        type: FinanceTransactionType.expense,
        title: 'هزینه',
        category: 'خرید',
        amount: exact,
        occurredAtUtc: now,
        createdAtUtc: now,
      ),
    );
    await repository.addTransaction(
      FinanceTransaction.create(
        id: 'income-1',
        type: FinanceTransactionType.income,
        title: 'درآمد',
        category: 'حقوق',
        amount: exact,
        occurredAtUtc: now.add(const Duration(hours: 1)),
        createdAtUtc: now.add(const Duration(minutes: 1)),
      ),
    );

    final items = await emission;

    expect(items.map((item) => item.id).toList(), <String>[
      'income-1',
      'expense-1',
    ]);
    expect(items.first.amount, exact);
    expect(items.last.amount, exact);
    expect(items.first.type, FinanceTransactionType.income);
    expect(items.last.type, FinanceTransactionType.expense);
  });

  test('deleteTransaction removes only the requested transaction', () async {
    final now = DateTime.utc(2026, 7, 26, 11);

    for (final id in <String>['keep', 'remove']) {
      await repository.addTransaction(
        FinanceTransaction.create(
          id: id,
          type: FinanceTransactionType.expense,
          title: id,
          category: 'آزمایش',
          amount: _money(100000000),
          occurredAtUtc: now,
          createdAtUtc: now,
        ),
      );
    }

    final emission = repository.watchTransactions().firstWhere(
      (items) => items.length == 1 && items.single.id == 'keep',
    );

    await repository.deleteTransaction('remove');

    expect((await emission).single.id, 'keep');
  });

  test('watchDebts aggregates exact payment sums', () async {
    final now = DateTime.utc(2026, 7, 26, 12);

    await repository.addDebt(
      Debt(
        id: 'debt-1',
        title: 'بدهی آزمایشی',
        total: _money(1000000000),
        paid: Money.zeroIRT,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    final emission = repository.watchDebts().firstWhere(
      (items) => items.length == 1 && items.single.paid.minorUnits == 500000000,
    );

    await repository.recordDebtPayment(
      debtId: 'debt-1',
      amount: _money(325000000),
      paidAt: now.add(const Duration(days: 1)),
    );
    await repository.recordDebtPayment(
      debtId: 'debt-1',
      amount: _money(175000000),
      paidAt: now.add(const Duration(days: 2)),
    );

    final debt = (await emission).single;

    expect(debt.total, _money(1000000000));
    expect(debt.paid, _money(500000000));
    expect(debt.remaining, _money(500000000));
    expect(debt.settled, isFalse);
  });

  test('recordDebtPayment rejects amount above remaining debt', () async {
    final now = DateTime.utc(2026, 7, 26, 13);

    await repository.addDebt(
      Debt(
        id: 'debt-1',
        title: 'بدهی محدود',
        total: _money(1000000000),
        paid: Money.zeroIRT,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    await repository.recordDebtPayment(
      debtId: 'debt-1',
      amount: _money(200000000),
      paidAt: now,
    );

    await expectLater(
      repository.recordDebtPayment(
        debtId: 'debt-1',
        amount: _money(900000000),
        paidAt: now,
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.userMessage,
          'userMessage',
          'مبلغ پرداخت از مانده بدهی بیشتر است.',
        ),
      ),
    );
  });

  test('payNextInstallment inserts sequential payment numbers', () async {
    final now = DateTime.utc(2026, 7, 26, 14);

    await repository.addInstallmentPlan(
      InstallmentPlan(
        id: 'plan-1',
        title: 'اقساط آزمایشی',
        perInstallment: _money(125000000),
        installmentCount: 3,
        paidCount: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    final emission = repository.watchInstallmentPlans().firstWhere(
      (items) => items.length == 1 && items.single.paidCount == 2,
    );

    await repository.payNextInstallment(
      planId: 'plan-1',
      paidAt: now.add(const Duration(days: 1)),
    );
    await repository.payNextInstallment(
      planId: 'plan-1',
      paidAt: now.add(const Duration(days: 2)),
    );

    final plan = (await emission).single;
    expect(plan.paidCount, 2);
    expect(plan.remainingCount, 1);
    expect(plan.paid, _money(250000000));
    expect(plan.remaining, _money(125000000));

    final rows = await database.select(database.installmentPaymentRows).get();
    rows.sort(
      (left, right) =>
          left.installmentNumber.compareTo(right.installmentNumber),
    );

    expect(rows.map((row) => row.installmentNumber).toList(), <int>[1, 2]);
    expect(rows.map((row) => row.id).toList(), <String>[
      'finance-1',
      'finance-2',
    ]);
  });

  test('fully paid installment plan rejects another payment', () async {
    final now = DateTime.utc(2026, 7, 26, 15);

    await repository.addInstallmentPlan(
      InstallmentPlan(
        id: 'plan-1',
        title: 'یک قسط',
        perInstallment: _money(500000000),
        installmentCount: 1,
        paidCount: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    await repository.payNextInstallment(planId: 'plan-1', paidAt: now);

    await expectLater(
      repository.payNextInstallment(
        planId: 'plan-1',
        paidAt: now.add(const Duration(days: 1)),
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.userMessage,
          'userMessage',
          'همه اقساط این برنامه پرداخت شده‌اند.',
        ),
      ),
    );
  });

  test('deleting parents cascades to their payment rows', () async {
    final now = DateTime.utc(2026, 7, 26, 16);

    await repository.addDebt(
      Debt(
        id: 'debt-1',
        title: 'بدهی',
        total: _money(1000000000),
        paid: Money.zeroIRT,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.recordDebtPayment(
      debtId: 'debt-1',
      amount: _money(100000000),
      paidAt: now,
    );

    await repository.addInstallmentPlan(
      InstallmentPlan(
        id: 'plan-1',
        title: 'قسط',
        perInstallment: _money(100000000),
        installmentCount: 2,
        paidCount: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.payNextInstallment(planId: 'plan-1', paidAt: now);

    expect(await database.select(database.debtPaymentRows).get(), hasLength(1));
    expect(
      await database.select(database.installmentPaymentRows).get(),
      hasLength(1),
    );

    await repository.deleteDebt('debt-1');
    await repository.deleteInstallmentPlan('plan-1');

    expect(await database.select(database.debtPaymentRows).get(), isEmpty);
    expect(
      await database.select(database.installmentPaymentRows).get(),
      isEmpty,
    );
  });

  test('recordDebtPayment refuses a payment sum above int64', () async {
    final now = DateTime.utc(2026, 11, 4);
    await database
        .into(database.debtRows)
        .insert(
          DebtRowsCompanion.insert(
            id: 'debt-huge',
            title: 'بزرگ',
            totalMinorUnits: 9000000000000000000,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    for (final entry in <(String, int)>[
      ('pay-a', 5000000000000000000),
      ('pay-b', 4900000000000000000),
    ]) {
      await database
          .into(database.debtPaymentRows)
          .insert(
            DebtPaymentRowsCompanion.insert(
              id: entry.$1,
              debtId: 'debt-huge',
              amountMinorUnits: entry.$2,
              paidAtUtc: now,
              createdAtUtc: now,
            ),
          );
    }

    await expectLater(
      repository.recordDebtPayment(
        debtId: 'debt-huge',
        amount: _money(1),
        paidAt: now,
      ),
      throwsA(isA<MoneyOverflowFailure>()),
    );
  });
}

Money _money(int minorUnits) {
  return Money(
    minorUnits: minorUnits,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}
