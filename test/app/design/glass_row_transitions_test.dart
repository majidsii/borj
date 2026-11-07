// test/app/design/glass_row_transitions_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

final _listKey = GlobalKey<AnimatedListState>();

Widget _row(String label) => SizedBox(
  height: 56,
  child: AppGlass(
    role: GlassRole.row,
    child: Center(child: AppText(label)),
  ),
);

Widget _list(List<String> items) => SizedBox(
  height: 400,
  width: 300,
  child: GlassScope(
    kind: GlassLayerKind.content,
    child: AnimatedList(
      key: _listKey,
      initialItemCount: items.length,
      itemBuilder: (context, i, animation) =>
          glassRowInsert(context, animation, _row(items[i])),
    ),
  ),
);

void main() {
  testWidgets('insert opens the slot while fading in', (tester) async {
    final items = ['یک', 'دو'];
    await tester.pumpWidget(glassTestApp(_list(items)));
    items.insert(1, 'نو');
    _listKey.currentState!.insertItem(
      1,
      duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester
        .widget<SizeTransition>(find.byType(SizeTransition).at(1))
        .sizeFactor
        .value;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('نو'), findsOneWidget);
  });

  testWidgets('remove: ghost fades and shrinks, slot collapses', (
    tester,
  ) async {
    final items = ['یک', 'دو', 'سه'];
    await tester.pumpWidget(glassTestApp(_list(items)));
    final removed = items.removeAt(1);
    _listKey.currentState!.removeItem(
      1,
      (context, animation) => glassRowRemove(context, animation, _row(removed)),
      duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final ghost = find.ancestor(
      of: find.text('دو'),
      matching: find.byType(ScaleTransition),
    );
    final scale = tester.widget<ScaleTransition>(ghost.first).scale.value;
    expect(scale, lessThan(1));
    expect(scale, greaterThanOrEqualTo(0.96));
    await tester.pumpAndSettle();
    expect(find.text('دو'), findsNothing);
    expect(
      tester.getTopLeft(find.text('سه')).dy -
          tester.getTopLeft(find.byType(AnimatedList)).dy,
      lessThan(120),
    );
  });

  testWidgets('reduced motion: fade only, no size or scale', (tester) async {
    final items = ['یک', 'دو'];
    await tester.pumpWidget(glassTestApp(_list(items), reduceMotion: true));
    await expectNoMovement(
      tester,
      within: find.byType(AnimatedList),
      trigger: () async {
        items.insert(1, 'نو');
        _listKey.currentState!.insertItem(
          1,
          duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
        );
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('نو'), findsOneWidget);
  });

  testWidgets('reduced motion remove: fade only, slot leaves at the end', (
    tester,
  ) async {
    final items = ['یک', 'دو', 'سه'];
    await tester.pumpWidget(glassTestApp(_list(items), reduceMotion: true));
    final removed = items.removeAt(1);
    await expectNoMovement(
      tester,
      within: find.byType(AnimatedList),
      trigger: () async {
        _listKey.currentState!.removeItem(
          1,
          (context, animation) =>
              glassRowRemove(context, animation, _row(removed)),
          duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
        );
      },
    );
    expect(
      find.ancestor(
        of: find.text('دو'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('دو'), findsNothing);
  });
}
