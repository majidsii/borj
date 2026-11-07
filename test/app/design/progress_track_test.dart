// test/app/design/progress_track_test.dart
import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

double _fill(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('progress-fill'))).width;

Widget _track(double value, {bool animateIn = false}) => SizedBox(
  width: 200,
  child: ProgressTrack(value: value, animateIn: animateIn),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _track(0.7),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the value directly without animateIn', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.5)));
    expect(_fill(tester), closeTo(100, 0.5));
  });

  testWidgets('animates from the previous value over dataUpdate', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_track(0.2)));
    await tester.pumpWidget(glassTestApp(_track(0.8)));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _fill(tester);
    expect(mid, greaterThan(40));
    expect(mid, lessThan(160));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_fill(tester), closeTo(160, 0.5));
  });

  testWidgets('animateIn grows from 0 over dataEnter', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(1, animateIn: true)));
    expect(_fill(tester), lessThan(5));
    await tester.pump(const Duration(milliseconds: 460));
    expect(_fill(tester), closeTo(200, 0.5));
  });

  testWidgets('fill starts at the right edge in RTL', (tester) async {
    await tester.pumpWidget(glassTestApp(_track(0.5)));
    final track = tester.getRect(find.byType(ProgressTrack));
    expect(
      tester.getRect(find.byKey(const ValueKey('progress-fill'))).right,
      closeTo(track.right, 0.5),
    );
  });

  testWidgets('reduced motion: value change lands in one frame', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_track(0.2), reduceMotion: true));
    await tester.pumpWidget(glassTestApp(_track(0.8), reduceMotion: true));
    await tester.pump();
    expect(_fill(tester), closeTo(160, 0.5));
  });

  testWidgets('semantics expose the Persian percent value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 200,
          child: ProgressTrack(value: 0.7, semanticLabel: 'بودجه'),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(ProgressTrack))
        .getSemanticsData();
    expect(data.label, 'بودجه');
    expect(data.value, '۷۰٪');
    handle.dispose();
  });
}
