import 'package:borj/app/design/design.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

String _fmt(num v) => formatPersianInteger(v.round());

Widget _number(int value, {bool animateIn = false}) =>
    AnimatedNumber(value: value, format: _fmt, animateIn: animateIn);

String _shown(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).data!;

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _number(12400),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(find.text('۱۲٬۴۰۰'), findsOneWidget);
    });
  }

  testWidgets('counts from the old value to the new one over dataUpdate', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pumpWidget(glassTestApp(_number(1000)));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _shown(tester);
    expect(mid, isNot('۰'));
    expect(mid, isNot('۱٬۰۰۰'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('۱٬۰۰۰'), findsOneWidget);
  });

  testWidgets('an update mid-roll continues from the displayed value', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pumpWidget(glassTestApp(_number(1000)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final before = _shown(tester);
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pump();
    // The first frame after the update must still show the in-flight value,
    // not jump to the old target (1000) or the new one (0).
    expect(_shown(tester), before);
    expect(before, isNot('۰'));
    expect(before, isNot('۱٬۰۰۰'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('۰'), findsOneWidget);
  });

  testWidgets('screen readers get only the final value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_number(0)));
    await tester.pumpWidget(glassTestApp(_number(1000)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('۱٬۰۰۰'), findsOneWidget);
    expect(find.bySemanticsLabel(_shown(tester)), findsNothing);
    handle.dispose();
  });

  testWidgets('animateIn counts up from zero', (tester) async {
    await tester.pumpWidget(glassTestApp(_number(1000, animateIn: true)));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _shown(tester);
    expect(mid, isNot('۱٬۰۰۰'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('۱٬۰۰۰'), findsOneWidget);
  });

  testWidgets('tabular figures; reduced motion jumps', (tester) async {
    await tester.pumpWidget(glassTestApp(_number(0), reduceMotion: true));
    await tester.pumpWidget(glassTestApp(_number(1000), reduceMotion: true));
    await tester.pump();
    expect(find.text('۱٬۰۰۰'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byType(Text)).style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
