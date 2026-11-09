import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/borj_test_app.dart';
import '../../support/glass_fade_expectations.dart';
import '../../support/reduced_motion_expectations.dart';

// 2026-11-04 14:30 in Tehran (UTC+3:30).
final _nowUtc = DateTime.utc(2026, 11, 4, 11);
final _clock = FixedAppClock(utcValue: _nowUtc, localValue: _nowUtc);
final _t0 = DateTime.utc(2026, 11, 1);

Future<void> _seedTask(ProviderContainer c) => c
    .read(taskRepositoryProvider)
    .create(
      TaskItem(
        id: 'a',
        displayNumber: 1,
        title: 'ورزش عصر',
        priority: 0,
        status: TaskStatus.planned,
        positionInStatus: 0,
        dueAtUtc: DateTime.utc(2026, 11, 4, 11, 30), // 15:00 Tehran
        createdAtUtc: _t0,
        updatedAtUtc: _t0,
      ),
    );

Future<void> _seedUntimed(ProviderContainer c) => c
    .read(taskRepositoryProvider)
    .create(
      TaskItem(
        id: 'u',
        displayNumber: 2,
        title: 'خرید نان',
        priority: 0,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: _t0,
        updatedAtUtc: _t0,
      ),
    );

Future<void> _seedPlan(ProviderContainer c) => c
    .read(financeRepositoryProvider)
    .addInstallmentPlan(
      InstallmentPlan(
        id: 'p',
        title: 'قسط وام',
        perInstallment: Money(
          minorUnits: 4200000,
          currencyCode: 'IRT',
          scale: 0,
        ),
        installmentCount: 12,
        paidCount: 3,
        createdAtUtc: _t0,
        updatedAtUtc: _t0,
      ),
    );

Future<void> _seedBoth(ProviderContainer c) async {
  await _seedTask(c);
  await _seedPlan(c);
}

List<Override> get _overrides => [appClockProvider.overrideWithValue(_clock)];

Finder get _grid => find.byKey(const ValueKey('today-grid'));

List<double> _enterValues(WidgetTester tester) => [
  for (final g in tester.widgetList<GlassVisibility>(
    find.descendant(of: _grid, matching: find.byType(GlassVisibility)),
  ))
    g.value,
];

