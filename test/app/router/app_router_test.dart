import 'dart:async';
import 'dart:math' as math;

import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/pending_screen.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_panel.dart';
import 'package:borj/features/settings/presentation/settings_screen.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_screen.dart';
import 'package:borj/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/borj_test_app.dart';

Future<void> _size(WidgetTester tester, Size size) async =>
    useWindowSize(tester, size);

void main() {
  testWidgets('opens on Today', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.byKey(const ValueKey('today-onboarding')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
  });

  testWidgets('tabs show the tasks screen and finance panel', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pumpAndSettle();
    expect(find.text('مالی من'), findsOneWidget);
    expect(find.byType(TasksScreen), findsNothing);
  });

  testWidgets(
    'compact: the Today settings circle pushes Settings; back returns',
    (tester) async {
      await _size(tester, const Size(390, 844));
      await pumpBorjTestApp(tester);
      await tester.tap(find.byKey(const ValueKey('toolbar-تنظیمات')));
      await pumpPage(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      GoRouter.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(TodayPage), findsOneWidget);
    },
  );

  testWidgets('compact: a focused Finance field stays above the keyboard', (
    tester,
  ) async {
    await _size(tester, const Size(390, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText).first;
    tester.state<EditableTextState>(field).requestKeyboard();
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(844 - 300));
  });

  testWidgets('compact: a focused field is revealed above the tab bar', (
    tester,
  ) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pumpAndSettle();
    final fields = find.byType(EditableText);
    var lowest = fields.first;
    for (var i = 0; i < fields.evaluate().length; i++) {
      final f = fields.at(i);
      if (tester.getBottomLeft(f).dy > tester.getBottomLeft(lowest).dy) {
        lowest = f;
      }
    }
    // Park the field at the very bottom of the viewport, behind the tab bar.
    final state = Scrollable.of(tester.element(lowest));
    state.position.jumpTo(
      (state.position.pixels + tester.getBottomLeft(lowest).dy - 830).clamp(
        0,
        state.position.maxScrollExtent,
      ),
    );
    await tester.pump();
    expect(tester.getBottomLeft(lowest).dy, greaterThan(758));
    tester.state<EditableTextState>(lowest).requestKeyboard();
    await tester.pumpAndSettle();
    final tabTop = tester.getTopLeft(find.byType(GlassTabBar)).dy;
    expect(tester.getBottomLeft(lowest).dy, lessThanOrEqualTo(tabTop));
  });

  group('page background', () {
    Finder backgroundsAbove() => find.ancestor(
      of: find.byType(PendingScreen),
      matching: find.byType(AppBackground),
    );
    Finder shellContent() => find.byKey(const ValueKey('shell-content'));

    testWidgets('expanded: a branch push adds no AppBackground', (
      tester,
    ) async {
      await _size(tester, const Size(1440, 900));
      final container = await pumpBorjTestApp(tester);
      container.read(appRouterProvider).go('/finance/debts/debt_1');
      await tester.pumpAndSettle();
      expect(find.byType(PendingScreen), findsOneWidget);
      // Only the shell's own background sits above the page.
      expect(backgroundsAbove(), findsOneWidget);
      expect(
        find.descendant(of: backgroundsAbove(), matching: shellContent()),
        findsOneWidget,
      );
    });

    testWidgets('compact: a branch push keeps its own AppBackground', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      final container = await pumpBorjTestApp(tester);
      container.read(appRouterProvider).go('/finance/debts/debt_1');
      await tester.pumpAndSettle();
      expect(backgroundsAbove(), findsNWidgets(2));
    });

    testWidgets('expanded: a root push paints one AppBackground', (
      tester,
    ) async {
      await _size(tester, const Size(1440, 900));
      final container = await pumpBorjTestApp(tester);
      unawaited(container.read(appRouterProvider).push('/backup'));
      await tester.pumpAndSettle();
      expect(backgroundsAbove(), findsOneWidget);
      expect(
        find.descendant(of: backgroundsAbove(), matching: shellContent()),
        findsNothing,
      );
    });
  });

  testWidgets('expanded: the پول rows both show FinancePanel and select', (
    tester,
  ) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    Finder selected(String location) => find.descendant(
      of: find.byKey(ValueKey('sidebar-item-$location')),
      matching: find.byType(GlassInner),
    );
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/finance')));
    await tester.pumpAndSettle();
    expect(find.byType(FinancePanel), findsOneWidget);
    expect(selected('/finance'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/tasks')));
    await tester.pumpAndSettle();
    expect(find.byType(FinancePanel), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('sidebar-item-/finance?section=debts')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FinancePanel), findsOneWidget);
    expect(selected('/finance?section=debts'), findsOneWidget);
    expect(selected('/finance'), findsNothing);
  });

  group('sidebar rows go to their exact location', () {
    Finder row(String l) => find.byKey(ValueKey('sidebar-item-$l'));
    Finder selected(String l) =>
        find.descendant(of: row(l), matching: find.byType(GlassInner));

    testWidgets('debts -> Tasks -> تراکنش‌ها shows FinancePanel, selected', (
      tester,
    ) async {
      await _size(tester, const Size(1440, 900));
      await pumpBorjTestApp(tester);
      for (final l in ['/finance?section=debts', '/tasks', '/finance']) {
        await tester.tap(row(l));
        await tester.pumpAndSettle();
      }
      expect(find.byType(FinancePanel), findsOneWidget);
      expect(selected('/finance'), findsOneWidget);
      expect(selected('/finance?section=debts'), findsNothing);
    });

    testWidgets('a pushed finance detail is not restored by the row', (
      tester,
    ) async {
      await _size(tester, const Size(1440, 900));
      final container = await pumpBorjTestApp(tester);
      container.read(appRouterProvider).go('/finance/debts/debt_1');
      await tester.pumpAndSettle();
      expect(find.byType(PendingScreen), findsOneWidget);
      await tester.tap(row('/'));
      await tester.pumpAndSettle();
      await tester.tap(row('/finance'));
      await tester.pumpAndSettle();
      expect(find.byType(FinancePanel), findsOneWidget);
      expect(find.byType(PendingScreen), findsNothing);
    });

    testWidgets('تقویم -> Today -> همهٔ کارها selects همهٔ کارها', (
      tester,
    ) async {
      await _size(tester, const Size(1440, 900));
      await pumpBorjTestApp(tester);
      for (final l in ['/tasks?view=calendar', '/', '/tasks']) {
        await tester.tap(row(l));
        await tester.pumpAndSettle();
      }
      expect(selected('/tasks'), findsOneWidget);
      expect(selected('/tasks?view=calendar'), findsNothing);
    });
  });

  testWidgets('a pushed page keeps its element across 390 <-> 1440', (
    tester,
  ) async {
    await _size(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/finance/debts/debt_1');
    await tester.pumpAndSettle();
    final before = tester.element(find.byType(PendingScreen));
    await _size(tester, const Size(390, 844));
    await tester.pumpAndSettle();
    expect(find.byType(PendingScreen), findsOneWidget);
    expect(tester.element(find.byType(PendingScreen)), same(before));
  });

  testWidgets('expanded: the sidebar settings row opens Settings', (
    tester,
  ) async {
    await _size(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    expect(find.byKey(const ValueKey('toolbar-تنظیمات')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sidebar-settings')));
    await pumpPage(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('debug: long-press the Today title opens the glass review', (
    tester,
  ) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.longPress(
      find.descendant(
        of: find.byKey(const ValueKey('today-title')),
        matching: find.text('امروز'),
      ),
    );
    await pumpPage(tester);
    expect(find.byType(GlassReviewScreen), findsOneWidget);
    // Pushed, not replaced: back returns to Today.
    GoRouter.of(tester.element(find.byType(GlassReviewScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TodayPage), findsOneWidget);
  });

  testWidgets('unknown location shows the error page; its action goes home', (
    tester,
  ) async {
    await _size(tester, const Size(390, 844));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/nope');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('route-error')), findsOneWidget);
    await tester.tap(find.text('رفتن به امروز'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayPage), findsOneWidget);
  });

  testWidgets('expanded: no 780 px cap on the tasks screen', (tester) async {
    await _size(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TasksScreen)).width, greaterThan(1000));
  });

  test('no GoRoute uses a builder (builder routes become MaterialPages)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final offenders = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute && r.builder != null) offenders.add(r.path);
        if (r is StatefulShellRoute && r.builder != null) {
          offenders.add('StatefulShellRoute');
        }
        walk(r.routes);
      }
    }

    walk(router.configuration.routes);
    expect(offenders, isEmpty);
  });

  testWidgets(
    'compact: a detail pushed in a branch joins only the shell group',
    (tester) async {
      await _size(tester, const Size(390, 844));
      final container = await pumpBorjTestApp(tester);
      unawaited(
        container.read(appRouterProvider).push('/finance/debts/debt_1'),
      );
      var worst = 0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        worst = math.max(worst, countCompositedBackdrops(tester));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PendingScreen), findsOneWidget);
      expect(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(PendingScreen),
                matching: find.byType(AppGlass),
              ),
              matching: find.byType(GlassBackdropGroup),
            )
            .evaluate()
            .toSet(),
        hasLength(1),
      );
      expect(worst, lessThanOrEqualTo(3));
    },
  );
}
