// test/app/design/glass_toggle_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_material_expectations.dart';
import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _toggle(bool value, ValueChanged<bool> onChanged) =>
    GlassToggle(value: value, onChanged: onChanged, semanticLabel: 'کاهش حرکت');

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _toggle(true, (_) {}),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap toggles; size 52×32; colours from tokens', (tester) async {
    var value = false;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _toggle(value, (v) => setState(() => value = v)),
        ),
      ),
    );
    final track = find.byKey(const ValueKey('glass-toggle-track'));
    expect(tester.getSize(track), const Size(52, 32));
    await tester.tap(find.byType(GlassToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    final box = tester.widget<AnimatedContainer>(track);
    expect(
      (box.decoration! as BoxDecoration).color,
      AppTheme.light.colors.switchOn,
    );
  });

  testWidgets('on puts the knob at the end (left in RTL)', (tester) async {
    await tester.pumpWidget(glassTestApp(_toggle(true, (_) {})));
    await tester.pumpAndSettle();
    final track = tester.getRect(
      find.byKey(const ValueKey('glass-toggle-track')),
    );
    final knob = tester.getRect(
      find.byKey(const ValueKey('glass-toggle-knob')),
    );
    expect(knob.left, closeTo(track.left + 3, 0.5));
  });

  testWidgets('reduced motion: knob reaches its end after one frame', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _toggle(value, (v) => setState(() => value = v)),
        ),
        reduceMotion: true,
      ),
    );
    await expectNoMovement(
      tester,
      within: find.byType(GlassToggle),
      trigger: () => tester.tap(find.byType(GlassToggle)),
    );
    final track = tester.getRect(
      find.byKey(const ValueKey('glass-toggle-track')),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester.getRect(find.byKey(const ValueKey('glass-toggle-knob'))).left,
      closeTo(track.left + 3, 0.5),
    );
  });

  testWidgets('semantics toggled state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_toggle(true, (_) {})));
    expect(
      tester.getSemantics(find.byType(GlassToggle)),
      matchesSemantics(
        label: 'کاهش حرکت',
        isToggled: true,
        hasToggledState: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('keyboard: Tab focuses, Space and Enter toggle', (tester) async {
    var value = false;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _toggle(value, (v) => setState(() => value = v)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('reduce transparency: the toggle has no glass to fake', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(_toggle(true, (_) {}), reduceTransparency: true),
    );
    expect(tester.takeException(), isNull);
    expect(glassLayerFakeFlags(tester), isEmpty);
    expect(find.byKey(const ValueKey('glass-toggle-track')), findsOneWidget);
  });
}
