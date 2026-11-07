// test/app/design/round_check_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _check(bool value, ValueChanged<bool> onChanged) =>
    RoundCheck(checked: value, onChanged: onChanged, semanticLabel: 'خرید نان');

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders both states (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_check(false, (_) {}), _check(true, (_) {})],
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('checking grows the fill with a spring, then draws the mark', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _check(value, (v) => setState(() => value = v)),
        ),
      ),
    );
    await tester.tap(find.byType(RoundCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final scale = tester
        .widget<ScaleTransition>(find.byKey(const ValueKey('round-check-fill')))
        .scale
        .value;
    expect(scale, greaterThan(0));
    expect(scale, lessThan(1));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(
      tester
          .widget<ScaleTransition>(
            find.byKey(const ValueKey('round-check-fill')),
          )
          .scale
          .value,
      1,
    );
  });

  testWidgets('reduced motion: cross-fade only', (tester) async {
    var value = false;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _check(value, (v) => setState(() => value = v)),
        ),
        reduceMotion: true,
      ),
    );
    await expectNoMovement(
      tester,
      within: find.byType(RoundCheck),
      trigger: () => tester.tap(find.byType(RoundCheck)),
    );
    expect(value, isTrue);
  });

  testWidgets('44 px target and checked semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_check(true, (_) {})));
    expect(tester.getSize(find.byType(RoundCheck)), const Size(44, 44));
    expect(
      tester.getSemantics(find.byType(RoundCheck)),
      matchesSemantics(
        label: 'خرید نان',
        isChecked: true,
        hasCheckedState: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
