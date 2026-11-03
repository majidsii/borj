import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const oneToman = Money(
    minorUnits: 100000000,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
  final createdAt = DateTime.utc(2026, 7, 26, 10);
  final updatedAt = DateTime.utc(2026, 7, 26, 11);

  test('transaction rejects a zero amount', () {
    expect(
      () => FinanceTransaction.create(
        id: 'tx-1',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: Money.zeroIRT,
        occurredAtUtc: createdAt,
        createdAtUtc: createdAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'transaction trims labels and preserves an exact eight-decimal amount',
    () {
      const amount = Money(
        minorUnits: 12345678901,
        currencyCode: Money.tomanCurrencyCode,
        scale: Money.financeScale,
      );

      final transaction = FinanceTransaction.create(
        id: 'tx-1',
        type: FinanceTransactionType.income,
        title: '  حقوق  ',
        category: '  درآمد  ',
        amount: amount,
        occurredAtUtc: createdAt,
        createdAtUtc: createdAt,
      );

      expect(transaction.title, 'حقوق');
      expect(transaction.category, 'درآمد');
      expect(transaction.amount, amount);
      expect(transaction.isIncome, isTrue);
      expect(transaction.updatedAtUtc, createdAt);
    },
  );

  test('transaction rejects a non-toman currency definition', () {
    const invalidMoney = Money(
      minorUnits: 100000000,
      currencyCode: 'USD',
      scale: Money.financeScale,
    );

    expect(
      () => FinanceTransaction.create(
        id: 'tx-1',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: invalidMoney,
        occurredAtUtc: createdAt,
        createdAtUtc: createdAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('transaction rejects local persistence timestamps', () {
    expect(
      () => FinanceTransaction.create(
        id: 'tx-1',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: oneToman,
        occurredAtUtc: DateTime(2026, 7, 26),
        createdAtUtc: createdAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('debt exposes an exact remaining amount and chart progress', () {
    final debt = Debt(
      id: 'debt-1',
      title: 'قرض',
      total: oneToman * 10,
      paid: oneToman * 3,
      createdAtUtc: createdAt,
      updatedAtUtc: updatedAt,
    );

    expect(debt.remaining, oneToman * 7);
    expect(debt.settled, isFalse);
    expect(debt.progressForChart, closeTo(0.3, 0.000000001));
  });

  test('debt rejects a paid amount greater than its total', () {
    expect(
      () => Debt(
        id: 'debt-1',
        title: 'قرض',
        total: oneToman * 2,
        paid: oneToman * 3,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('installment plan rejects paid count over total count', () {
    expect(
      () => InstallmentPlan(
        id: 'plan-1',
        title: 'قسط',
        perInstallment: oneToman,
        installmentCount: 2,
        paidCount: 3,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('installment plan calculates exact remaining value', () {
    final plan = InstallmentPlan(
      id: 'plan-1',
      title: 'قسط خودرو',
      perInstallment: oneToman * 5,
      installmentCount: 12,
      paidCount: 4,
      createdAtUtc: createdAt,
      updatedAtUtc: updatedAt,
    );

    expect(plan.remainingCount, 8);
    expect(plan.remaining, oneToman * 40);
    expect(plan.settled, isFalse);
    expect(plan.progressForChart, closeTo(4 / 12, 0.000000001));
  });

  test('transaction rejects a legacy scale-8 amount', () {
    const legacy = Money(
      minorUnits: 100000000,
      currencyCode: Money.tomanCurrencyCode,
      scale: 8,
    );

    expect(
      () => FinanceTransaction.create(
        id: 'tx-legacy',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: legacy,
        occurredAtUtc: createdAt,
        createdAtUtc: createdAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('installment plan rejects a total above int64', () {
    expect(
      () => InstallmentPlan(
        id: 'plan-huge',
        title: 'بزرگ',
        perInstallment: const Money(
          minorUnits: 1000000000000000,
          currencyCode: Money.tomanCurrencyCode,
          scale: Money.financeScale,
        ),
        installmentCount: 10000,
        paidCount: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
