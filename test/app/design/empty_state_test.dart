import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';

void main() {
  Widget state({
    bool reduce = false,
    VoidCallback? onAction,
    Brightness b = Brightness.light,
    double s = 1.0,
  }) => glassTestApp(
    reduceMotion: reduce,
    brightness: b,
    textScale: s,
    EmptyState(
      icon: Icons.inbox_outlined,
      title: 'هنوز چیزی نیست',
      message: 'به‌زودی',
      actionLabel: 'افزودن',
      onAction: onAction ?? () {},
    ),
  );

  GlassVisibility buttonVisibility(WidgetTester tester) =>
      tester.widget<GlassVisibility>(
        find
            .ancestor(
              of: find.byType(GlassButton),
              matching: find.byType(GlassVisibility),
            )
            .first,
      );

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(state(b: v.brightness, s: v.textScale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('هنوز چیزی نیست'), findsOneWidget);
    });
  }

  testWidgets('fades in with quick; the button fades through GlassVisibility', (
    tester,
  ) async {
    await tester.pumpWidget(state());
    await tester.pump(const Duration(milliseconds: 100));
    expect(buttonVisibility(tester).value, inExclusiveRange(0.0, 1.0));
    expect(bareFadesAboveGlass(tester, find.byType(EmptyState)), isEmpty);
    await tester.pumpAndSettle();
    expect(buttonVisibility(tester).value, 1.0);
  });

  testWidgets('Reduce Motion: fades over reduced, no movement', (tester) async {
    await tester.pumpWidget(state(reduce: true));
    final before = tester.getTopLeft(find.text('هنوز چیزی نیست'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(buttonVisibility(tester).value, inExclusiveRange(0.0, 1.0));
    expect(tester.getTopLeft(find.text('هنوز چیزی نیست')), before);
    expect(bareFadesAboveGlass(tester, find.byType(EmptyState)), isEmpty);
    await tester.pumpAndSettle();
    expect(buttonVisibility(tester).value, 1.0);
  });

  testWidgets('action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(state(onAction: () => tapped = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('افزودن'));
    expect(tapped, isTrue);
  });
}
