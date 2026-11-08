import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Widget _sidebar({
  String selected = '/',
  bool rail = false,
  ValueChanged<SidebarItem>? onSelected,
  VoidCallback? onSettings,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) => glassTestApp(
  brightness: brightness,
  textScale: textScale,
  SizedBox(
    height: 800,
    child: GlassScope(
      kind: GlassLayerKind.chrome,
      child: GlassSidebar(
        groups: sidebarGroups(),
        selectedLocation: selected,
        rail: rail,
        onSelected: onSelected ?? (_) {},
        onSettings: onSettings ?? () {},
      ),
    ),
  ),
);

Finder _innerOf(String location) => find.descendant(
  of: find.byKey(ValueKey('sidebar-item-$location')),
  matching: find.byType(GlassInner),
);

void main() {
  for (final v in glassTestVariants) {
    for (final rail in [false, true]) {
      testWidgets('renders (${v.name}, rail=$rail)', (tester) async {
        await tester.pumpWidget(
          _sidebar(
            rail: rail,
            brightness: v.brightness,
            textScale: v.textScale,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('board geometry: width 236, items 36 tall', (tester) async {
    await tester.pumpWidget(_sidebar());
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 236);
    expect(
      tester.getSize(find.byKey(const ValueKey('sidebar-item-/'))).height,
      36,
    );
    expect(find.text('برنامه'), findsOneWidget);
    expect(find.text('پول'), findsOneWidget);
    expect(find.text('زندگی'), findsNothing);
    expect(find.text('بودجه'), findsNothing);
  });

  testWidgets('selection by location, prefix and query', (tester) async {
    await tester.pumpWidget(_sidebar(selected: '/finance/debts/42'));
    expect(_innerOf('/finance/debts'), findsOneWidget);
    expect(_innerOf('/'), findsNothing);
    await tester.pumpWidget(_sidebar(selected: '/tasks?view=board'));
    expect(_innerOf('/tasks'), findsOneWidget);
    await tester.pumpWidget(_sidebar(selected: '/tasks?view=calendar'));
    expect(_innerOf('/tasks?view=calendar'), findsOneWidget);
    expect(_innerOf('/tasks'), findsNothing);
  });

  testWidgets('tap reports the item; settings row at the bottom', (
    tester,
  ) async {
    // The default 800x600 test surface clamps the 800 pt host; make it taller.
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SidebarItem? picked;
    var settings = false;
    await tester.pumpWidget(
      _sidebar(
        onSelected: (i) => picked = i,
        onSettings: () => settings = true,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('sidebar-item-/finance/transactions')),
    );
    expect(picked?.label, 'تراکنش‌ها');
    final settingsRow = find.byKey(const ValueKey('sidebar-settings'));
    expect(tester.getBottomLeft(settingsRow).dy, greaterThan(700));
    await tester.tap(settingsRow);
    expect(settings, isTrue);
    expect(find.text('تنظیمات'), findsOneWidget);
  });

  testWidgets('rail: 72 wide, icons only with tooltips', (tester) async {
    await tester.pumpWidget(_sidebar(rail: true));
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 72);
    expect(find.text('تراکنش‌ها'), findsNothing);
    expect(find.byTooltip('تراکنش‌ها'), findsOneWidget);
    expect(find.byTooltip('تنظیمات'), findsOneWidget);
  });

  testWidgets('RTL: labels right-aligned in the panel', (tester) async {
    await tester.pumpWidget(_sidebar());
    final item = tester.getRect(find.byKey(const ValueKey('sidebar-item-/')));
    final label = tester.getRect(find.text('امروز'));
    expect(label.right, greaterThan(item.center.dx));
  });

  testWidgets('hit box is the 36 pt row; the 2 pt gap is not a hit', (
    tester,
  ) async {
    final picked = <String>[];
    await tester.pumpWidget(_sidebar(onSelected: (i) => picked.add(i.label)));
    final rect = tester.getRect(find.byKey(const ValueKey('sidebar-item-/')));
    await tester.tapAt(rect.bottomCenter - const Offset(0, 1));
    expect(picked, ['امروز']);
    await tester.tapAt(rect.bottomCenter + const Offset(0, 1));
    expect(picked, ['امروز']);
  });

  testWidgets('rail rows are at least 44 x 44 for touch', (tester) async {
    await tester.pumpWidget(_sidebar(rail: true));
    final rows = find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          (k.value.startsWith('sidebar-item-') ||
              k.value == 'sidebar-settings');
    });
    expect(rows, findsNWidgets(6));
    for (final e in rows.evaluate()) {
      final size = tester.getSize(find.byElementPredicate((x) => x == e));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    }
  });
}
