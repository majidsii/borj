// test/app/design/glass_row_transitions_test.dart
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';
import '../../support/glass_fade_expectations.dart';
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

double _visibility(WidgetTester tester, String label) =>
    GlassVisibility.of(tester.element(find.text(label)));

void main() {
  for (final v in glassTestVariants) {
    testWidgets('insert and remove render without errors (${v.name})', (
      tester,
    ) async {
      final items = ['یک', 'دو', 'سه'];
      await tester.pumpWidget(
        glassTestApp(
          _list(items),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      items.insert(1, 'نو');
      _listKey.currentState!.insertItem(
        1,
        duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      final removed = items.removeAt(0);
      _listKey.currentState!.removeItem(
        0,
        (context, animation) =>
            glassRowRemove(context, animation, _row(removed)),
        duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('نو'), findsOneWidget);
      expect(find.text('یک'), findsNothing);
    });
  }

  // First on purpose: the renderer prints its bare-fade warning once per
  // isolate (and only for real glass, not the FakeGlass of `flutter test`), so
  // the structural check below is the one that holds everywhere.
  testWidgets('row glass fades through GlassVisibility, never a bare fade', (
    tester,
  ) async {
    final items = ['یک', 'دو', 'سه'];
    for (final reduced in [false, true]) {
      final record = await BackdropCaptureLog.record(() async {
        await tester.pumpWidget(
          glassTestApp(_list(items), reduceMotion: reduced),
        );
        items.insert(1, 'نو');
        _listKey.currentState!.insertItem(
          1,
          duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(bareFadesAboveGlass(tester, find.byType(GlassScope)), isEmpty);
        expect(_visibility(tester, 'نو'), inExclusiveRange(0, 1));
        await tester.pumpAndSettle();
        final removed = items.removeAt(1);
        _listKey.currentState!.removeItem(
          1,
          (context, animation) =>
              glassRowRemove(context, animation, _row(removed)),
          duration: glassRowDuration(tester.element(find.byType(AnimatedList))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(bareFadesAboveGlass(tester, find.byType(GlassScope)), isEmpty);
        expect(_visibility(tester, 'نو'), inExclusiveRange(0, 1));
        await tester.pumpAndSettle();
      });
      expect(record.bareFadeWarned, isFalse);
    }
  });

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

  testWidgets('reduced remove eases out (flipped on the 1 to 0 animation)', (
    tester,
  ) async {
    final items = ['یک', 'دو', 'سه'];
    await tester.pumpWidget(glassTestApp(_list(items), reduceMotion: true));
    final removed = items.removeAt(1);
    _listKey.currentState!.removeItem(
      1,
      (context, animation) => glassRowRemove(context, animation, _row(removed)),
      duration: AppMotion.reduced.duration,
    );
    await tester.pump();
    await tester.pump(AppMotion.reduced.duration * 0.25);
    // Elapsed fraction 0.25: the fade-out follows ease-out of the elapsed
    // time (fast first), not the reverse of an ease-out (an ease-in).
    expect(
      _visibility(tester, 'دو'),
      closeTo(1 - AppMotion.reduced.curve.transform(0.25), 0.03),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('reduced insert eases out', (tester) async {
    final items = ['یک', 'دو'];
    await tester.pumpWidget(glassTestApp(_list(items), reduceMotion: true));
    items.insert(1, 'نو');
    _listKey.currentState!.insertItem(1, duration: AppMotion.reduced.duration);
    await tester.pump();
    await tester.pump(AppMotion.reduced.duration * 0.25);
    expect(
      _visibility(tester, 'نو'),
      closeTo(AppMotion.reduced.curve.transform(0.25), 0.03),
    );
    await tester.pumpAndSettle();
  });
}