void main() {
  setUp(TodayEntrance.reset);

  testWidgets('empty database: onboarding; its button opens Tasks', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    await pumpBorjTestApp(tester, overrides: _overrides);
    expect(find.byKey(const ValueKey('today-onboarding')), findsOneWidget);
    expect(_grid, findsNothing);
    await tester.tap(find.byKey(const ValueKey('onboarding-add-task')));
    await tester.pumpAndSettle();
    expect(find.byType(TasksPanel), findsOneWidget);
  });

  testWidgets('one task today: grid with timeline and tasks, no installment', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    await pumpBorjTestApp(tester, overrides: _overrides, seed: _seedTask);
    expect(_grid, findsOneWidget);
    expect(find.byKey(const ValueKey('today-slot-timeline')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-slot-tasks')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-slot-installment')), findsNothing);
    final timeline = find.byKey(const ValueKey('today-slot-timeline'));
    expect(
      find.descendant(of: timeline, matching: find.text('بعدی:')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: timeline, matching: find.text('ورزش عصر')),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('today-task-a@one-off')), findsOneWidget);
  });

  testWidgets('toggling the row completes the task, again plans it', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    final c = await pumpBorjTestApp(
      tester,
      overrides: _overrides,
      seed: _seedTask,
    );
    final check = find.descendant(
      of: find.byKey(const ValueKey('today-task-a@one-off')),
      matching: find.byType(RoundCheck),
    );
    await tester.tap(check);
    await tester.pumpAndSettle();
    final repository = c.read(taskRepositoryProvider);
    expect((await repository.getById('a'))!.status, TaskStatus.completed);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect((await repository.getById('a'))!.status, TaskStatus.planned);
  });

  testWidgets(
    'an untimed task stays when ticked (struck through) and reopens',
    (tester) async {
      useWindowSize(tester, const Size(390, 844));
      final c = await pumpBorjTestApp(
        tester,
        overrides: _overrides,
        seed: _seedUntimed,
      );
      final row = find.byKey(const ValueKey('today-task-u@one-off'));
      final check = find.descendant(of: row, matching: find.byType(RoundCheck));
      TextDecoration? decoration() => tester
          .widget<Text>(
            find.descendant(of: row, matching: find.text('خرید نان')),
          )
          .style
          ?.decoration;
      expect(row, findsOneWidget);
      await tester.tap(check);
      await tester.pumpAndSettle();
      final repository = c.read(taskRepositoryProvider);
      expect((await repository.getById('u'))!.status, TaskStatus.completed);
      expect(row, findsOneWidget);
      expect(find.text('امروز کاری نداری'), findsNothing);
      expect(tester.widget<RoundCheck>(check).checked, isTrue);
      expect(decoration(), TextDecoration.lineThrough);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect((await repository.getById('u'))!.status, TaskStatus.planned);
      expect(row, findsOneWidget);
      expect(tester.widget<RoundCheck>(check).checked, isFalse);
      expect(decoration(), isNot(TextDecoration.lineThrough));
    },
  );

  testWidgets('an active plan shows the installment card; tap opens Finance', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    await pumpBorjTestApp(tester, overrides: _overrides, seed: _seedBoth);
    expect(
      find.byKey(const ValueKey('today-slot-installment')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('today-page')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('قسط وام'));
    await tester.pumpAndSettle();
    expect(find.byType(FinancePanel), findsOneWidget);
  });

  testWidgets('compact header: weekday and Jalali day', (tester) async {
    useWindowSize(tester, const Size(390, 844));
    await pumpBorjTestApp(tester, overrides: _overrides);
    expect(find.text('چهارشنبه ۱۳ آبان'), findsOneWidget);
  });

  testWidgets('expanded header: the date chip', (tester) async {
    useWindowSize(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester, overrides: _overrides);
    expect(find.text('۱۳ آبان ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('debug long-press on the title pushes the glass review', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    await pumpBorjTestApp(tester, overrides: _overrides);
    await tester.longPress(
      find.descendant(
        of: find.byKey(const ValueKey('today-title')),
        matching: find.text('امروز'),
      ),
    );
    await pumpPage(tester);
    expect(find.text('Liquid Glass review'), findsWidgets);
    expect(find.byKey(const ValueKey('today-page')), findsNothing);
  });

  Future<StreamController<DateTime>> pumpToGrid(
    WidgetTester tester, {
    Future<void> Function(ProviderContainer)? seed = _seedBoth,
  }) async {
    final ticks = StreamController<DateTime>();
    addTearDown(ticks.close);
    await pumpBorjTestApp(
      tester,
      overrides: _overrides,
      minuteTicks: ticks.stream,
      seed: seed,
    );
    ticks.add(_nowUtc);
    for (var i = 0; i < 5 && _grid.evaluate().isEmpty; i++) {
      await tester.pump();
    }
    expect(_grid, findsOneWidget);
    return ticks;
  }

  group('entrance', () {
    testWidgets('cold start: ordered stagger, done within the bound, no bare '
        'fades', (tester) async {
      useWindowSize(tester, const Size(390, 844));
      await pumpToGrid(tester);
      final first = _enterValues(tester);
      expect(first.length, 3);
      expect(first.every((v) => v == 0), isTrue);
      expect(
        bareFadesAboveGlass(tester, find.byKey(const ValueKey('today-page'))),
        isEmpty,
      );
      await tester.pump(const Duration(milliseconds: 60));
      final early = _enterValues(tester);
      expect(early[0], greaterThan(0));
      expect(early[2], 0, reason: 'item 2 waits for its stagger');
      await tester.pump(
        AppMotion.staggerAt(2) +
            AppMotion.quick.duration -
            const Duration(milliseconds: 60),
      );
      expect(_enterValues(tester).every((v) => v == 1), isTrue);
      expect(TodayEntrance.played, isTrue);
    });

    testWidgets('a later build has no entrance (value 1 on the first frame)', (
      tester,
    ) async {
      TodayEntrance.markPlayed();
      useWindowSize(tester, const Size(390, 844));
      await pumpToGrid(tester);
      expect(_enterValues(tester).every((v) => v == 1), isTrue);
    });

    testWidgets('onboarding plays; the grid after the first task does not', (
      tester,
    ) async {
      useWindowSize(tester, const Size(390, 844));
      final ticks = StreamController<DateTime>();
      addTearDown(ticks.close);
      final c = await pumpBorjTestApp(
        tester,
        overrides: _overrides,
        minuteTicks: ticks.stream,
      );
      ticks.add(_nowUtc);
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      final onboarding = find.byKey(const ValueKey('today-onboarding'));
      expect(onboarding, findsOneWidget);
      final enter = find.descendant(
        of: onboarding,
        matching: find.byType(GlassVisibility),
      );
      expect(tester.widget<GlassVisibility>(enter.first).value, 0);
      await tester.pump(const Duration(milliseconds: 400));
      await _seedTask(c);
      for (var i = 0; i < 5 && _grid.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(_grid, findsOneWidget);
      expect(_enterValues(tester).every((v) => v == 1), isTrue);
    });

    testWidgets('reduce motion: nothing moves, the fade still runs', (
      tester,
    ) async {
      useWindowSize(tester, const Size(390, 844));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpToGrid(tester);
      expect(_enterValues(tester).every((v) => v < 1), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_enterValues(tester).any((v) => v > 0 && v < 1), isTrue);
      await expectNoMovement(
        tester,
        within: _grid,
        trigger: () async {},
        span: const Duration(milliseconds: 700),
      );
      expect(_enterValues(tester).every((v) => v == 1), isTrue);
    });
  });

  testWidgets('the agenda follows the clock: next day drops today\'s task', (
    tester,
  ) async {
    useWindowSize(tester, const Size(390, 844));
    final ticks = StreamController<DateTime>();
    addTearDown(ticks.close);
    ticks.add(_nowUtc);
    await pumpBorjTestApp(
      tester,
      overrides: _overrides,
      minuteTicks: ticks.stream,
      seed: _seedTask,
    );
    expect(find.byKey(const ValueKey('today-task-a@one-off')), findsOneWidget);
    ticks.add(DateTime.utc(2026, 11, 5, 11));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-task-a@one-off')), findsNothing);
    expect(_grid, findsOneWidget);
    expect(find.text('امروز کاری نداری'), findsOneWidget);
  });

  for (final size in const [Size(600, 844), Size(1024, 800)]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('populated at ${size.width.toInt()}x${size.height.toInt()} '
          'text ${scale}x: no exception', (tester) async {
        useWindowSize(tester, size);
        await pumpBorjTestApp(
          tester,
          overrides: _overrides,
          seed: _seedBoth,
          wrap: (app) => MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: app,
          ),
        );
        expect(_grid, findsOneWidget);
        // Decision 7: the 1024 px window's grid is under 720 px wide.
        const columns = 2;
        final timeline = tester.getRect(
          find.byKey(const ValueKey('today-slot-timeline')),
        );
        final tasks = tester.getRect(
          find.byKey(const ValueKey('today-slot-tasks')),
        );
        expect(
          timeline.top < tasks.top,
          columns == 2,
          reason: 'two columns stack timeline above tasks',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
