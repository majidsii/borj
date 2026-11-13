import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/router/app_router.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_screen.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // One task due now (today) and one active installment plan, through the
  // real repositories, before Today first builds.
  Future<void> seedToday(ProviderContainer c) async {
    final now = c.read(appClockProvider).nowUtc();
    await c
        .read(taskRepositoryProvider)
        .create(
          TaskItem(
            id: 'probe-task',
            displayNumber: 1,
            title: 'ورزش عصر',
            priority: 0,
            status: TaskStatus.planned,
            positionInStatus: 0,
            dueAtUtc: now,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    await c
        .read(financeRepositoryProvider)
        .addInstallmentPlan(
          InstallmentPlan(
            id: 'probe-plan',
            title: 'قسط وام',
            perInstallment: Money(
              minorUnits: 4200000,
              currencyCode: 'IRT',
              scale: 0,
            ),
            installmentCount: 12,
            paidCount: 3,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
  }

  // Samples from the first frame the Today grid exists until the cold-start
  // entrance has settled (at least [frames] frames).
  Future<({int worst, int passes})> sampleEntrance(
    WidgetTester tester, {
    int frames = 30,
  }) async {
    final grid = find.byKey(const ValueKey('today-grid'));
    var worst = 0;
    var passes = 0;
    var seen = 0;
    for (var i = 0; i < 400 && seen < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (grid.evaluate().isEmpty) continue;
      seen++;
      final n = countCompositedBackdropsDetailed(tester);
      worst = math.max(worst, n.captures);
      passes = math.max(passes, n.activeSeededPasses);
    }
    expect(seen, frames, reason: 'the Today grid never appeared');
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
    if (kProfileMode) {
      // Guard against a vacuous run: real frames, real raster times.
      final frames = (summary['frame_count'] as num).toInt();
      expect(frames, greaterThanOrEqualTo(60), reason: 'too few frames');
      expect(p90, greaterThan(0), reason: 'no raster time recorded');
      expect(p90, lessThanOrEqualTo(8.0));
    }
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
    TodayEntrance.reset();
    final container = await pumpBorjTestApp(
      tester,
      seed: seedToday,
      settle: false,
      wrap: (app) => MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(size: phone),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 390, height: 844, child: app),
        ),
      ),
    );
    final entrance = await sampleEntrance(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-grid')), findsOneWidget);
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
    final passes = math.max(
      math.max(today.passes, entrance.passes),
      searchPush.passes,
    );
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phoneShell today=${today.worst} todayEntrance=${entrance.worst} tasks=${tasks.worst} finance=${finance.worst} settingsPush=${settingsPush.worst} settingsSettled=${settingsSettled.worst} searchPush=${searchPush.worst} active_seeded_passes=$passes',
    );
    final worst = math.max(
      math.max(today.worst, entrance.worst),
      searchPush.worst,
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=phoneShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(3));
      expect(today.worst, lessThanOrEqualTo(3));
      expect(today.worst, greaterThanOrEqualTo(2));
      expect(entrance.worst, lessThanOrEqualTo(3));
      expect(entrance.worst, greaterThanOrEqualTo(2));
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
    TodayEntrance.reset();
    final container = await pumpBorjTestApp(
      tester,
      seed: seedToday,
      settle: false,
    );
    final entrance = await sampleEntrance(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-grid')), findsOneWidget);
    final today = await sample(tester, 30);
    await tester.tap(find.byKey(const ValueKey('toolbar-search')));
    final overlay = await sample(tester, 30);
    rootNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    final worst = math.max(
      math.max(today.worst, entrance.worst),
      overlay.worst,
    );
    final passes = math.max(
      math.max(today.passes, entrance.passes),
      overlay.passes,
    );
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=desktopShell today=${today.worst} todayEntrance=${entrance.worst} search=${overlay.worst} active_seeded_passes=$passes',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktopShell path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(4));
      expect(today.worst, lessThanOrEqualTo(4));
      expect(today.worst, greaterThanOrEqualTo(2));
      expect(entrance.worst, lessThanOrEqualTo(4));
      expect(entrance.worst, greaterThanOrEqualTo(2));
      expect(passes, greaterThan(0), reason: 'no active seeded pass seen');
      expect(
        overlay.worst,
        greaterThan(today.worst),
        reason: 'the overlay glass must be counted',
      );
      expect(overlay.worst, greaterThanOrEqualTo(2));
    }
    // A physicalSize override makes the engine report ~0 ms raster times, so
    // the perf run uses the real OS window (1180 wide: still expanded).
    tester.view.reset();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    container.read(appRouterProvider).go('${AppRoutes.tasks}?view=list');
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(TasksScreen),
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
    reportPerf('desktopShellLegacyTasks', 'glass_shell_desktop');
  });
}
