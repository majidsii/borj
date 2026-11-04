import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/rings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rings screen renders and the disc splits into capsules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: RingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('خلاصه'), findsOneWidget);
    expect(find.text('۱۲ روز پیاپی پیاده‌روی'), findsOneWidget);
    expect(find.text('خرج امروز زیر بودجه'), findsOneWidget);
    expect(find.text('۳ از ۵'), findsNothing);

    await tester.tap(find.text('۱۳ آبان'));
    await tester.pumpAndSettle();
    expect(find.text('۳ از ۵'), findsOneWidget);
    expect(find.text('۲ از ۴'), findsOneWidget);
    expect(find.text('۴۵۰ هزار'), findsOneWidget);

    await tester.tap(find.text('۱۳ آبان'));
    await tester.pumpAndSettle();
    expect(find.text('۳ از ۵'), findsNothing);
  });
}
