import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/router/app_router.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../test/support/backdrop_layer_count.dart';
import '../test/support/borj_test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LiquidGlass.precache);

  Future<({int worst, int passes})> sample(
    WidgetTester tester,
    int frames,
  ) async {
    var worst = 0;
    var passes = 0;
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final n = countCompositedBackdropsDetailed(tester);
      worst = math.max(worst, n.captures);
      passes = math.max(passes, n.activeSeededPasses);
    }
    return (worst: worst, passes: passes);
  }

  void reportPerf(String scene, String key) {
    final summary = binding.reportData![key]! as Map<String, dynamic>;
    final p90 = (summary['90th_percentile_frame_rasterizer_time_millis'] as num)
        .toDouble();
    // ignore: avoid_print
    print(
      'LG_PERF scene=$scene mode=${kProfileMode ? 'profile' : 'debug'} raster_p90_ms=$p90',
    );
    if (kProfileMode) expect(p90, lessThanOrEqualTo(8.0));
  }

  testWidgets('phoneShell within budget on real glass', (tester) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'real glass is not active',
    );
    // setSurfaceSize keeps the real view (real raster timings); the app is
    // shown a 390 x 844 logical window through a MediaQuery override.
    const phone = Size(390, 844);
    await binding.setSurfaceSize(phone);
    addTearDown(() => binding.setSurfaceSize(null));
    final container = await pumpBorjTestApp(
      tester,
      wrap: (app) => MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(size: phone),
        child: app,
      ),
    );
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
    final today = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    final tasks = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    final finance = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('tab-today')));
    await pumpPage(tester);
    final router = container.read(appRouterProvider);
    // Settings is a legacy screen (Decision 7): printed, not asserted.
    unawaited(router.push(AppRoutes.settings));
    final settingsPush = await sample(tester, 30);
    await pumpPage(tester);
    final settingsSettled = await sample(tester, 3);
    router.pop();
    await pumpPage(tester);
    // /search is a new page on GlassPushPage: the asserted push.
    unawaited(router.push(AppRoutes.search));
    final searchPush = await sample(tester, 30);
    await pumpPage(tester);
    final passes = math.max(today.passes, searchPush.passes);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phoneShell today=${today.worst} tasks=${tasks.worst} finance=${finance.worst} settingsPush=${settingsPush.worst} settingsSettled=${settingsSettled.worst} searchPush=${searchPush.worst} active_seeded_passes=$passes',
    );
    final worst = math.max(today.worst, searchPush.worst);
    // ignore: avoid_print
    print('LG_CAPTURES scene=phoneShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(3));
      expect(passes, greaterThan(0), reason: 'no active seeded pass seen');
      expect(searchPush.worst, greaterThanOrEqualTo(2));
    }
    router.pop();
    await pumpPage(tester);
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      while (watch.elapsed < const Duration(seconds: 3)) {
        unawaited(router.push(AppRoutes.search));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        router.pop();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'glass_shell_phone');
    reportPerf('phoneShell', 'glass_shell_phone');
  });

  testWidgets('desktopShell within budget on real glass', (tester) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'real glass is not active',
    );
    useWindowSize(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester);
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    final today = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('toolbar-search')));
    final overlay = await sample(tester, 30);
    rootNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    final worst = math.max(today.worst, overlay.worst);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=desktopShell today=${today.worst} search=${overlay.worst} active_seeded_passes=${math.max(today.passes, overlay.passes)}',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktopShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(4));
      expect(
        math.max(today.passes, overlay.passes),
        greaterThan(0),
        reason: 'no active seeded pass seen',
      );
      expect(
        overlay.worst,
        greaterThan(today.worst),
        reason: 'the overlay glass must be counted',
      );
    }
    // A physicalSize override makes the engine report ~0 ms raster times, so
    // the perf run uses the real OS window (1180 wide: still expanded).
    tester.view.reset();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    container.read(appRouterProvider).go(AppRoutes.tasks);
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(TasksPanel),
      matching: find.byType(Scrollable),
    );
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      var up = true;
      while (watch.elapsed < const Duration(seconds: 3)) {
        await tester.fling(scrollable.first, Offset(0, up ? -600 : 600), 2400);
        await tester.pumpAndSettle();
        up = !up;
      }
    }, reportKey: 'glass_shell_desktop');
    reportPerf('desktopShell', 'glass_shell_desktop');
  });
}
