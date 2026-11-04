import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/wallet_stack_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wallet deck selects a card and shows its transactions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: WalletStackScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('کیف پول'), findsOneWidget);
    expect(find.text('۲۱٬۴۰۰٬۰۰۰'), findsOneWidget);
    expect(find.text('ناهار با علی'), findsNothing);

    await tester.tap(find.text('کارت ملت'));
    await tester.pumpAndSettle();
    expect(find.text('ناهار با علی'), findsOneWidget);
    expect(find.text('حقوق آبان'), findsOneWidget);

    await tester.tap(find.text('کارت ملت'));
    await tester.pumpAndSettle();
    expect(find.text('ناهار با علی'), findsNothing);
  });
}
