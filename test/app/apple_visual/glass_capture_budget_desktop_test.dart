import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  // One test per file: the renderer prints a count only when it rises within
  // the process, so a second test in this file could report a lower number.
  // The capture structure does not depend on brightness.
  testWidgets('desktop Today glass stays within 4 captures', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final count = await BackdropCaptureLog.record(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppTheme.dark],
          ),
          home: const GlassProbeScene.desktop(),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(GlassProbeScene.scrollKey),
        const Offset(0, -500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktop path=fake max=$count');
    expect(count, lessThanOrEqualTo(4));
  });
}
