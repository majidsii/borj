import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../support/backdrop_layer_count.dart';
import '../../../support/glass_shape_limit.dart';
import '../../../support/glass_test_app.dart';

const _tz = 'Asia/Tehran';
// 2026-11-04 14:30 Tehran.
final _now = DateTime.utc(2026, 11, 4, 11);

DateTime _tehran(int d, int h, [int m = 0]) =>
    DateTime.utc(2026, 11, d, h, m).subtract(const Duration(minutes: 210));

TaskItem _task(
  String id, {
  DateTime? dueUtc,
  int number = 1,
  TaskStatus status = TaskStatus.planned,
}) {
  final t = DateTime.utc(2026, 11, 1);
  return TaskItem(
    id: id,
    displayNumber: number,
    title: 'کار $id',
    priority: 0,
    status: status,
    positionInStatus: 0,
    dueAtUtc: dueUtc,
    createdAtUtc: t,
    updatedAtUtc: t,
    completedAtUtc: status == TaskStatus.completed ? t : null,
    canceledAtUtc: status == TaskStatus.canceled ? t : null,
  );
}

TaskListView _view(
  List<TaskItem> tasks, {
  TaskSmartFilter filter = TaskSmartFilter.all,
  String query = '',
}) => buildTaskListView(
  tasks: tasks,
  nowUtc: _now,
  timeZoneId: _tz,
  filter: filter,
  query: query,
);

class _Log {
  final log = <String>[];
  TaskRowCallbacks get callbacks => TaskRowCallbacks(
    onToggle: (t) => log.add('toggle ${t.id}'),
    onOpen: (t) => log.add('open ${t.id}'),
    onDelete: (t) => log.add('delete ${t.id}'),
    menuFor: (t) => TaskRowMenuActions(
      onEdit: () => log.add('edit ${t.id}'),
      onCyclePriority: () => log.add('priority ${t.id}'),
      onToggleInProgress: () => log.add('progress ${t.id}'),
      onToggleCanceled: () => log.add('cancel ${t.id}'),
      onDelete: () => log.add('menu-delete ${t.id}'),
    ),
  );
}

