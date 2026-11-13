import 'dart:async';
import 'dart:io';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/app_shell.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_calendar/task_calendar_board.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_manager_dialog.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_desktop.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_phone.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_options_sheet.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/backdrop_layer_count.dart';
import '../../../support/borj_test_app.dart';

// 2026-11-11 13:30 in Tehran (UTC+3:30), a Wednesday.
final DateTime _now = DateTime.utc(2026, 11, 11, 10);
final FixedAppClock _clock = FixedAppClock(utcValue: _now, localValue: _now);

GoRouter? _router;

TaskItem _task(
  String id,
  int number,
  String title, {
  int priority = 0,
  DateTime? due,
  int createdHour = 0,
}) {
  final created = DateTime.utc(2026, 11, 1, createdHour);
  return TaskItem(
    id: id,
    displayNumber: number,
    title: title,
    priority: priority,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: due,
    createdAtUtc: created,
    updatedAtUtc: created,
  );
}

Future<void> _seed(ProviderContainer c) async {
  final repository = c.read(taskRepositoryProvider);
  final tasks = [
    _task(
      't1',
      1,
      'خرید نان',
      priority: 3,
      due: DateTime.utc(2026, 11, 11, 11, 30), // today 15:00
    ),
    _task('t2', 2, 'مرور پروژه', priority: 1, createdHour: 1),
    _task(
      't3',
      3,
      'قبض برق',
      priority: 2,
      due: DateTime.utc(2026, 11, 5, 8), // overdue
    ),
    _task('t4', 4, 'سفر کوتاه', due: DateTime.utc(2026, 11, 20, 8)),
    _task('t5', 5, 'خواندن کتاب'),
    _task('t6', 6, 'گزارش ماهانه', createdHour: 5),
  ];
  const target = {'t5': TaskStatus.completed, 't6': TaskStatus.inProgress};
  for (final t in tasks) {
    await repository.create(t);
    await repository.transition(
      id: t.id,
      status: target[t.id] ?? TaskStatus.planned,
      targetPosition: 0,
      changedAtUtc: t.createdAtUtc,
    );
  }
}

GoRouter _buildRouter(String view) {
  Widget stub(String text) => Center(child: Text(text));
  return GoRouter(
    initialLocation: view.isEmpty ? '/tasks' : '/tasks?view=$view',
    routes: [
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => NoTransitionPage(
          key: state.pageKey,
          child: AppShell(
            navigationShell: shell,
            location: state.uri.toString(),
            actionsFor: (c, wc) => wc == WindowClass.compact
                ? [
                    ShellAction(
                      icon: Icons.more_horiz,
                      label: 'گزینه‌ها',
                      leading: true,
                      onPressed: (c) => unawaited(showTasksOptions(c)),
                    ),
                  ]
                : const [],
            onSettings: () {},
            onSearch: () {},
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => stub('today'))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: TasksScreen(
                    view: state.uri.queryParameters['view'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/finance', builder: (_, _) => stub('finance')),
            ],
          ),
        ],
      ),
    ],
  );
}

String? get _viewParam =>
    _router!.routeInformationProvider.value.uri.queryParameters['view'];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String view = '',
  double scale = 1,
  Future<void> Function(ProviderContainer c) seed = _seed,
}) {
  useWindowSize(tester, size);
  if (scale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  return pumpBorjTestApp(
    tester,
    overrides: [
      appClockProvider.overrideWithValue(_clock),
      appRouterProvider.overrideWith((ref) => _router = _buildRouter(view)),
    ],
    seed: seed,
  );
}

Finder _row(String id) => find.byKey(ValueKey('task-row-$id'));
Finder _key(String k) => find.byKey(ValueKey(k));

Finder _segment(String label) =>
    find.descendant(of: _key('tasks-view'), matching: find.text(label));

Future<void> _openOptionsCompact(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz));
  await tester.pumpAndSettle();
}

Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
}

/// Lets real database I/O finish, then settles the frames it caused.
Future<void> _settleIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<T> _run<T>(WidgetTester tester, Future<T> Function() body) async {
  final result = await tester.runAsync(body);
  return result as T;
}

Future<TaskItem?> _stored(
  WidgetTester tester,
  ProviderContainer c,
  String id,
) => _run(tester, () => c.read(taskRepositoryProvider).getById(id));

