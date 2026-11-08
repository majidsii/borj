// ignore_for_file: invalid_use_of_internal_member
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:liquid_glass_renderer/src/internal/backdrop_seed.dart';

import '../../support/backdrop_capture_log.dart';
import '../../support/backdrop_layer_count.dart';
import '../../support/glass_fade_expectations.dart';
import '../../support/glass_material_expectations.dart';
import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

void main() {
  // Dedicated and first: the renderer prints its bare-fade warning once per
  // isolate, so this must be the first test that could trigger it.
  testWidgets('disabled and pressed glass never bare-fades', (tester) async {
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        glassTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassButton(onPressed: () {}, label: 'یک'),
              const GlassButton(onPressed: null, label: 'دو'),
            ],
          ),
          reduceMotion: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('یک')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.up();
      await tester.pumpAndSettle();
    });
    expect(record.bareFadeWarned, isFalse);
  });

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
    // Glass fades through GlassVisibility (glass and label together), never
    // through a parent opacity.
    expect(find.byType(AnimatedOpacity), findsNothing);
    await tester.pump(AppMotion.reduced.duration);
    expect(GlassVisibility.of(tester.element(find.byType(AppGlass))), 0.7);
    expect(bareFadesAboveGlass(tester, find.byType(GlassButton)), isEmpty);
    await gesture.up();
    await tester.pump();
    await tester.pump(AppMotion.reduced.duration);
    expect(GlassVisibility.of(tester.element(find.byType(AppGlass))), 1);
  });

  group('disabled glass', () {
    tearDown(() => SeededBackdropPassLayer.debugModeOverride = null);

    for (final seed in [BackdropSeed.none, BackdropSeed.identity]) {
      testWidgets('captures like the enabled button (seed ${seed.name})', (
        tester,
      ) async {
        SeededBackdropPassLayer.debugModeOverride = seed;
        Widget app({required bool enabled}) => glassTestApp(
          GlassButton(onPressed: enabled ? () {} : null, label: 'یک'),
        );
        await tester.pumpWidget(app(enabled: true));
        final enabled = countCompositedBackdrops(tester);
        await tester.pumpWidget(app(enabled: false));
        expect(countCompositedBackdrops(tester), enabled);
        expect(bareFadesAboveGlass(tester, find.byType(GlassButton)), isEmpty);
        expect(GlassVisibility.of(tester.element(find.byType(AppGlass))), 0.4);
      });
    }

    testWidgets('same wrapper structure enabled and disabled', (tester) async {
      Widget app({required bool enabled}) => glassTestApp(
        GlassButton(onPressed: enabled ? () {} : null, label: 'یک'),
      );
      await tester.pumpWidget(app(enabled: true));
      final before = find
          .descendant(
            of: find.byType(GlassButton),
            matching: find.byType(Semantics),
          )
          .evaluate()
          .map((e) => e.widget.runtimeType)
          .toList();
      final element = tester.element(find.byType(AppGlass));
      await tester.pumpWidget(app(enabled: false));
      expect(tester.element(find.byType(AppGlass)), same(element));
      expect(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(Semantics),
            )
            .evaluate()
            .map((e) => e.widget.runtimeType)
            .toList(),
        before,
      );
    });

    testWidgets('inside a GlassScope the glass dims too', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          const GlassScope(
            kind: GlassLayerKind.chrome,
            child: GlassButton(onPressed: null, label: 'یک'),
          ),
        ),
      );
      expect(GlassVisibility.of(tester.element(find.byType(AppGlass))), 0.4);
      expect(bareFadesAboveGlass(tester, find.byType(GlassScope)), isEmpty);
    });
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

  testWidgets('reduce transparency: chrome stays real glass, no errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        GlassButton(onPressed: () {}, label: 'یک'),
        reduceTransparency: true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(glassLayerFakeFlags(tester), [false]);
  });
}
