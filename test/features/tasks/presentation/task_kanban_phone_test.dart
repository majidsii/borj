import 'package:borj/app/design/design.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_phone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../support/backdrop_layer_count.dart';
import '../../../support/glass_shape_limit.dart';
import '../../../support/glass_test_app.dart';
import '../../../support/reduced_motion_expectations.dart';
import '../../../support/test_database.dart';

class _Env {
  _Env() {
    db = openTestDatabase();
    repo = DriftTaskRepository(db);
    actions = TaskActions(
      repository: repo,
      pending: PendingTaskDeletions(),
      clock: FixedAppClock(
        utcValue: DateTime.utc(2026, 11, 11, 9),
        localValue: DateTime(2026, 11, 11, 9),
      ),
    );
  }

  late final AppDatabase db;
  late final DriftTaskRepository repo;
  late final TaskActions actions;
  final opened = <String>[];
  final deleted = <String>[];
  final errors = <Object>[];

  Future<void> seed(TaskStatus status, List<String> titles) async {
    for (final title in titles.reversed) {
      final id = await actions.createAndReturnId(title: title, priority: 0);
      if (status != TaskStatus.planned) {
        await actions.setStatus((await repo.getById(id))!, status);
      }
    }
  }

  Future<List<String>> order(TaskStatus status) async {
    final all = await repo.watchAll().first;
    final list = all.where((t) => t.status == status).toList()
      ..sort((a, b) => a.positionInStatus.compareTo(b.positionInStatus));
    return [for (final t in list) t.title];
  }

  Widget board() => StreamBuilder<List<TaskItem>>(
    stream: repo.watchAll(),
    builder: (context, snap) => TaskKanbanPhone(
      tasks: snap.data ?? const <TaskItem>[],
      actions: actions,
      onOpen: (t) => opened.add(t.title),
      onDelete: (t) => deleted.add(t.title),
      timeZoneId: 'Asia/Tehran',
      onError: errors.add,
    ),
  );
}

Widget _app(
  _Env env, {
  Brightness b = Brightness.light,
  double s = 1.0,
  bool reduce = false,
}) => glassTestApp(
  GlassBackdropGroup(
    child: SizedBox(width: 390, height: 760, child: env.board()),
  ),
  brightness: b,
  textScale: s,
  reduceMotion: reduce,
  overlayBackdrop: true,
);

Future<void> _pump(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

Future<_Env> _setup(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = _Env();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await env.db.close();
  });
  await tester.runAsync(() async {
    await env.seed(TaskStatus.planned, ['الف', 'ب', 'ج']);
    await env.seed(TaskStatus.completed, ['د']);
  });
  return env;
}

Finder _seg(TaskStatus s) => find.byKey(ValueKey('kanban-status-${s.name}'));