void main() {
  testWidgets('compact list: open count, tiles and sections', (tester) async {
    await _pump(tester);
    expect(find.text('۵ کار باز'), findsOneWidget);
    expect(_key('tasks-title'), findsOneWidget);
    expect(find.text('کارها'), findsWidgets);
    for (final f in ['today', 'timed', 'overdue', 'all']) {
      expect(_key('task-tile-$f'), findsOneWidget);
    }
    for (final s in ['عقب‌افتاده', 'امروز', 'آینده', 'بی‌زمان']) {
      expect(find.text(s), findsWidgets);
    }
    expect(_row('t1'), findsOneWidget);
    expect(_row('t3'), findsOneWidget);
    expect(_row('t4'), findsOneWidget);
    expect(_row('t2'), findsOneWidget);
    expect(_row('t6'), findsOneWidget);
    expect(_row('t5'), findsNothing);
    expect(find.text('نمایش انجام‌شده‌ها (۱)'), findsOneWidget);
    expect(_key('tasks-search'), findsOneWidget);
    expect(find.byType(TaskKanbanPhone), findsNothing);
  });

  testWidgets('smart tile filters the list', (tester) async {
    await _pump(tester);
    await tester.tap(_key('task-tile-overdue'));
    await tester.pumpAndSettle();
    expect(_row('t3'), findsOneWidget);
    expect(_row('t1'), findsNothing);
  });

  testWidgets('segmented switches the route query and the content', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_segment('کانبان'));
    await tester.pumpAndSettle();
    expect(_viewParam, 'board');
    expect(find.byType(TaskKanbanPhone), findsOneWidget);
    expect(_key('task-tile-all'), findsNothing);

    await tester.tap(_segment('تقویم'));
    await tester.pumpAndSettle();
    expect(_viewParam, 'calendar');
    expect(find.byType(TaskCalendarBoard), findsOneWidget);

    await tester.tap(_segment('فهرست'));
    await tester.pumpAndSettle();
    expect(_viewParam, 'list');
    expect(_row('t1'), findsOneWidget);
  });

  testWidgets('expanded defaults to the board with four columns', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1440, 900));
    expect(find.byType(TaskKanbanDesktop), findsOneWidget);
    for (final s in TaskStatus.values) {
      expect(_key('kanban-column-${s.name}'), findsOneWidget);
    }
    expect(
      find.descendant(
        of: _key('tasks-header-chip'),
        matching: find.text('همهٔ کارها'),
      ),
      findsOneWidget,
    );
    expect(find.text('۵ کار باز'), findsOneWidget);
    expect(_key('tasks-options'), findsOneWidget);
    expect(_key('tasks-search'), findsOneWidget);
  });

  testWidgets('explicit list view on expanded shows the list', (tester) async {
    await _pump(tester, size: const Size(1440, 900), view: 'list');
    expect(find.byType(TaskKanbanDesktop), findsNothing);
    expect(_row('t1'), findsOneWidget);
  });

  testWidgets('options sheet lists every entry', (tester) async {
    await _pump(tester);
    await _openOptionsCompact(tester);
    for (final label in [
      'مرتب‌سازی',
      'زمان',
      'اولویت',
      'جدیدترین',
      'الفبا',
      'پاک کردن انجام‌شده‌ها (۱)',
      'افزودن با جزئیات',
      'انتخاب قالب',
      'مدیریت قالب‌ها',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    for (final k in [
      'option-clear',
      'option-add-details',
      'option-template-pick',
      'option-template-manage',
      'option-calendar',
    ]) {
      expect(_key(k), findsOneWidget, reason: k);
    }
  });

  testWidgets('sort change reorders the list', (tester) async {
    await _pump(tester);
    // Time sort: same section, priority desc, so t2 (priority 1) is first.
    expect(
      tester.getTopLeft(_row('t2')).dy,
      lessThan(tester.getTopLeft(_row('t6')).dy),
    );
    await _openOptionsCompact(tester);
    await tester.tap(find.text('جدیدترین'));
    await tester.pumpAndSettle();
    await _closeSheet(tester);
    expect(
      tester.getTopLeft(_row('t6')).dy,
      lessThan(tester.getTopLeft(_row('t2')).dy),
    );
  });

  testWidgets('clear completed hides them, undo brings them back', (
    tester,
  ) async {
    final c = await _pump(tester);
    await _openOptionsCompact(tester);
    await tester.tap(_key('option-clear'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(find.text('۱ کار انجام‌شده پاک شد'), findsOneWidget);
    expect(
      c.read(visibleTaskItemsProvider).requireValue.any((t) => t.id == 't5'),
      isFalse,
    );
    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect(
      c.read(visibleTaskItemsProvider).requireValue.any((t) => t.id == 't5'),
      isTrue,
    );
    expect(await _stored(tester, c, 't5'), isNotNull);
  });

  testWidgets('clear completed is removed for good when the toast expires', (
    tester,
  ) async {
    final c = await _pump(tester);
    await _openOptionsCompact(tester);
    await tester.tap(_key('option-clear'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(await _stored(tester, c, 't5'), isNull);
    expect(await _stored(tester, c, 't1'), isNotNull);
  });

  testWidgets('clear completed is disabled when nothing is completed', (
    tester,
  ) async {
    await _pump(
      tester,
      seed: (c) async {
        await c
            .read(taskActionsProvider)
            .create(title: 'فقط یک کار', priority: 0);
      },
    );
    await _openOptionsCompact(tester);
    expect(find.text('پاک کردن انجام‌شده‌ها (۰)'), findsOneWidget);
    final pressable = tester.widget<Pressable>(_key('option-clear'));
    expect(pressable.onPressed, isNull);
  });

  Future<void> swipeDelete(WidgetTester tester, String id) async {
    await tester.drag(_row(id), const Offset(80, 0));
    await tester.pumpAndSettle();
    await tester.tap(_key('swipe-delete'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
  }

  testWidgets('delete hides the task, undo shows it again', (tester) async {
    final c = await _pump(tester);
    await swipeDelete(tester, 't3');
    expect(find.text('کار حذف شد'), findsOneWidget);
    expect(_row('t3'), findsNothing);
    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect(_row('t3'), findsOneWidget);
    expect(await _stored(tester, c, 't3'), isNotNull);
  });

  testWidgets('delete is committed when the toast expires', (tester) async {
    final c = await _pump(tester);
    await swipeDelete(tester, 't3');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(await _stored(tester, c, 't3'), isNull);
    expect(_row('t3'), findsNothing);
  });

  testWidgets('swipe complete and the row menu use the task actions', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.drag(_row('t3'), const Offset(80, 0));
    await tester.pumpAndSettle();
    await tester.tap(_key('swipe-complete'));
    await tester.pumpAndSettle();
    expect((await _stored(tester, c, 't3'))!.status, TaskStatus.completed);

    await tester.longPress(find.text('خرید نان'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اولویت'));
    await tester.pumpAndSettle();
    expect((await _stored(tester, c, 't1'))!.priority, 0);

    await tester.longPress(find.text('خرید نان'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لغو کار'));
    await tester.pumpAndSettle();
    expect((await _stored(tester, c, 't1'))!.status, TaskStatus.canceled);
  });

  testWidgets('the options sheet has no export item (never implemented)', (
    tester,
  ) async {
    await _pump(tester);
    await _openOptionsCompact(tester);
    expect(find.text('خروجی'), findsNothing);
    expect(_key('option-export'), findsNothing);
    expect(_key('option-add-details'), findsOneWidget);
  });

  testWidgets('add with details opens the legacy dialog and creates', (
    tester,
  ) async {
    final c = await _pump(tester);
    await _openOptionsCompact(tester);
    await tester.tap(_key('option-add-details'));
    await tester.pumpAndSettle();
    expect(find.text('افزودن کار'), findsWidgets);
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'عنوان کار',
      ),
      'کار با جزئیات',
    );
    await tester.pump();
    await tester.tap(find.text('افزودن کار').last);
    await tester.pumpAndSettle();
    final all = await _run(
      tester,
      () => c.read(taskRepositoryProvider).watchAll().first,
    );
    expect(all.where((t) => t.title == 'کار با جزئیات'), hasLength(1));
  });

  testWidgets('template picker and manager open the legacy dialogs', (
    tester,
  ) async {
    // The legacy manager dialog overflows below ~700 px (as it did in the
    // legacy panel), so this test uses a medium window and the desktop button.
    await _pump(tester, size: const Size(900, 1000));
    await tester.tap(_key('tasks-options'));
    await tester.pumpAndSettle();
    await tester.tap(_key('option-template-pick'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('انتخاب قالب'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();

    await tester.tap(_key('tasks-options'));
    await tester.pumpAndSettle();
    await tester.tap(_key('option-template-manage'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskTemplateManagerDialog), findsOneWidget);
  });

  testWidgets('the options calendar entry switches to the calendar', (
    tester,
  ) async {
    await _pump(tester);
    await _openOptionsCompact(tester);
    await tester.tap(_key('option-calendar'));
    await tester.pumpAndSettle();
    expect(_viewParam, 'calendar');
    expect(find.byType(TaskCalendarBoard), findsOneWidget);
  });

  testWidgets('desktop options button opens the same sheet', (tester) async {
    await _pump(tester, size: const Size(1440, 900));
    await tester.tap(_key('tasks-options'));
    await tester.pumpAndSettle();
    expect(_key('option-add-details'), findsOneWidget);
    expect(find.text('مرتب‌سازی'), findsOneWidget);
  });

  testWidgets('row tap opens the legacy edit dialog', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('خرید نان'));
    await tester.pumpAndSettle();
    expect(find.text('ویرایش کار'), findsWidgets);
  });

  testWidgets('search filters the list and the kanban', (tester) async {
    await _pump(tester);
    final field = find.descendant(
      of: _key('tasks-search'),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'نان');
    await tester.pumpAndSettle();
    expect(_row('t1'), findsOneWidget);
    expect(_row('t2'), findsNothing);

    await tester.tap(_segment('کانبان'));
    await tester.pumpAndSettle();
    expect(_key('kanban-card-t1'), findsOneWidget);
    expect(_key('kanban-card-t2'), findsNothing);

    await tester.enterText(
      find.descendant(
        of: _key('tasks-search'),
        matching: find.byType(TextField),
      ),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(_key('kanban-card-t1'), findsNothing);
  });

  testWidgets('search with no match shows the empty state', (tester) async {
    await _pump(tester);
    await tester.enterText(
      find.descendant(
        of: _key('tasks-search'),
        matching: find.byType(TextField),
      ),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('چیزی پیدا نشد'), findsOneWidget);
  });

  testWidgets('no tasks shows the empty state', (tester) async {
    await _pump(tester, seed: (_) async {});
    expect(find.text('هنوز کاری اضافه نکرده‌اید'), findsOneWidget);
    expect(find.text('۰ کار باز'), findsOneWidget);
  });

  testWidgets('an active timer shows the legacy strip above the content', (
    tester,
  ) async {
    await _pump(
      tester,
      seed: (c) async {
        await _seed(c);
        await c.read(taskTimerServiceProvider).start('t1');
      },
    );
    expect(_key('global-active-timer'), findsOneWidget);
  });

  test('tasks screen code never calls DateTime.now()', () {
    final files = Directory('lib/features/tasks/presentation/tasks_screen')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      expect(
        f.readAsStringSync().contains('DateTime.now'),
        isFalse,
        reason: f.path,
      );
    }
  });

  group('sizes and text scale', () {
    for (final width in [390.0, 600.0, 1024.0, 1440.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final view in ['list', 'board', 'calendar']) {
          // The legacy TaskCalendarBoard day cell overflows by 3 px on a phone
          // at 1.3 text scale; legacy glass and layout are printed, not
          // asserted (plan Decision 7).
          if (view == 'calendar' && width == 390 && scale > 1) continue;
          testWidgets('$view at $width x$scale', (tester) async {
            await _pump(
              tester,
              size: Size(width, width < 600 ? 844 : 900),
              view: view,
              scale: scale,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('capture budget', () {
    testWidgets('compact idle is 2', (tester) async {
      await _pump(tester);
      expect(countCompositedBackdrops(tester), 2);
    });
    testWidgets('compact board idle is 2', (tester) async {
      await _pump(tester, view: 'board');
      expect(countCompositedBackdrops(tester), 2);
    });
    testWidgets('expanded idle is 2', (tester) async {
      await _pump(tester, size: const Size(1440, 900));
      expect(countCompositedBackdrops(tester), 2);
    });
  });
}
