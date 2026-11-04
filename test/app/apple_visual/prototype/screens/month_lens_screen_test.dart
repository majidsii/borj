import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/month_lens_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month lens: labels, tap day morphs detail, month switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: MonthLensScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تقویم'), findsOneWidget);
    expect(find.text('آبان ۱۴۰۵'), findsOneWidget);
    expect(find.text('جمعه'), findsOneWidget);
    // Default selection is 13 Aban.
    expect(find.text('۱۳ آبان · چهارشنبه'), findsOneWidget);
    expect(find.text('جلسه ۱۵:۰۰'), findsOneWidget);
    expect(find.text('قسط ۴٬۲۰۰٬۰۰۰'), findsOneWidget);
    expect(find.text('پیاده‌روی ✓'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('day-6')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('۶ آبان · چهارشنبه'), findsOneWidget);
    expect(find.text('اجاره ۹٬۰۰۰٬۰۰۰'), findsOneWidget);
    expect(find.text('جلسه ۱۵:۰۰'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('آذر ۱۴۰۵'), findsOneWidget);
  });
}
