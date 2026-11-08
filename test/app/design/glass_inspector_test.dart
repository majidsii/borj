import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _host({
  required bool open,
  bool reduce = false,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) => glassTestApp(
  brightness: brightness,
  textScale: textScale,
  reduceMotion: reduce,
  SizedBox(
    width: 1200,
    height: 800,
    child: Stack(
      children: [
        PositionedDirectional(
          end: 8,
          top: 8,
          bottom: 8,
          width: GlassInspector.width,
          child: GlassInspector(
            open: open,
            child: const Center(child: Text('جزئیات')),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('closed builds no glass', (tester) async {
    await tester.pumpWidget(_host(open: false));
    expect(find.byKey(const ValueKey('inspector')), findsNothing);
    expect(find.byType(AppGlass), findsNothing);
  });

  testWidgets('RTL: slides in from the left edge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(open: false));
    await tester.pumpWidget(_host(open: true));
    await tester.pump(const Duration(milliseconds: 48));
    final mid = tester.getRect(find.byKey(const ValueKey('inspector')));
    await tester.pumpAndSettle();
    final rest = tester.getRect(find.byKey(const ValueKey('inspector')));
    expect(mid.left, lessThan(rest.left), reason: 'comes from the left in RTL');
    expect(rest.width, GlassInspector.width);
  });

  testWidgets('closes faster than it opens and then builds nothing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(open: true));
    await tester.pumpAndSettle();
    final rest = tester.getRect(find.byKey(const ValueKey('inspector'))).left;
    final travel = GlassInspector.width + 16;
    final closeTime = SpringCurve(AppMotion.standard).duration * 0.7;
    await tester.pumpWidget(_host(open: false));
    await tester.pump();
    await tester.pump(closeTime * 0.25);
    final moved =
        rest - tester.getRect(find.byKey(const ValueKey('inspector'))).left;
    expect(
      moved,
      greaterThan(travel * 0.25),
      reason: 'the close eases out: fast start',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inspector')), findsNothing);
  });

  testWidgets('reduce motion: no movement, visibility fades', (tester) async {
    await tester.pumpWidget(_host(open: false, reduce: true));
    await expectNoMovement(
      tester,
      within: find.byType(GlassInspector),
      trigger: () async {
        await tester.pumpWidget(_host(open: true, reduce: true));
        await tester.pump();
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('جزئیات'), findsOneWidget);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(open: true, brightness: v.brightness, textScale: v.textScale),
      );
      await tester.pumpAndSettle();
      expect(find.text('جزئیات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
