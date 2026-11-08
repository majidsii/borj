import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _bar({
  int selected = 0,
  ValueChanged<int>? onSelected,
  VoidCallback? onSearch,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
}) => glassTestApp(
  brightness: brightness,
  textScale: textScale,
  reduceMotion: reduceMotion,
  SizedBox(
    width: 390,
    child: GlassScope(
      kind: GlassLayerKind.chrome,
      child: GlassTabBar(
        destinations: shellDestinations,
        selectedIndex: selected,
        onSelected: onSelected ?? (_) {},
        onSearch: onSearch ?? () {},
      ),
    ),
  ),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders without overflow (${v.name})', (tester) async {
      await tester.pumpWidget(
        _bar(brightness: v.brightness, textScale: v.textScale),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('امروز'), findsOneWidget);
      expect(find.text('کارها'), findsOneWidget);
      expect(find.text('مالی'), findsOneWidget);
    });
  }

  testWidgets('board geometry: capsule 62 tall, search circle 62', (
    tester,
  ) async {
    await tester.pumpWidget(_bar());
    expect(tester.getSize(find.byKey(const ValueKey('tab-bar'))).height, 62);
    expect(
      tester.getSize(find.byKey(const ValueKey('tab-search'))),
      const Size(62, 62),
    );
  });

  testWidgets('RTL: امروز is right-most, search circle on the left', (
    tester,
  ) async {
    await tester.pumpWidget(_bar());
    final today = tester.getCenter(find.byKey(const ValueKey('tab-today')));
    final finance = tester.getCenter(find.byKey(const ValueKey('tab-finance')));
    final search = tester.getCenter(find.byKey(const ValueKey('tab-search')));
    expect(today.dx, greaterThan(finance.dx));
    expect(search.dx, lessThan(finance.dx));
  });

  testWidgets('tapping a tab reports its index; search reports', (
    tester,
  ) async {
    int? picked;
    var searched = false;
    await tester.pumpWidget(
      _bar(onSelected: (i) => picked = i, onSearch: () => searched = true),
    );
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    expect(picked, 2);
    await tester.tap(find.byKey(const ValueKey('tab-search')));
    expect(searched, isTrue);
  });

  testWidgets('selected tab semantics and 44 pt targets', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_bar(selected: 1));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('tab-tasks'))),
      matchesSemantics(
        label: 'کارها',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    for (final s in ShellSection.values) {
      final size = tester.getSize(find.byKey(ValueKey('tab-${s.name}')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    handle.dispose();
  });

  testWidgets('the lens is flat GlassInner, never glass on glass', (
    tester,
  ) async {
    await tester.pumpWidget(_bar());
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tab-lens')),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tab-lens')),
        matching: find.byType(AppGlass),
      ),
      findsNothing,
    );
  });

  testWidgets('reduce motion: switching tabs moves nothing', (tester) async {
    await tester.pumpWidget(_bar(reduceMotion: true));
    await expectNoMovement(
      tester,
      within: find.byKey(const ValueKey('tab-bar')),
      trigger: () async =>
          tester.pumpWidget(_bar(selected: 2, reduceMotion: true)),
    );
  });
}
