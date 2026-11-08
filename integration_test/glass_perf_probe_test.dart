import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../test/support/backdrop_capture_log.dart';
import '../test/support/backdrop_layer_count.dart';

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
      final record = await BackdropCaptureLog.record(() async {
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
      print('LG_CAPTURES scene=$name path=real max=${record.maxCaptures}');
      if (!kProfileMode) {
        // The counter only exists in debug builds.
        expect(record.maxCaptures, lessThanOrEqualTo(budget));
        expect(
          record.shapeLimitExceeded,
          isFalse,
          reason: 'a GlassScope holds more than 16 shapes',
        );
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

  Widget overlayApp(Widget scene) => MaterialApp(
    theme: ThemeData(brightness: Brightness.dark, extensions: [AppTheme.dark]),
    builder: (context, child) => GlassOverlayBackdrop(child: child!),
    home: scene,
  );

  void expectRealGlass() => expect(
    ui.ImageFilter.isShaderFilterSupported,
    isTrue,
    reason:
        'shader filters unavailable: real glass is not active, the probe would measure FakeGlass',
  );

  void fireToast(WidgetTester tester) => tester
      .widget<GlassButton>(find.byKey(const ValueKey('probe-show-toast')))
      .onPressed!();

  Future<({int worst, int naive, int passes})> sampleFrames(
    WidgetTester tester,
    int frames,
  ) async {
    var worst = 0;
    var naive = 0;
    var passes = 0;
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final n = countCompositedBackdropsDetailed(tester);
      if (n.captures > worst) worst = n.captures;
      if (n.naive > naive) naive = n.naive;
      if (n.activeSeededPasses > passes) passes = n.activeSeededPasses;
    }
    return (worst: worst, naive: naive, passes: passes);
  }

  // Scrolls the content behind an overlay for 3 s. The overlay's barrier sits
  // over the content, so a pointer fling cannot reach it; drive the scroll
  // position directly instead.
  Future<void> scrollBehind(WidgetTester tester) async {
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(GlassProbeScene.scrollKey),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    final watch = Stopwatch()..start();
    var down = true;
    while (watch.elapsed < const Duration(seconds: 3)) {
      final target = down ? position.maxScrollExtent : 0.0;
      final future = position.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
      await tester.pumpAndSettle();
      await future;
      down = !down;
    }
  }

  void reportPerf(String scene, String key) {
    final summary = binding.reportData![key]! as Map<String, dynamic>;
    final p90 = (summary['90th_percentile_frame_rasterizer_time_millis'] as num)
        .toDouble();
    // ignore: avoid_print
    print(
      'LG_PERF scene=$scene mode=${kProfileMode ? 'profile' : 'debug'} raster_p90_ms=$p90',
    );
    if (kProfileMode) {
      expect(p90, lessThanOrEqualTo(8.0));
    }
  }

  testWidgets('phoneWithSheetTrigger sheet and toast within budget', (
    tester,
  ) async {
    expectRealGlass();
    await binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      overlayApp(const GlassProbeScene.phoneWithSheetTrigger()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('probe-open-sheet')));
    final sheet = await sampleFrames(tester, 30);
    await tester.pumpAndSettle();
    fireToast(tester);
    final toast = await sampleFrames(tester, 30);
    final worst = math.max(sheet.worst, toast.worst);
    final passes = math.max(sheet.passes, toast.passes);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phoneWithSheetTrigger '
      'sheet=${sheet.worst} sheet_naive=${sheet.naive} '
      'toast=${toast.worst} toast_naive=${toast.naive} '
      'active_seeded_passes=$passes',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=phoneWithSheetTrigger path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(3));
      // A counter that under-reads must not pass vacuously.
      expect(passes, greaterThan(0), reason: 'no active seeded pass seen');
      expect(worst, greaterThanOrEqualTo(2));
    }
    await tester.pump(const Duration(seconds: 5)); // let the toast hide

    await binding.watchPerformance(
      () => scrollBehind(tester),
      reportKey: 'glass_probe_phone_overlay',
    );
    reportPerf('phoneWithSheetTrigger', 'glass_probe_phone_overlay');
  });

  testWidgets('desktopWithToastTrigger toast within budget', (tester) async {
    expectRealGlass();
    await binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      overlayApp(const GlassProbeScene.desktopWithToastTrigger()),
    );
    await tester.pumpAndSettle();
    fireToast(tester);
    final toast = await sampleFrames(tester, 30);
    final worst = toast.worst;
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=desktopWithToastTrigger toast=$worst '
      'toast_naive=${toast.naive} active_seeded_passes=${toast.passes}',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktopWithToastTrigger path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(4));
      expect(
        toast.passes,
        greaterThan(0),
        reason: 'no active seeded pass seen',
      );
      expect(worst, greaterThanOrEqualTo(3));
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
    }, reportKey: 'glass_probe_desktop_overlay');
    reportPerf('desktopWithToastTrigger', 'glass_probe_desktop_overlay');
  });
}
