import 'dart:io';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_calendar/task_calendar_board.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_desktop.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_list_view.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/borj_test_app.dart';

final DateTime _now = DateTime.utc(2026, 11, 11, 10);
final FixedAppClock _clock = FixedAppClock(utcValue: _now, localValue: _now);

Future<void> _seed(ProviderContainer c) async {
  final created = DateTime.utc(2026, 11, 1);
  final repository = c.read(taskRepositoryProvider);
  await repository.create(
    TaskItem(
      id: 'deep1',
      displayNumber: 1,
      title: 'کار اعلان',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 0,
      createdAtUtc: created,
      updatedAtUtc: created,
    ),
  );
}

Future<ProviderContainer> _pump(WidgetTester tester, Size size) {
  useWindowSize(tester, size);
  return pumpBorjTestApp(
    tester,
    overrides: [appClockProvider.overrideWithValue(_clock)],
    seed: _seed,
  );
}

Future<void> _io(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

String _location(ProviderContainer c) => c
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  testWidgets('compact /tasks defaults to the list', (tester) async {
    final c = await _pump(tester, const Size(390, 844));
    c.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(find.byType(TaskSectionList), findsOneWidget);
    expect(find.byType(TaskKanbanDesktop), findsNothing);
  });

  for (final size in [const Size(700, 900), const Size(1440, 900)]) {
    testWidgets('${size.width.toInt()} wide /tasks defaults to the board', (
      tester,
    ) async {
      final c = await _pump(tester, size);
      c.read(appRouterProvider).go('/tasks');
      await tester.pumpAndSettle();
      expect(find.byType(TaskKanbanDesktop), findsOneWidget);
      expect(find.byType(TaskSectionList), findsNothing);
    });
  }

  testWidgets('/tasks?view=list on expanded shows the list', (tester) async {
    final c = await _pump(tester, const Size(1440, 900));
    c.read(appRouterProvider).go('/tasks?view=list');
    await tester.pumpAndSettle();
    expect(find.byType(TaskSectionList), findsOneWidget);
  });

  testWidgets('sidebar تقویم shows the calendar, همهٔ کارها leaves it', (
    tester,
  ) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(
      find.byKey(const ValueKey('sidebar-item-/tasks?view=calendar')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskCalendarBoard), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sidebar-item-/tasks')));
    await tester.pumpAndSettle();
    expect(find.byType(TaskCalendarBoard), findsNothing);
    expect(find.byType(TaskKanbanDesktop), findsOneWidget);
  });

  testWidgets(
    'deep link /tasks/<id> opens the edit dialog; closing goes to /tasks',
    (tester) async {
      final c = await _pump(tester, const Size(390, 844));
      c.read(appRouterProvider).go('/tasks/deep1');
      await _io(tester);
      expect(find.text('ویرایش کار'), findsWidgets);
      expect(find.text('انصراف'), findsOneWidget);
      expect(find.text('کار اعلان'), findsWidgets);
      // Rebuilds (a resize) do not open a second dialog.
      useWindowSize(tester, const Size(500, 900));
      await tester.pumpAndSettle();
      expect(find.text('انصراف'), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(find.text('انصراف'), findsNothing);
      expect(_location(c), '/tasks');
      expect(find.byType(TasksScreen), findsOneWidget);
    },
  );

  testWidgets('deep link with a missing id toasts and returns to /tasks', (
    tester,
  ) async {
    final c = await _pump(tester, const Size(390, 844));
    c.read(appRouterProvider).go('/tasks/nope');
    await _io(tester);
    expect(find.text('این کار پیدا نشد'), findsOneWidget);
    expect(find.text('برگرداندن'), findsNothing);
    expect(_location(c), '/tasks');
    expect(find.text('انصراف'), findsNothing);
  });

  testWidgets('compact tasks toolbar: گزینه‌ها and کار جدید', (tester) async {
    final c = await _pump(tester, const Size(390, 844));
    c.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('toolbar-گزینه‌ها')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toolbar-گزینه‌ها')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('option-add-details')), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toolbar-کار جدید')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(GlassButton, 'ثبت'), findsOneWidget);
  });

  testWidgets('expanded tasks toolbar has only کار جدید', (tester) async {
    final c = await _pump(tester, const Size(1440, 900));
    c.read(appRouterProvider).go('/tasks');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('toolbar-گزینه‌ها')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toolbar-کار جدید')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(GlassButton, 'ثبت'), findsOneWidget);
  });

  for (final entry in {
    'compact ورود سریع': (const Size(390, 844), 'toolbar-ورود سریع'),
    'expanded افزودن': (const Size(1440, 900), 'toolbar-افزودن'),
  }.entries) {
    testWidgets('Today ${entry.key} creates a task shown on Today', (
      tester,
    ) async {
      await _pump(tester, entry.value.$1);
      await tester.tap(find.byKey(ValueKey(entry.value.$2)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'کار از ورود سریع');
      await tester.tap(find.text('امروز').last);
      await tester.pump();
      await tester.tap(find.widgetWithText(GlassButton, 'ثبت'));
      await _io(tester);
      expect(find.text('کار از ورود سریع'), findsWidgets);
    });
  }

  test('no reference to the legacy tasks panel remains', () {
    final offenders = <String>[];
    for (final root in ['lib', 'test']) {
      for (final f in Directory(root).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.path.endsWith('tasks_routes_test.dart')) continue;
        if (f.readAsStringSync().contains('TasksPanel')) offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
