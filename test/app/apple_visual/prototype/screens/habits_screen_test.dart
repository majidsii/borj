import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/habits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('habits: drop completes a habit and heat-map switches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HabitsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عادت‌ها'), findsOneWidget);
    expect(find.text('پیاده‌روی'), findsOneWidget);
    expect(find.text('۱۲ روز پیاپی'), findsOneWidget);
    expect(find.text('۱۵ از ۲۰ دقیقه'), findsOneWidget);
    expect(find.text('۴ از ۸ لیوان'), findsOneWidget);
    expect(find.text('دیروز انجام نشد'), findsOneWidget);
    expect(find.text('آبان ۱۴۰۵ · پیاده‌روی'), findsOneWidget);

    // Water button is the second "add" icon (book, water).
    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('۴ از ۸ لیوان'), findsOneWidget); // bead still in flight
    await tester.pumpAndSettle();
    expect(find.text('۵ از ۸ لیوان'), findsOneWidget);

    await tester.tap(find.text('مدیتیشن'));
    await tester.pumpAndSettle();
    expect(find.text('آبان ۱۴۰۵ · مدیتیشن'), findsOneWidget);
    expect(find.text('آبان ۱۴۰۵ · پیاده‌روی'), findsNothing);
  });
}
