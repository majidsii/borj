import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_capture_log.dart';

void main() {
  testWidgets('phone with a sheet opening stays within 3 captures', (
    tester,
  ) async {
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
          builder: (context, child) => GlassOverlayBackdrop(child: child!),
          home: const GlassProbeScene.phoneWithSheetTrigger(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('probe-open-sheet')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(
          const Duration(milliseconds: 16),
        ); // count during the open animation
      }
    });
    // ignore: avoid_print
    print('LG_CAPTURES scene=phone+sheet path=fake max=${record.maxCaptures}');
    expect(record.shapeLimitExceeded, isFalse);
    expect(record.maxCaptures, lessThanOrEqualTo(3));
  });
}
