import 'dart:ui' as ui;

import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../test/support/backdrop_capture_log.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LiquidGlass.precache);

  // The renderer prints a count only when it rises within the process. Phone
  // (budget 3) runs first; if desktop prints nothing, its count is at most the
  // phone's, so still within 4. The reverse order could hide a phone count of 4.
  for (final (name, scene, size, budget) in [
    ('phone', const GlassProbeScene.phone(), const Size(390, 844), 3),
    ('desktop', const GlassProbeScene.desktop(), const Size(1440, 900), 4),
  ]) {
    testWidgets('$name probe scrolls within budget on real glass', (
      tester,
    ) async {
      expect(
        ui.ImageFilter.isShaderFilterSupported,
        isTrue,
        reason:
            'shader filters unavailable: real glass is not active, the probe would measure FakeGlass',
      );
      await binding.setSurfaceSize(size);
      final captures = await BackdropCaptureLog.record(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [AppTheme.dark],
            ),
            home: scene,
          ),
        );
        await tester.pumpAndSettle();
      });
      // ignore: avoid_print
      print('LG_CAPTURES scene=$name path=real max=$captures');
      if (!kProfileMode) {
        // The counter only exists in debug builds.
        expect(captures, lessThanOrEqualTo(budget));
      }

      await binding.watchPerformance(() async {
        final watch = Stopwatch()..start();
        var up = true;
        while (watch.elapsed < const Duration(seconds: 3)) {
          await tester.fling(
            find.byKey(GlassProbeScene.scrollKey),
            Offset(0, up ? -600 : 600),
            2400,
          );
          await tester.pumpAndSettle();
          up = !up;
        }
      }, reportKey: 'glass_probe_$name');

      final summary =
          binding.reportData!['glass_probe_$name']! as Map<String, dynamic>;
      final p90 =
          (summary['90th_percentile_frame_rasterizer_time_millis'] as num)
              .toDouble();
      // ignore: avoid_print
      print(
        'LG_PERF scene=$name mode=${kProfileMode ? 'profile' : 'debug'} raster_p90_ms=$p90',
      );
      if (kProfileMode) {
        expect(p90, lessThanOrEqualTo(8.0));
      }
    });
  }
}
