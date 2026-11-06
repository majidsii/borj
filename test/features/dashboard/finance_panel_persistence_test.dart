import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_finance_repository.dart';

void main() {
  late MemoryFinanceRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MemoryFinanceRepository();
    container = ProviderContainer(
      overrides: <Override>[
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: SizedBox(width: 780, child: FinancePanel()),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> flushUiAction(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await flushUiAction(tester);
  }

  Finder field(String key) {
    return find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(TextField),
    );
  }

  Finder fieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byKey(const ValueKey<String>('finance-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await flushUiAction(tester);
  }

  testWidgets(
    'repository stream updates cards objects and recent transactions exactly',
    (tester) async {
      await pumpSubject(tester);

      final now = DateTime.now().toUtc();
      await container
          .read(financeRepositoryProvider)
          .addTransaction(
            FinanceTransaction.create(
              id: 'income-exact',
              type: FinanceTransactionType.income,
              title: 'درآمد ذخیره‌شده',
              category: 'حقوق',
              amount: _money('1234567'),
              occurredAtUtc: now,
              createdAtUtc: now,
            ),
          );
      await container
          .read(financeRepositoryProvider)
          .addDebt(
            Debt(
              id: 'debt-saved',
              title: 'بدهی ذخیره‌شده',
              total: _money('10000000'),
              paid: _money('2500000'),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await container
          .read(financeRepositoryProvider)
          .addInstallmentPlan(
            InstallmentPlan(
              id: 'plan-saved',
              title: 'قسط ذخیره‌شده',
              perInstallment: _money('3000000'),
              installmentCount: 12,
              paidCount: 2,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      await flushUiAction(tester);

      expect(find.text('درآمد ذخیره‌شده'), findsOneWidget);
      expect(find.text('+۱٬۲۳۴٬۵۶۷'), findsOneWidget);
      expect(find.text('۱٬۲۳۴٬۵۶۷'), findsWidgets);
      expect(find.text('بدهی ذخیره‌شده'), findsOneWidget);
      expect(find.text('قسط ذخیره‌شده'), findsOneWidget);
      expect(find.text('۲ از ۱۲ قسط پرداخت شده'), findsOneWidget);
    },
  );

  testWidgets('finance forms write exact transactions debts and installments', (
    tester,
  ) async {
    await pumpSubject(tester);

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('finance-type-income')),
    );
    await tester.enterText(field('finance-title-field'), 'درآمد دقیق رابط');
    await tester.enterText(field('finance-amount-field'), '1234567');
    await submit(tester);

    expect(repository.transactions, hasLength(1));
    expect(repository.transactions.single.amount.minorUnits, 1234567);
    expect(repository.transactions.single.type, FinanceTransactionType.income);

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('finance-type-debt')),
    );
    await tester.enterText(field('finance-title-field'), 'بدهی رابط');
    await tester.enterText(field('finance-amount-field'), '10000001');
    await tester.enterText(field('finance-debt-paid-field'), '2500001');
    await submit(tester);

    expect(repository.debts, hasLength(1));
    expect(repository.debts.single.total.minorUnits, 10000001);
    expect(repository.debts.single.paid.minorUnits, 2500001);

    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('finance-type-installment')),
    );
    await tester.enterText(field('finance-title-field'), 'قسط رابط');
    await tester.enterText(field('finance-amount-field'), '3000001');
    await tester.enterText(field('finance-installment-count-field'), '12');
    await tester.enterText(field('finance-installment-paid-field'), '2');
    await submit(tester);

    expect(repository.installments, hasLength(1));
    expect(repository.installments.single.perInstallment.minorUnits, 3000001);
    expect(repository.installments.single.installmentCount, 12);
    expect(repository.installments.single.paidCount, 2);
  });

  testWidgets('payment and delete controls call the finance repository', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    repository.seed(
      transactions: <FinanceTransaction>[
        FinanceTransaction.create(
          id: 'delete-transaction',
          type: FinanceTransactionType.expense,
          title: 'تراکنش قابل حذف',
          category: 'خرید',
          amount: _money('6900000'),
          occurredAtUtc: now,
          createdAtUtc: now,
        ),
      ],
      debts: <Debt>[
        Debt(
          id: 'pay-debt',
          title: 'بدهی قابل پرداخت',
          total: _money('10000000'),
          paid: _money('2500000'),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      installments: <InstallmentPlan>[
        InstallmentPlan(
          id: 'pay-plan',
          title: 'قسط قابل پرداخت',
          perInstallment: _money('3000000'),
          installmentCount: 12,
          paidCount: 2,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
    );

    await pumpSubject(tester);

    final openDebtPayment = find.bySemanticsLabel(
      'ثبت پرداخت برای بدهی قابل پرداخت',
    );
    await tester.ensureVisible(openDebtPayment);
    await tester.tap(openDebtPayment);
    await flushUiAction(tester);

    await tester.enterText(fieldWithHint('مبلغ پرداخت‌شده'), '1000000');
    final applyDebtPayment = find.text('ثبت').last;
    await tester.ensureVisible(applyDebtPayment);
    await tester.tap(applyDebtPayment);
    await flushUiAction(tester);

    expect(repository.debts.single.paid.minorUnits, 3500000);

    final payInstallment = find.bySemanticsLabel(
      'پرداخت یک قسط برای قسط قابل پرداخت',
    );
    await tester.ensureVisible(payInstallment);
    await tester.tap(payInstallment);
    await flushUiAction(tester);

    expect(repository.installments.single.paidCount, 3);

    final deleteTransaction = find.bySemanticsLabel('حذف تراکنش');
    await tester.ensureVisible(deleteTransaction);
    await tester.tap(deleteTransaction);
    await flushUiAction(tester);

    expect(repository.transactions, isEmpty);

    final deleteDebt = find.bySemanticsLabel('حذف بدهی بدهی قابل پرداخت');
    await tester.ensureVisible(deleteDebt);
    await tester.tap(deleteDebt);
    await flushUiAction(tester);

    expect(repository.debts, isEmpty);

    final deletePlan = find.bySemanticsLabel('حذف قسط قسط قابل پرداخت');
    await tester.ensureVisible(deletePlan);
    await tester.tap(deletePlan);
    await flushUiAction(tester);

    expect(repository.installments, isEmpty);
  });
}

Money _money(String value) {
  return Money.parseMajorUnits(
    value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}
