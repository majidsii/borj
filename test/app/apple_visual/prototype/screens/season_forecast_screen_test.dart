import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/season_forecast_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wallpaper drifts forever, so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('forecast, season switch and sheet detents', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SeasonForecastScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('آبان'), findsOneWidget);
    expect(find.text('۱۹٫۱ میلیون'), findsOneWidget);
    for (final s in <String>['بهار', 'تابستان', 'پاییز', 'زمستان']) {
      expect(find.text(s), findsOneWidget);
    }
    expect(find.text('قسط وام ۱۰ آذر'), findsOneWidget);

    // Season switch animates the wallpaper and settles.
    await tester.tap(find.text('زمستان'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('بهار'));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    // Sheet snaps between detents.
    final controller = tester
        .widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet))
        .controller!;
    expect(controller.size, closeTo(0.28, 0.01));
    await tester.tap(find.text('برنامهٔ مالی آبان'));
    await settle(tester);
    expect(controller.size, closeTo(0.6, 0.01));
    await tester.drag(find.text('برنامهٔ مالی آبان'), const Offset(0, -400));
    await settle(tester);
    expect(controller.size, closeTo(0.92, 0.01));
  });
}
