// test/app/design/glass_chip_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          GlassChip(
            label: 'امروز',
            selected: true,
            onPressed: () {},
            icon: Icons.today,
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('off glass is a row glass capsule; on glass is flat', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(GlassChip(label: 'a', onPressed: () {})),
    );
    expect(tester.widget<AppGlass>(find.byType(AppGlass)).role, GlassRole.row);
    await tester.pumpWidget(
      glassTestApp(
        AppGlass(
          role: GlassRole.panel,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GlassChip(label: 'a', onPressed: () {}),
          ),
        ),
      ),
    );
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget);
  });

  testWidgets('hit target is at least 44 tall; tap works', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      glassTestApp(GlassChip(label: 'a', onPressed: () => taps++)),
    );
    expect(
      tester.getSize(find.byType(GlassChip)).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.text('a'));
    expect(taps, 1);
  });

  testWidgets('hover overlay follows the 32 tall chip, not the 44 hit box', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(GlassChip(label: 'a', onPressed: () {})),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(GlassChip)));
    await tester.pump();
    final hover = find.byKey(const ValueKey('pressable-hover'));
    expect(hover, findsOneWidget);
    expect(tester.getSize(hover).height, 32);
  });
}
