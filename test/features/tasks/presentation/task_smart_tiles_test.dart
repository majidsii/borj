import 'package:borj/app/design/design.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_smart_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/backdrop_layer_count.dart';
import '../../../support/glass_shape_limit.dart';
import '../../../support/glass_test_app.dart';

const _counts = TaskSmartCounts(today: 3, timed: 12, overdue: 1, all: 27);

Widget _tiles({
  TaskSmartFilter selected = TaskSmartFilter.all,
  ValueChanged<TaskSmartFilter>? onSelected,
}) => SizedBox(
  width: 360,
  child: TaskSmartTiles(
    counts: _counts,
    selected: selected,
    onSelected: onSelected ?? (_) {},
  ),
);

Finder _tile(TaskSmartFilter f) => find.byKey(ValueKey('task-tile-${f.name}'));

void main() {
  testWidgets('counts are shown in Persian digits', (tester) async {
    await tester.pumpWidget(glassTestApp(_tiles()));
    expect(find.text('۳'), findsOneWidget);
    expect(find.text('۱۲'), findsOneWidget);
    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۲۷'), findsOneWidget);
    for (final label in ['امروز', 'زمان‌دار', 'عقب‌افتاده', 'همه']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping a tile reports its filter', (tester) async {
    final calls = <TaskSmartFilter>[];
    await tester.pumpWidget(glassTestApp(_tiles(onSelected: calls.add)));
    await tester.tap(_tile(TaskSmartFilter.overdue));
    await tester.pump();
    expect(calls, [TaskSmartFilter.overdue]);
  });

  testWidgets('RTL: امروز is top-right, 2 x 2', (tester) async {
    await tester.pumpWidget(glassTestApp(_tiles()));
    final today = tester.getCenter(_tile(TaskSmartFilter.today));
    final timed = tester.getCenter(_tile(TaskSmartFilter.timed));
    final overdue = tester.getCenter(_tile(TaskSmartFilter.overdue));
    final all = tester.getCenter(_tile(TaskSmartFilter.all));
    expect(today.dx, greaterThan(timed.dx));
    expect(today.dy, timed.dy);
    expect(overdue.dx, today.dx);
    expect(overdue.dy, greaterThan(today.dy));
    expect(all.dx, timed.dx);
    expect(all.dy, overdue.dy);
    expect(tester.getSize(_tile(TaskSmartFilter.today)).height, 56);
  });

  testWidgets('one scope holds the four tiles', (tester) async {
    await tester.pumpWidget(glassTestApp(_tiles()));
    expect(find.byType(GlassScope), findsOneWidget);
    expect(find.byType(AppGlass), findsNWidgets(4));
    expectScopesWithinShapeLimit(tester);
  });

  testWidgets('only the selected tile has a lens and selected semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      glassTestApp(_tiles(selected: TaskSmartFilter.overdue)),
    );
    expect(find.byType(GlassInner), findsOneWidget);
    expect(
      find.descendant(
        of: _tile(TaskSmartFilter.overdue),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(_tile(TaskSmartFilter.overdue)),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'عقب‌افتاده، ۱',
      ),
    );
    handle.dispose();
  });

  testWidgets('tiles add no backdrop group and one capture in a group', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(GlassBackdropGroup(child: _tiles()), overlayBackdrop: true),
    );
    expect(
      find.descendant(
        of: find.byType(TaskSmartTiles),
        matching: find.byType(GlassBackdropGroup),
      ),
      findsNothing,
    );
    expect(countCompositedBackdrops(tester), 1);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _tiles(selected: TaskSmartFilter.today),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
