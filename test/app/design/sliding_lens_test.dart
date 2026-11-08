import 'dart:math' as math;

import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Widget _lens(Rect target, {bool reduceMotion = false}) => glassTestApp(
  reduceMotion: reduceMotion,
  SizedBox(
    width: 400,
    height: 100,
    child: Stack(
      children: [
        SlidingLens(
          key: const ValueKey('lens'),
          target: target,
          axis: Axis.horizontal,
          shape: const AppleGlassShape.capsule(),
        ),
      ],
    ),
  ),
);

void main() {
  const a = Rect.fromLTWH(0, 4, 100, 54);
  const b = Rect.fromLTWH(200, 4, 100, 54);
  final lens = find.byKey(const ValueKey('lens'));
  Rect painted(WidgetTester tester) => tester.getRect(
    find.descendant(of: lens, matching: find.byType(GlassInner)),
  );

  testWidgets('sits on its target', (tester) async {
    await tester.pumpWidget(_lens(a));
    expect(painted(tester).size, a.size);
  });

  testWidgets('slides to a new target, stretching at most 12 % mid-way', (
    tester,
  ) async {
    await tester.pumpWidget(_lens(a));
    final origin = painted(tester).topLeft;
    await tester.pumpWidget(_lens(b));
    var maxWidth = 0.0;
    var sawMiddle = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final r = painted(tester);
      maxWidth = math.max(maxWidth, r.width);
      if (r.left > origin.dx + 40 && r.left < origin.dx + 160) sawMiddle = true;
    }
    expect(sawMiddle, isTrue, reason: 'the lens must travel, not jump');
    expect(maxWidth, greaterThan(100.5));
    expect(maxWidth, lessThanOrEqualTo(112.0 + 0.01));
    await tester.pumpAndSettle();
    expect(painted(tester).width, closeTo(100, 0.01));
    expect(painted(tester).left - origin.dx, closeTo(200, 0.01));
  });

  testWidgets('reduce motion: jumps', (tester) async {
    await tester.pumpWidget(_lens(a, reduceMotion: true));
    final origin = painted(tester).topLeft;
    await tester.pumpWidget(_lens(b, reduceMotion: true));
    await tester.pump();
    expect(painted(tester).left - origin.dx, closeTo(200, 0.01));
    expect(painted(tester).width, closeTo(100, 0.01));
  });

  testWidgets('interrupted mid-way continues from the painted rect', (
    tester,
  ) async {
    await tester.pumpWidget(_lens(a));
    await tester.pumpWidget(_lens(b));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final before = painted(tester);
    await tester.pumpWidget(_lens(a));
    await tester.pump(const Duration(milliseconds: 16));
    final after = painted(tester);
    expect((after.center.dx - before.center.dx).abs(), lessThan(30));
  });
}
