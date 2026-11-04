import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/envelopes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('envelopes carousel swaps transactions on swipe', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: EnvelopesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('پاکت‌ها'), findsOneWidget);
    expect(find.text('۷٬۵۵۰٬۰۰۰ مانده'), findsOneWidget);
    expect(find.text('۲ پرداخت این هفته'), findsOneWidget);
    expect(find.text('سوپرمارکت'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.text('اجارهٔ آبان'), findsOneWidget);
    expect(find.text('سوپرمارکت'), findsNothing);
  });
}
