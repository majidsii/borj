import 'package:dashboard_shakhsi/app/apple_visual/prototype/all_glass_prototype.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('both tabs render Persian labels and the sheet opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AllGlassPrototype(fakeGlass: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('چهارشنبه ۱۳ آبان ۱۴۰۵'), findsOneWidget);
    expect(find.text('ورزش صبح'), findsOneWidget);
    expect(find.text('جلسه با تیم طراحی'), findsOneWidget);
    expect(find.text('طراحی صفحهٔ اصلی'), findsOneWidget);
    expect(find.text('پیاده‌روی'), findsOneWidget);

    await tester.tap(find.text('پول').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('خوراک'), findsOneWidget);
    expect(find.text('ناهار با علی'), findsOneWidget);
    expect(find.text('حقوق آبان'), findsOneWidget);
    expect(find.text('فصل'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('کار جدید'), findsOneWidget);
    expect(find.text('۳۰ دقیقه قبل'), findsOneWidget);
  });
}
