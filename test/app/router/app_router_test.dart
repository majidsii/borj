import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/today_interim_page.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/borj_test_app.dart';

Future<void> _size(WidgetTester tester, Size size) async =>
    useWindowSize(tester, size);

void main() {
  testWidgets('opens on the interim Today', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    expect(find.byType(TodayInterimPage), findsOneWidget);
    expect(find.text('صفحهٔ امروز در حال ساخت است'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-compact')), findsOneWidget);
  });

  testWidgets('tabs show the tasks and finance panels', (tester) async {
    await _size(tester, const Size(390, 844));
    await pumpBorjTestApp(tester);
    await tester.tap(find.byKey(const ValueKey('tab-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('کارهای من'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-finance')));
    await tester.pumpAndSettle();
    expect(find.text('مالی من'), findsOneWidget);
    expect(find.text('کارهای من'), findsNothing);
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
      expect(find.byType(TodayInterimPage), findsOneWidget);
    },
  );

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
    expect(find.byType(TodayInterimPage), findsOneWidget);
  });

  testWidgets('expanded: no 780 px cap on the panels', (tester) async {
    await _size(tester, const Size(1440, 900));
    final container = await pumpBorjTestApp(tester);
    container.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TasksPanel)).width, greaterThan(1000));
  });

  test('no GoRoute uses a builder (builder routes become MaterialPages)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final offenders = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute && r.builder != null) offenders.add(r.path);
        walk(r.routes);
      }
    }

    walk(router.configuration.routes);
    expect(offenders, isEmpty);
  });
}
