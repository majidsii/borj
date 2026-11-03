import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_finance_repository.dart';

void main() {
  testWidgets('a report sum above int64 shows an out-of-range notice', (
    tester,
  ) async {
    final repository = MemoryFinanceRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });

    final now = DateTime.now().toUtc();
    const huge = Money(
      minorUnits: 6000000000000000000,
      currencyCode: Money.tomanCurrencyCode,
      scale: Money.financeScale,
    );
    repository.seed(
      transactions: <FinanceTransaction>[
        for (final id in <String>['a', 'b'])
          FinanceTransaction.create(
            id: id,
            type: FinanceTransactionType.income,
            title: 'درآمد $id',
            category: 'حقوق',
            amount: huge,
            occurredAtUtc: now,
            createdAtUtc: now,
          ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('finance-out-of-range')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
