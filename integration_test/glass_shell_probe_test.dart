import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/router/app_router.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_screen.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
    await pumpBorjTestApp(tester, seed: seedToday, settle: false);
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
  });

  // 30 tasks over every section and status, through the real repository,
  // before the app first builds. Offsets are whole hours/days from now.
  Future<void> seedTasks(ProviderContainer c) async {
    final now = c.read(appClockProvider).nowUtc();
    final repo = c.read(taskRepositoryProvider);
    final position = <TaskStatus, int>{};
    for (var i = 1; i <= 30; i++) {
      final status = switch (i % 10) {
        0 || 1 => TaskStatus.inProgress,
        2 || 3 => TaskStatus.completed,
        4 => TaskStatus.canceled,
        _ => TaskStatus.planned,
      };
      // Mixed sections: overdue, today, upcoming, untimed.
      final due = switch (i % 4) {
        0 => null,
        1 => now.subtract(Duration(days: 1 + i % 3)),
        2 => now.add(Duration(hours: i % 5)),
        _ => now.add(Duration(days: 1 + i % 6)),
      };
      final slot = position.update(status, (p) => p + 1, ifAbsent: () => 0);
      await repo.create(
        TaskItem(
          id: 'probe-t${i.toString().padLeft(2, '0')}',
          displayNumber: i,
          title: 'کار شمارهٔ $i',
          priority: i % 4,
          status: status,
          positionInStatus: slot,
          dueAtUtc: due,
          createdAtUtc: now,
          updatedAtUtc: now,
          completedAtUtc: status == TaskStatus.completed ? now : null,
          canceledAtUtc: status == TaskStatus.canceled ? now : null,
        ),
      );
    }
  }

  Finder tasksScrollable() => find
      .descendant(
        of: find.byType(TasksScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  // Presses [from], optionally waits [hold], moves in steps toward [to] and
  // samples every frame of the gesture, then releases.
  Future<({int worst, int passes})> sampleDrag(
    WidgetTester tester,
    Offset from,
    Offset to, {
    Duration hold = Duration.zero,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int steps = 20,
    VoidCallback? beforeRelease,
  }) async {
    var worst = 0;
    var passes = 0;
    void take() {
      final n = countCompositedBackdropsDetailed(tester);
      worst = math.max(worst, n.captures);
      passes = math.max(passes, n.activeSeededPasses);
    }

    final g = await tester.startGesture(from, kind: kind);
    if (hold > Duration.zero) {
      await tester.pump(hold);
      take();
    }
    await g.moveBy(const Offset(0, 8));
    await tester.pump(const Duration(milliseconds: 16));
    take();
    for (var i = 1; i <= steps; i++) {
      await g.moveTo(Offset.lerp(from, to, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
      take();
    }
    beforeRelease?.call();
    await g.up();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      take();
    }
    return (worst: worst, passes: passes);
  }

  testWidgets('phoneTasks within budget on real glass', (tester) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'real glass is not active',
    );
    const phone = Size(390, 844);
    await binding.setSurfaceSize(phone);
    addTearDown(() => binding.setSurfaceSize(null));
    final container = await pumpBorjTestApp(
      tester,
      seed: seedTasks,
      wrap: (app) => MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(size: phone),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 390, height: 844, child: app),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(find.byType(TaskGlassRow), findsWidgets);
    final list = await sample(tester, 30);

    // Scroll: a fling, sampled while it runs.
    var scrollWorst = 0;
    await tester.fling(tasksScrollable(), const Offset(0, -500), 1800);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      scrollWorst = math.max(
        scrollWorst,
        countCompositedBackdropsDetailed(tester).captures,
      );
    }
    await tester.fling(tasksScrollable(), const Offset(0, 900), 3000);
    await tester.pumpAndSettle();

    // Swipe the first row open (RTL: toward the start side is rightward).
    final row = find.byType(TaskGlassRow).first;
    final rowCentre = tester.getCenter(row);
    final swipe = await sampleDrag(
      tester,
      rowCentre,
      rowCentre + const Offset(130, 0),
      steps: 10,
    );
    expect(find.byKey(const ValueKey('swipe-delete')), findsWidgets);

    // Kanban: page through the columns, then drag a card onto a segment.
    container.read(appRouterProvider).go('${AppRoutes.tasks}?view=board');
    await tester.pumpAndSettle();
    final kanbanIdle = await sample(tester, 30);
    var pagingWorst = 0;
    for (final s in const ['inProgress', 'completed', 'planned']) {
      await tester.tap(find.byKey(ValueKey('kanban-status-$s')));
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        pagingWorst = math.max(
          pagingWorst,
          countCompositedBackdropsDetailed(tester).captures,
        );
      }
    }
    final card = find.byWidgetPredicate((w) => w is Draggable<TaskItem>).first;
    final target = tester.getCenter(
      find.byKey(const ValueKey('kanban-status-inProgress')),
    );
    final drag = await sampleDrag(
      tester,
      tester.getCenter(card),
      target,
      hold: const Duration(milliseconds: 600),
      beforeRelease: () => expect(
        find.byKey(const ValueKey('kanban-drop-hint')),
        findsOneWidget,
        reason: 'the drag never lifted the card',
      ),
    );
    await tester.pumpAndSettle();

    final kanban = math.max(kanbanIdle.worst, pagingWorst);
    final listWorst = math.max(list.worst, scrollWorst);
    final passes = [
      list.passes,
      swipe.passes,
      kanbanIdle.passes,
      drag.passes,
    ].reduce(math.max);
    final worst = [listWorst, swipe.worst, kanban, drag.worst].reduce(math.max);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phoneTasks tasksList=$listWorst tasksSwipe=${swipe.worst} tasksKanban=$kanban tasksDrag=${drag.worst} active_seeded_passes=$passes',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=phoneTasks path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(3));
      expect(listWorst, greaterThanOrEqualTo(2));
      expect(kanban, greaterThanOrEqualTo(2));
      expect(passes, greaterThan(0), reason: 'no active seeded pass seen');
    }

    container.read(appRouterProvider).go('${AppRoutes.tasks}?view=list');
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      var up = true;
      while (watch.elapsed < const Duration(milliseconds: 1500)) {
        await tester.fling(tasksScrollable(), Offset(0, up ? -600 : 600), 2400);
        await tester.pumpAndSettle();
        up = !up;
      }
      container.read(appRouterProvider).go('${AppRoutes.tasks}?view=board');
      await tester.pumpAndSettle();
      watch
        ..reset()
        ..start();
      var i = 0;
      const order = ['inProgress', 'completed', 'canceled', 'planned'];
      while (watch.elapsed < const Duration(milliseconds: 1500)) {
        await tester.tap(
          find.byKey(ValueKey('kanban-status-${order[i++ % 4]}')),
        );
        for (var f = 0; f < 25; f++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'glass_tasks_phone');
    reportPerf('phoneTasks', 'glass_tasks_phone');
  });

  testWidgets('desktopTasks within budget on real glass', (tester) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'real glass is not active',
    );
    useWindowSize(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester, seed: seedTasks);
    container.read(appRouterProvider).go('${AppRoutes.tasks}?view=board');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    expect(find.byType(TasksScreen), findsOneWidget);
    final kanban = await sample(tester, 30);
    final card = find.byType(Draggable<TaskItem>).first;
    final target = tester.getCenter(
      find.byKey(const ValueKey('kanban-column-inProgress')),
    );
    final drag = await sampleDrag(
      tester,
      tester.getCenter(card),
      target,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    final worst = math.max(kanban.worst, drag.worst);
    final passes = math.max(kanban.passes, drag.passes);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=desktopTasks tasksKanban=${kanban.worst} tasksDrag=${drag.worst} active_seeded_passes=$passes',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=desktopTasks path=real max=$worst');
    if (!kProfileMode) {
      expect(worst, lessThanOrEqualTo(4));
      expect(kanban.worst, greaterThanOrEqualTo(2));
      expect(passes, greaterThan(0), reason: 'no active seeded pass seen');
    }
    // A physicalSize override makes the engine report ~0 ms raster times, so
    // the perf run uses the real OS window (1180 wide: still expanded).
    tester.view.reset();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-expanded')), findsOneWidget);
    container.read(appRouterProvider).go('${AppRoutes.tasks}?view=list');
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      final watch = Stopwatch()..start();
      var up = true;
      while (watch.elapsed < const Duration(milliseconds: 1500)) {
        await tester.fling(tasksScrollable(), Offset(0, up ? -600 : 600), 2400);
        await tester.pumpAndSettle();
        up = !up;
      }
      container.read(appRouterProvider).go('${AppRoutes.tasks}?view=board');
      await tester.pumpAndSettle();
      final horizontal = find.byKey(const ValueKey('kanban-horizontal-scroll'));
      watch
        ..reset()
        ..start();
      var left = true;
      while (watch.elapsed < const Duration(milliseconds: 1500)) {
        if (horizontal.evaluate().isNotEmpty) {
          await tester.fling(horizontal, Offset(left ? -400 : 400, 0), 2000);
        }
        for (var f = 0; f < 25; f++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        left = !left;
      }
    }, reportKey: 'glass_tasks_desktop');
    reportPerf('desktopTasks', 'glass_tasks_desktop');
  });
}
