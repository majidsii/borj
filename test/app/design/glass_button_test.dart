import 'package:borj/app/design/design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders every variant without errors (${v.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassButton(onPressed: () {}, label: 'ذخیره'),
              GlassButton(
                onPressed: () {},
                label: 'ذخیره',
                variant: GlassButtonVariant.tinted,
              ),
              GlassButton(
                onPressed: () {},
                label: 'لغو',
                variant: GlassButtonVariant.plain,
              ),
              GlassButton(
                onPressed: () {},
                icon: Icons.add,
                semanticLabel: 'افزودن',
              ),
            ],
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ذخیره'), findsNWidgets(2));
    });
  }

  testWidgets('tap, disabled, keyboard', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      glassTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassButton(onPressed: () => taps++, label: 'یک'),
            const GlassButton(onPressed: null, label: 'دو'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('یک'));
    await tester.tap(find.text('دو'));
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
  });

  testWidgets('press scales to 0.97 on pointer-down and back on up', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(GlassButton(onPressed: () {}, label: 'یک')),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('یک')),
    );
    await tester.pump(const Duration(milliseconds: 130));
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.97,
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('reduced motion: press only fades', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        GlassButton(onPressed: () {}, label: 'یک'),
        reduceMotion: true,
      ),
    );
    late TestGesture gesture;
    await expectNoMovement(
      tester,
      within: find.byType(GlassButton),
      trigger: () async => gesture = await tester.startGesture(
        tester.getCenter(find.text('یک')),
      ),
    );
    expect(find.byType(AnimatedScale), findsNothing);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.7,
    );
    await gesture.up();
  });

  testWidgets('on glass: chrome is flat GlassInner, no nested glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        AppGlass(
          role: GlassRole.panel,
          shape: const AppleGlassShape.rounded(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassButton(onPressed: () {}, label: 'ویرایش'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });

  testWidgets('off glass: chrome and tinted are AppGlass', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassButton(onPressed: () {}, label: 'a'),
            GlassButton(
              onPressed: () {},
              label: 'b',
              variant: GlassButtonVariant.tinted,
            ),
          ],
        ),
      ),
    );
    final roles = tester
        .widgetList<AppGlass>(find.byType(AppGlass))
        .map((g) => g.role)
        .toList();
    expect(roles, [GlassRole.chrome, GlassRole.tinted]);
  });

  testWidgets('hit target ≥ 44 and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      glassTestApp(
        GlassButton(onPressed: () {}, icon: Icons.add, semanticLabel: 'افزودن'),
      ),
    );
    final size = tester.getSize(find.byType(GlassButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(find.byType(GlassButton)),
      matchesSemantics(
        label: 'افزودن',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('hover highlight only for a mouse', (tester) async {
    await tester.pumpWidget(
      glassTestApp(GlassButton(onPressed: () {}, label: 'یک')),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('یک')));
    await tester.pump();
    expect(find.byKey(const ValueKey('pressable-hover')), findsOneWidget);
    await mouse.removePointer();
  });
}
