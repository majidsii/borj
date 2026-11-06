import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_charts.dart';
import 'package:borj/features/finance/application/finance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Money toman(int value) => Money(
    minorUnits: value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );

  testWidgets('legend percentages do not overflow on huge categories', (
    tester,
  ) async {
    // 9.5e16 * 100 exceeds int64, which used to show a wrong percentage.
    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: FinanceDonutChart(
                currentMonthOnly: true,
                points: <FinanceCategoryPoint>[
                  FinanceCategoryPoint(
                    label: 'بزرگ',
                    value: toman(95000000000000000),
                  ),
                  FinanceCategoryPoint(
                    label: 'کوچک',
                    value: toman(5000000000000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('٪۹۵'), findsOneWidget);
    expect(find.text('٪۵'), findsOneWidget);
  });
}
