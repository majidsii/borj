import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/focus_timer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('focus timer: split controls, countdown, merge, presets', (
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
          child: FocusTimerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تمرکز'), findsOneWidget);
    expect(find.text('طراحی صفحهٔ اصلی'), findsOneWidget);
    expect(find.text('۲۵:۰۰'), findsOneWidget);
    expect(find.text('شروع'), findsOneWidget);
    expect(find.text('پایان'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('preset-2')));
    await tester.pumpAndSettle();
    expect(find.text('۵۰:۰۰'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('primary-button')));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('۴۹:۵۷'), findsOneWidget);
    expect(find.text('توقف'), findsOneWidget);
    expect(find.text('پایان'), findsOneWidget);

    // Stop: circles merge back into one, timer is cancelled.
    await tester.tap(find.byKey(const ValueKey<String>('primary-button')));
    await tester.pumpAndSettle();
    expect(find.text('پایان'), findsNothing);
    expect(find.text('ادامه'), findsOneWidget);
    expect(find.text('۴۹:۵۷'), findsOneWidget);

    // Resume, then finish: a session is recorded and the timer resets.
    await tester.tap(find.byKey(const ValueKey<String>('primary-button')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey<String>('finish-button')));
    await tester.pumpAndSettle();
    expect(find.text('شروع'), findsOneWidget);
    expect(find.text('۵۰:۰۰'), findsOneWidget);
    expect(find.text('۱۴:۳۰'), findsOneWidget);
  });
}
