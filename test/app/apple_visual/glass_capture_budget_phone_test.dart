import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';
import '../../support/glass_shape_limit.dart';

void main() {
  // One test per file: the renderer prints a count only when it rises within
  // the process, so a second test in this file could report a lower number.
  // The capture structure does not depend on brightness.
  testWidgets('phone Today glass stays within 3 captures', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final record = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppTheme.dark],
          ),
          home: const GlassProbeScene.phone(),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(GlassProbeScene.scrollKey),
        const Offset(0, -500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expectScopesWithinShapeLimit(tester);
    });
    // ignore: avoid_print
    print('LG_CAPTURES scene=phone path=fake max=${record.maxCaptures}');
    expect(record.maxCaptures, lessThanOrEqualTo(3));
    expect(
      record.shapeLimitExceeded,
      isFalse,
      reason: 'a GlassScope holds more than 16 shapes',
    );
  });
}
