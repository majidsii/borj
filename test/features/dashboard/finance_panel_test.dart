import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_panel.dart';
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

  Finder field(String key) {
    return find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(TextField),
    );
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byKey(const ValueKey<String>('finance-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await flushUiAction(tester);
  }

  testWidgets('adds an expense and updates summaries and recent transactions', (
    tester,
  ) async {
    await pumpSubject(tester);

    await tester.enterText(field('finance-title-field'), 'خرید هفتگی');
    await tester.enterText(field('finance-amount-field'), '6900000');
    await submit(tester);

    expect(find.text('خرید هفتگی'), findsOneWidget);
    expect(find.text('۶٬۹۰۰٬۰۰۰'), findsOneWidget);
    expect(find.text('−۶٬۹۰۰٬۰۰۰'), findsNWidgets(2));
    expect(
      find.text('⚠️ هزینه‌های این ماه از درآمد بیشتر است'),
      findsOneWidget,
    );
  });

  testWidgets('adds a partially paid debt and shows the remaining amount', (
    tester,
  ) async {
    await pumpSubject(tester);

    await tester.tap(find.byKey(const ValueKey<String>('finance-type-debt')));
    await flushUiAction(tester);
    await tester.enterText(field('finance-title-field'), 'قرض از علی');
    await tester.enterText(field('finance-amount-field'), '10000000');
    await tester.enterText(field('finance-debt-paid-field'), '2500000');
    await submit(tester);

    expect(find.text('قرض از علی'), findsOneWidget);
    expect(find.text('۷٬۵۰۰٬۰۰۰'), findsOneWidget);
    expect(
      find.text('پرداخت‌شده ۲٬۵۰۰٬۰۰۰ از ۱۰٬۰۰۰٬۰۰۰ تومان'),
      findsOneWidget,
    );
  });

  testWidgets('adds an installment plan and advances one installment', (
    tester,
  ) async {
    await pumpSubject(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('finance-type-installment')),
    );
    await flushUiAction(tester);
    await tester.enterText(field('finance-title-field'), 'قسط خودرو');
    await tester.enterText(field('finance-amount-field'), '3000000');
    await tester.enterText(field('finance-installment-count-field'), '12');
    await tester.enterText(field('finance-installment-paid-field'), '2');
    await submit(tester);

    expect(find.text('قسط خودرو'), findsOneWidget);
    expect(find.text('۲ از ۱۲ قسط پرداخت شده'), findsOneWidget);
    expect(find.text('۳۰٬۰۰۰٬۰۰۰'), findsOneWidget);

    final payInstallment = find.bySemanticsLabel(
      'پرداخت یک قسط برای قسط خودرو',
    );
    await tester.ensureVisible(payInstallment);
    await tester.tap(payInstallment);
    await flushUiAction(tester);

    expect(find.text('۳ از ۱۲ قسط پرداخت شده'), findsOneWidget);
    expect(find.text('۲۷٬۰۰۰٬۰۰۰'), findsOneWidget);
  });

  testWidgets('renders the original three finance chart surfaces', (
    tester,
  ) async {
    await pumpSubject(tester);

    expect(
      find.byKey(const ValueKey<String>('finance-trend-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('finance-donut-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('finance-week-chart')),
      findsOneWidget,
    );
  });

  testWidgets('formats whole-toman money live', (tester) async {
    await pumpSubject(tester);

    await tester.enterText(field('finance-title-field'), 'درآمد دقیق');
    await tester.enterText(field('finance-amount-field'), '1234567');

    final amountField = tester.widget<TextField>(field('finance-amount-field'));
    expect(amountField.controller?.text, '۱٬۲۳۴٬۵۶۷');

    await tester.tap(find.byKey(const ValueKey<String>('finance-type-income')));
    await flushUiAction(tester);
    await submit(tester);

    expect(find.text('۱٬۲۳۴٬۵۶۷'), findsWidgets);
    expect(find.text('+۱٬۲۳۴٬۵۶۷'), findsOneWidget);
  });
}
