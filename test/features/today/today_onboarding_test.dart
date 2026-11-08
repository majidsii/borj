import 'package:borj/app/design/design.dart';
import 'package:borj/features/today/presentation/today_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Widget _app({
  VoidCallback? onAdd,
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  brightness: b,
  textScale: s,
  SizedBox(
    width: 390,
    child: SingleChildScrollView(
      child: TodayOnboarding(onAddTask: onAdd ?? () {}),
    ),
  ),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(_app(b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the welcome, the task step and the footer only', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('روز تازه‌ای است'), findsOneWidget);
    expect(find.text('اولین کار را بنویس'), findsOneWidget);
    expect(find.text('افزودن کار'), findsOneWidget);
    expect(
      find.text('هر وقت خواستی، با دکمهٔ مثبت بالا چیزی اضافه کن.'),
      findsOneWidget,
    );
    expect(find.text('اولین حساب را بساز'), findsNothing);
    expect(find.text('یک عادت شروع کن'), findsNothing);
  });

  testWidgets('tapping the add button calls onAddTask', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onAdd: () => taps++));
    await tester.tap(find.byKey(const ValueKey('onboarding-add-task')));
    expect(taps, 1);
  });

  testWidgets('button is flat GlassInner; exactly two AppGlass cards', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-add-task')),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppGlass), findsNWidgets(2));
  });

  testWidgets('hit target is >= 44 tall while the pill stays 36', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final hit = tester.getSize(
      find.byKey(const ValueKey('onboarding-add-task')),
    );
    expect(hit.height, greaterThanOrEqualTo(44));
    final pill = tester.getSize(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-add-task')),
        matching: find.byType(GlassInner),
      ),
    );
    expect(pill.height, 36);
  });
}