Widget _list(
  TaskListView view, {
  TaskSmartFilter filter = TaskSmartFilter.all,
  String query = '',
  _Log? log,
}) => SingleChildScrollView(
  child: SizedBox(
    width: 360,
    child: TaskSectionList(
      view: view,
      filter: filter,
      query: query,
      callbacks: (log ?? _Log()).callbacks,
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(400, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(glassTestApp(child, overlayBackdrop: true));
}

final _mixed = [
  _task('over', dueUtc: _tehran(2, 10), number: 1),
  _task('today', dueUtc: _tehran(4, 15), number: 2),
  _task('soon', dueUtc: _tehran(8, 9), number: 3),
  _task('free', number: 4),
  _task('done', status: TaskStatus.completed, number: 5),
  _task('canc', status: TaskStatus.canceled, number: 6),
];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('sections appear in order with their headers', (tester) async {
    await _pump(tester, _list(_view(_mixed)));
    final ys = [
      for (final h in ['عقب‌افتاده', 'امروز', 'آینده', 'بی‌زمان'])
        tester.getTopLeft(find.text(h)).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('انجام‌شده'), findsNothing);
    final overdue = tester.widget<Text>(find.text('عقب‌افتاده'));
    expect(overdue.style!.color, AppTheme.light.colors.danger);
    final other = tester.widget<Text>(find.text('امروز'));
    expect(other.style!.color, AppTheme.light.colors.textSecondary);
  });

  testWidgets('done is collapsed behind the show button, then expands', (
    tester,
  ) async {
    await _pump(tester, _list(_view(_mixed)));
    expect(find.byKey(const ValueKey('task-row-done')), findsNothing);
    expect(find.byKey(const ValueKey('task-row-canc')), findsNothing);
    expect(find.text('نمایش انجام‌شده‌ها (۲)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tasks-show-done')));
    await tester.pump();
    expect(find.text('انجام‌شده'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-row-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-row-canc')), findsOneWidget);
    expect(find.byKey(const ValueKey('tasks-show-done')), findsNothing);
    expect(find.text('لغوشده'), findsOneWidget);
  });

  testWidgets('expanded done section collapses again', (tester) async {
    await _pump(tester, _list(_view(_mixed)));
    await tester.tap(find.byKey(const ValueKey('tasks-show-done')));
    await tester.pump();
    final hide = find.byKey(const ValueKey('tasks-hide-done'));
    expect(hide, findsOneWidget);
    expect(find.text('پنهان کردن انجام‌شده‌ها'), findsOneWidget);
    expect(
      tester.getTopLeft(hide).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const ValueKey('task-row-canc'))).dy,
      ),
    );
    await tester.tap(hide);
    await tester.pump();
    expect(find.byKey(const ValueKey('task-row-done')), findsNothing);
    expect(find.byKey(const ValueKey('tasks-show-done')), findsOneWidget);
  });

  testWidgets('a section of 20 rows renders two panels within the limit', (
    tester,
  ) async {
    final tasks = [
      for (var i = 0; i < 20; i++)
        _task('t$i', dueUtc: _tehran(4, 15, i), number: i + 1),
    ];
    await _pump(tester, _list(_view(tasks)));
    expect(find.byType(AppGlass), findsNWidgets(2));
    expect(find.byType(GlassScope), findsNWidgets(2));
    expect(find.byType(TaskGlassRow, skipOffstage: false), findsNWidgets(20));
    expectScopesWithinShapeLimit(tester);
  });

  testWidgets('one panel per section', (tester) async {
    await _pump(tester, _list(_view(_mixed)));
    expect(find.byType(AppGlass), findsNWidgets(4));
  });

  testWidgets('rows in امروز show the clock, others show the date', (
    tester,
  ) async {
    await _pump(tester, _list(_view(_mixed)));
    expect(find.text('۱۵:۰۰'), findsOneWidget);
    expect(find.text('۱۷ آبان'), findsOneWidget);
    expect(find.text('۱۱ آبان'), findsOneWidget);
    expect(find.text('۹:۰۰'), findsNothing);
    expect(find.text('۱۰:۰۰'), findsNothing);
  });

  testWidgets('row callbacks receive the task', (tester) async {
    final log = _Log();
    await _pump(tester, _list(_view(_mixed), log: log));
    await tester.tap(find.text('کار today'));
    await tester.pump();
    expect(log.log, ['open today']);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('task-row-over')),
        matching: find.byType(RoundCheck),
      ),
    );
    await tester.pump();
    expect(log.log.last, 'toggle over');
  });

  testWidgets('empty: no tasks at all', (tester) async {
    await _pump(tester, _list(_view(const [])));
    expect(find.text('هنوز کاری اضافه نکرده‌اید'), findsOneWidget);
    expect(
      find.text('با دکمهٔ «کار جدید» اولین کارت را بنویس.'),
      findsOneWidget,
    );
    expect(find.byType(AppGlass), findsNothing);
  });

  testWidgets('empty: search with no match', (tester) async {
    final view = _view(_mixed, query: 'zzz');
    await _pump(tester, _list(view, query: 'zzz'));
    expect(find.text('چیزی پیدا نشد'), findsOneWidget);
    expect(find.text('عبارت دیگری را جست‌وجو کنید.'), findsOneWidget);
  });

  for (final (filter, title) in [
    (TaskSmartFilter.today, 'امروز کاری نداری'),
    (TaskSmartFilter.overdue, 'کار عقب‌افتاده‌ای نداری'),
    (TaskSmartFilter.timed, 'کار زمان‌داری نداری'),
  ]) {
    testWidgets('empty: ${filter.name} tile', (tester) async {
      final tasks = [_task('free')];
      await _pump(tester, _list(_view(tasks, filter: filter), filter: filter));
      expect(find.text(title), findsOneWidget);
    });
  }

  testWidgets('adds one content capture and no group of its own', (
    tester,
  ) async {
    await _pump(tester, GlassBackdropGroup(child: _list(_view(_mixed))));
    expect(
      find.descendant(
        of: find.byType(TaskSectionList),
        matching: find.byType(GlassBackdropGroup),
      ),
      findsNothing,
    );
    expect(countCompositedBackdrops(tester), 1);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        glassTestApp(
          _list(_view(_mixed)),
          brightness: v.brightness,
          textScale: v.textScale,
          overlayBackdrop: true,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