/// Long-press [from], move to [to], optionally inspect, release.
Future<void> _drag(
  WidgetTester tester,
  Finder from,
  Offset to, {
  VoidCallback? onMidDrag,
}) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 600));
  await g.moveBy(const Offset(0, 8));
  await tester.pump();
  await g.moveTo(to);
  await tester.pump();
  onMidDrag?.call();
  await g.up();
  await tester.pump();
  await _pump(tester);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('segments show counts; header reads column 1 of 4', (
    tester,
  ) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    String numberIn(TaskStatus s) => tester
        .widgetList<AppText>(
          find.descendant(of: _seg(s), matching: find.byType(AppText)),
        )
        .first
        .data;
    expect(numberIn(TaskStatus.planned), '۳');
    expect(numberIn(TaskStatus.inProgress), '۰');
    expect(numberIn(TaskStatus.completed), '۱');
    expect(numberIn(TaskStatus.canceled), '۰');
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-column-position')))
          .data,
      'ستون ۱ از ۴',
    );
    expect(find.byKey(const ValueKey('kanban-card-')), findsNothing);
    expect(find.text('الف'), findsOneWidget);
  });

  testWidgets('tapping انجام‌شده pages to column 3', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    await tester.tap(_seg(TaskStatus.completed));
    await _pump(tester);
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-column-position')))
          .data,
      'ستون ۳ از ۴',
    );
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-column-title')))
          .data,
      'انجام‌شده',
    );
    expect(find.text('د'), findsOneWidget);
    expect(find.text('الف'), findsNothing);
  });

  testWidgets('swiping the pages updates the segmented', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    // RTL: dragging right reveals the next page.
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
    await _pump(tester);
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-column-position')))
          .data,
      'ستون ۲ از ۴',
    );
    expect(find.text('کاری در حال انجام نیست.'), findsOneWidget);
    // Selected segment shows the lens.
    expect(
      find.descendant(
        of: _seg(TaskStatus.inProgress),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _seg(TaskStatus.planned),
        matching: find.byType(GlassInner),
      ),
      findsNothing,
    );
  });

  testWidgets('empty column text per status', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    for (final (s, text) in [
      (TaskStatus.inProgress, 'کاری در حال انجام نیست.'),
      (TaskStatus.canceled, 'کاری لغو نشده است.'),
    ]) {
      await tester.tap(_seg(s));
      await _pump(tester);
      expect(find.text(text), findsOneWidget, reason: s.name);
    }
    final empty = _Env();
    addTearDown(empty.db.close);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(empty));
    await _pump(tester);
    expect(find.text('کاری برای برنامه‌ریزی وجود ندارد.'), findsOneWidget);
    await tester.tap(_seg(TaskStatus.completed));
    await _pump(tester);
    expect(find.text('کاری انجام نشده است.'), findsOneWidget);
  });

  testWidgets('dragging a card onto a segment moves it to the end', (
    tester,
  ) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expect(find.byKey(const ValueKey('kanban-drop-hint')), findsNothing);
    await _drag(
      tester,
      find.text('الف'),
      tester.getCenter(_seg(TaskStatus.inProgress)),
      onMidDrag: () {
        expect(find.byKey(const ValueKey('kanban-drop-hint')), findsOneWidget);
        expect(
          find.text('نگه دارید و بکشید تا به ستون دیگر بروید'),
          findsOneWidget,
        );
      },
    );
    expect(await tester.runAsync(() => env.order(TaskStatus.inProgress)), [
      'الف',
    ]);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'ج',
    ]);
    expect(find.byKey(const ValueKey('kanban-drop-hint')), findsNothing);
    expect(env.errors, isEmpty);
  });

  testWidgets('dropping onto a segment with cards appends', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    await _drag(
      tester,
      find.text('الف'),
      tester.getCenter(_seg(TaskStatus.completed)),
    );
    expect(await tester.runAsync(() => env.order(TaskStatus.completed)), [
      'د',
      'الف',
    ]);
  });

  testWidgets('dragging within a column reorders', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'الف',
      'ب',
      'ج',
    ]);
    await _drag(tester, find.text('الف'), tester.getCenter(find.text('ج')));
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'ج',
      'الف',
    ]);
    await _drag(tester, find.text('الف'), tester.getCenter(find.text('ب')));
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'الف',
      'ب',
      'ج',
    ]);
  });

  testWidgets('menu moves to the next column and down without dragging', (
    tester,
  ) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    Finder menuOf(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(AppGlass)),
      matching: find.byIcon(Icons.more_horiz),
    );
    await tester.tap(menuOf('الف'));
    await _pump(tester);
    expect(find.text('انتقال به ستون قبلی'), findsNothing);
    expect(find.text('بالا'), findsNothing);
    await tester.tap(find.text('پایین'));
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'الف',
      'ج',
    ]);

    await tester.tap(menuOf('ب'));
    await _pump(tester);
    await tester.tap(find.text('انتقال به ستون بعدی'));
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.inProgress)), [
      'ب',
    ]);
    expect(env.errors, isEmpty);
  });

  testWidgets('menu: edit opens, delete calls onDelete only', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    final menu = find.byIcon(Icons.more_horiz).first;
    await tester.tap(menu);
    await _pump(tester);
    await tester.tap(find.text('حذف'));
    await _pump(tester);
    expect(env.deleted, ['الف']);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'الف',
      'ب',
      'ج',
    ]);
    await tester.tap(find.text('ب'));
    await _pump(tester);
    expect(env.opened, ['ب']);
  });

  testWidgets('canceled cards are tertiary with line-through', (tester) async {
    final env = _Env();
    addTearDown(env.db.close);
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => env.seed(TaskStatus.canceled, ['لغو']));
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    await tester.tap(_seg(TaskStatus.canceled));
    await _pump(tester);
    final style = tester.widget<Text>(find.text('لغو')).style!;
    expect(style.decoration, TextDecoration.lineThrough);
  });

  testWidgets('the dragged card is drawn under reduceTransparency', (
    tester,
  ) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    await _drag(
      tester,
      find.text('الف'),
      tester.getCenter(find.text('ج')) + const Offset(0, 4),
      onMidDrag: () {
        final feedback = find.byKey(const ValueKey('kanban-drag-feedback'));
        expect(feedback, findsOneWidget);
        final scope = tester.widget<GlassPreferencesScope>(
          find
              .ancestor(
                of: feedback,
                matching: find.byType(GlassPreferencesScope),
              )
              .first,
        );
        expect(scope.reduceTransparency, isTrue);
        // The card is lifted by 1.04.
        final lift = tester.widget<Transform>(
          find.descendant(of: feedback, matching: find.byType(Transform)).first,
        );
        expect(lift.transform.getMaxScaleOnAxis(), closeTo(1.04, 1e-6));
      },
    );
  });

  testWidgets('capture budget stays within 3 during a drag', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    var worst = countCompositedBackdrops(tester);
    final g = await tester.startGesture(tester.getCenter(find.text('الف')));
    await tester.pump(const Duration(milliseconds: 600));
    await g.moveBy(const Offset(0, 8));
    await tester.pump();
    for (var i = 1; i <= 6; i++) {
      await g.moveTo(
        tester.getCenter(_seg(TaskStatus.inProgress)) + Offset(i * 4.0, 0),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final n = countCompositedBackdrops(tester);
      worst = worst < n ? n : worst;
    }
    await g.up();
    await _pump(tester);
    expect(worst, lessThanOrEqualTo(3));
    expect(worst, greaterThanOrEqualTo(1));
  });

  testWidgets('reduce motion: paging jumps, no lift scale', (tester) async {
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env, reduce: true));
    await _pump(tester);
    await tester.tap(_seg(TaskStatus.completed));
    await tester.pump();
    final page = tester.widget<PageView>(find.byType(PageView));
    expect(page.controller!.page, 2.0);

    await tester.tap(_seg(TaskStatus.planned));
    await tester.pump();
    await expectNoMovement(
      tester,
      within: find.byType(PageView),
      trigger: () async {
        await tester.tap(_seg(TaskStatus.completed));
      },
    );
    await tester.tap(_seg(TaskStatus.planned));
    await _pump(tester);
    await _drag(
      tester,
      find.text('الف'),
      tester.getCenter(find.text('ج')) + const Offset(0, 4),
      onMidDrag: () {
        final feedback = find.byKey(const ValueKey('kanban-drag-feedback'));
        expect(feedback, findsOneWidget);
        expect(
          find.descendant(of: feedback, matching: find.byType(Transform)),
          findsNothing,
        );
      },
    );
  });

  testWidgets('more than 16 cards use extra scopes', (tester) async {
    final env = _Env();
    addTearDown(env.db.close);
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => env.seed(TaskStatus.planned, [for (var i = 0; i < 20; i++) 't$i']),
    );
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expectScopesWithinShapeLimit(tester);
    expect(tester.takeException(), isNull);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      final env = await _setup(tester);
      await tester.pumpWidget(_app(env, b: v.brightness, s: v.textScale));
      await _pump(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(_seg(TaskStatus.completed));
      await _pump(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
