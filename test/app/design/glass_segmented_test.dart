// test/app/design/glass_segmented_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_material_expectations.dart';
import '../../support/glass_test_app.dart';

enum _Mode { light, dark, auto }

Widget _segmented(_Mode selected, ValueChanged<_Mode> onChanged) => SizedBox(
  width: 300,
  child: GlassSegmented<_Mode>(
    semanticLabel: 'حالت ظاهری',
    selected: selected,
    onChanged: onChanged,
    segments: const [
      GlassSegment(value: _Mode.light, label: 'روشن'),
      GlassSegment(value: _Mode.dark, label: 'تیره'),
      GlassSegment(value: _Mode.auto, label: 'خودکار'),
    ],
  ),
);

Rect _thumb(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('glass-segmented-thumb')));

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _segmented(_Mode.auto, (_) {}),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap selects; thumb springs under the selected label', (
    tester,
  ) async {
    var selected = _Mode.light;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _segmented(selected, (m) => setState(() => selected = m)),
        ),
      ),
    );
    await tester.tap(find.text('خودکار'));
    await tester.pump(const Duration(milliseconds: 50));
    final mid = _thumb(tester).center.dx;
    await tester.pumpAndSettle();
    final end = _thumb(tester).center.dx;
    expect(selected, _Mode.auto);
    expect(end, closeTo(tester.getCenter(find.text('خودکار')).dx, 2));
    expect(
      mid,
      isNot(closeTo(end, 2)),
      reason: 'thumb should be travelling, not jumping',
    );
  });

  testWidgets('reduced motion: thumb jumps', (tester) async {
    var selected = _Mode.light;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _segmented(selected, (m) => setState(() => selected = m)),
        ),
        reduceMotion: true,
      ),
    );
    await tester.tap(find.text('خودکار'));
    await tester.pump();
    expect(
      _thumb(tester).center.dx,
      closeTo(tester.getCenter(find.text('خودکار')).dx, 2),
    );
  });

  testWidgets('on glass the track is flat and the thumb is a solid surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        AppGlass(
          role: GlassRole.panel,
          shape: const AppleGlassShape.rounded(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _segmented(_Mode.auto, (_) {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsOneWidget);
    expect(find.byType(GlassInner), findsOneWidget); // the track
  });

  testWidgets('arrow keys move the selection (RTL: left = next)', (
    tester,
  ) async {
    var selected = _Mode.light;
    await tester.pumpWidget(
      glassTestApp(
        StatefulBuilder(
          builder: (context, setState) =>
              _segmented(selected, (m) => setState(() => selected = m)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, _Mode.dark);
  });

  testWidgets('selected semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(glassTestApp(_segmented(_Mode.dark, (_) {})));
    expect(
      tester.getSemantics(find.text('تیره')),
      matchesSemantics(
        label: 'تیره',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('reduce transparency: the row control uses the flat material', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(_segmented(_Mode.dark, (_) {}), reduceTransparency: true),
    );
    expect(tester.takeException(), isNull);
    expect(glassLayerFakeFlags(tester), [true]);
  });
}
