import 'package:borj/app/design/design.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_desktop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../support/backdrop_layer_count.dart';
import '../../../support/glass_shape_limit.dart';
import '../../../support/glass_test_app.dart';
import '../../../support/test_database.dart';

class _Env {
  _Env() {
    db = openTestDatabase();
    repo = DriftTaskRepository(db);
    pending = PendingTaskDeletions();
    actions = TaskActions(
      repository: repo,
      pending: pending,
      clock: FixedAppClock(
        utcValue: DateTime.utc(2026, 11, 11, 9),
        localValue: DateTime(2026, 11, 11, 9),
      ),
    );
  }

  late final AppDatabase db;
  late final DriftTaskRepository repo;
  late final PendingTaskDeletions pending;
  late final TaskActions actions;
  final opened = <String>[];
  final errors = <Object>[];
  final deleted = <String>[];

  /// Creates [titles] in [status] so that they end up in the given order.
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
    builder: (context, snap) => TaskKanbanDesktop(
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
  double width = 1280,
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  SizedBox(width: width, height: 600, child: env.board()),
  brightness: b,
  textScale: s,
  overlayBackdrop: true,
);

Future<void> _pump(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

Future<void> _drag(
  WidgetTester tester,
  Finder from,
  Offset to, {
  void Function()? onMidDrag,
}) async {
  final g = await tester.startGesture(
    tester.getCenter(from),
    kind: PointerDeviceKind.mouse,
  );
  await g.moveBy(const Offset(-12, 0));
  await tester.pump();
  await g.moveTo(to);
  await tester.pump();
  onMidDrag?.call();
  await g.up();
  await tester.pump();
  await _pump(tester);
}

Future<_Env> _setup(WidgetTester tester) async {
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

Finder _column(TaskStatus s) => find.byKey(ValueKey('kanban-column-${s.name}'));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('four columns in RTL order with counts', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    final xs = [
      for (final s in TaskStatus.values) tester.getCenter(_column(s)).dx,
    ];
    expect(xs[0] > xs[1] && xs[1] > xs[2] && xs[2] > xs[3], isTrue);
    expect(find.text('برنامه‌ریزی‌شده'), findsOneWidget);
    expect(find.text('لغوشده'), findsOneWidget);
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-count-planned')))
          .data,
      '۳ کار',
    );
    expect(
      tester
          .widget<AppText>(find.byKey(const ValueKey('kanban-count-completed')))
          .data,
      '۱ کار',
    );
    expect(find.text('کاری در حال انجام نیست.'), findsOneWidget);
    expect(find.text('کاری لغو نشده است.'), findsOneWidget);
  });

  testWidgets('dragging a card to another column changes its status', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    await _drag(
      tester,
      find.text('الف'),
      tester.getCenter(_column(TaskStatus.inProgress)),
    );
    final t = await tester.runAsync(() => env.order(TaskStatus.inProgress));
    expect(t, ['الف']);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'ج',
    ]);
    expect(env.errors, isEmpty);
  });

  testWidgets('dropping on a card inserts at that position', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    // Into another column, before its first card.
    await _drag(tester, find.text('ب'), tester.getCenter(find.text('د')));
    expect(await tester.runAsync(() => env.order(TaskStatus.completed)), [
      'ب',
      'د',
    ]);
  });

  testWidgets('dragging within a column reorders', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    await _drag(tester, find.text('الف'), tester.getCenter(find.text('ج')));
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'ج',
      'الف',
    ]);
  });

  testWidgets('keyboard: arrows move a focused card, Enter opens it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    final cardFocus = find.ancestor(
      of: find.text('الف'),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Focus &&
            (w.focusNode?.debugLabel ?? '').startsWith('kanban-card-'),
      ),
    );
    tester.widget<Focus>(cardFocus).focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'الف',
      'ج',
    ]);

    // Focus survives the move: RTL left = the next status column.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.inProgress)), [
      'الف',
    ]);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'ج',
    ]);

    // Right goes back (the previous status, same index), down then up.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'الف',
      'ب',
      'ج',
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'ب',
      'الف',
      'ج',
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await _pump(tester);
    expect(await tester.runAsync(() => env.order(TaskStatus.planned)), [
      'الف',
      'ب',
      'ج',
    ]);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(env.opened, ['الف']);
    expect(env.errors, isEmpty);
  });

  testWidgets('narrow width scrolls horizontally without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env, width: 800));
    await _pump(tester);
    expect(tester.takeException(), isNull);
    final scroll = find.byKey(const ValueKey('kanban-horizontal-scroll'));
    expect(scroll, findsOneWidget);
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(tester.getSize(_column(TaskStatus.planned)).width, 260);
  });

  testWidgets('wide width flexes columns without scrolling', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expect(
      find.byKey(const ValueKey('kanban-horizontal-scroll')),
      findsNothing,
    );
    expect(tester.getSize(_column(TaskStatus.planned)).width, greaterThan(260));
  });

  testWidgets('cards are inner glass; one panel per column', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expect(find.byType(AppGlass), findsNWidgets(4));
    expect(find.byType(GlassScope), findsNWidgets(4));
    expect(find.byType(GlassInner), findsNWidgets(4));
    expect(
      find.descendant(
        of: find.byType(AppGlass),
        matching: find.byType(GlassInner),
      ),
      findsNWidgets(4),
    );
    expectScopesWithinShapeLimit(tester);
  });

  testWidgets('capture budget stays within 4 during a drag', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    var worst = countCompositedBackdrops(tester);
    final g = await tester.startGesture(
      tester.getCenter(find.text('الف')),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveBy(const Offset(-12, 0));
    await tester.pump();
    worst = worst < countCompositedBackdrops(tester)
        ? countCompositedBackdrops(tester)
        : worst;
    for (var i = 1; i <= 5; i++) {
      await g.moveTo(
        tester.getCenter(_column(TaskStatus.inProgress)) + Offset(i * 4.0, 0),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final n = countCompositedBackdrops(tester);
      worst = worst < n ? n : worst;
    }
    await g.up();
    await _pump(tester);
    expect(worst, lessThanOrEqualTo(4));
    expect(worst, greaterThanOrEqualTo(1));
  });

  testWidgets('menu: secondary tap opens it, delete calls onDelete', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.pumpWidget(_app(env));
    await _pump(tester);

    await tester.tapAt(
      tester.getCenter(find.text('ب')),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('اولویت'), findsOneWidget);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(env.deleted, ['ب']);

    await tester.tap(find.byKey(const ValueKey('kanban-menu-الف')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اولویت'));
    await _pump(tester);
    final a = (await tester.runAsync(
      () => env.repo.watchAll().first,
    ))!.firstWhere((t) => t.title == 'الف');
    expect(a.priority, 1);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final env = await _setup(tester);
      await tester.pumpWidget(_app(env, b: v.brightness, s: v.textScale));
      await _pump(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('card shows the Jalali date in the task zone', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await _setup(tester);
    await tester.runAsync(() async {
      final id = await env.actions.createAndReturnId(
        title: 'سررسیددار',
        priority: 2,
        dueAtUtc: DateTime.utc(2026, 11, 13, 11, 30),
      );
      expect(id, isNotEmpty);
    });
    await tester.pumpWidget(_app(env));
    await _pump(tester);
    expect(find.text('۲۲ آبان'), findsOneWidget);
    expect(find.text('اولویت متوسط'), findsOneWidget);
  });
}
