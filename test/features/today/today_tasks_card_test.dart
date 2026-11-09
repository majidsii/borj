import 'package:borj/app/design/design.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:borj/features/today/presentation/today_tasks_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

final _day = DateTime(2026, 11, 4);
TodayEntry _t(String id, int h, {bool done = false}) => TodayEntry(
  taskId: id,
  title: 'کار $id',
  done: done,
  recurring: false,
  localStart: DateTime(2026, 11, 4, h),
);
TodayEntry _u(String id) =>
    TodayEntry(taskId: id, title: 'کار $id', done: false, recurring: false);

Widget _card(
  TodayAgenda a, {
  TodayCardSize size = TodayCardSize.large,
  double width = 358,
  Size window = const Size(390, 844),
  ValueChanged<TodayEntry>? onToggle,
  VoidCallback? onShowAll,
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  brightness: b,
  textScale: s,
  MediaQuery(
    data: MediaQueryData(size: window),
    child: SizedBox(
      width: width,
      height: todayCardHeight(size),
      child: TodayTasksCard(
        agenda: a,
        now: DateTime(2026, 11, 4, 14, 30),
        size: size,
        onToggle: onToggle ?? (_) {},
        onShowAll: onShowAll ?? () {},
      ),
    ),
  ),
);

void main() {
  final agenda = TodayAgenda(
    day: _day,
    timed: [_t('a', 7, done: true), _t('b', 15), _t('c', 18)],
    untimed: [_u('d')],
  );

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(_card(agenda, b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact: rows in order, no group headers, times in Persian', (
    tester,
  ) async {
    await tester.pumpWidget(_card(agenda));
    final ys = [
      for (final id in ['a', 'b', 'c', 'd'])
        tester.getTopLeft(find.byKey(ValueKey('today-task-$id@one-off'))).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('صبح'), findsNothing);
    expect(find.text('۱۵:۰۰'), findsOneWidget);
  });

  testWidgets('expanded: group headers صبح / بعدازظهر / بی‌زمان', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(agenda, width: 572, window: const Size(1440, 900)),
    );
    expect(find.text('صبح'), findsOneWidget);
    expect(find.text('بعدازظهر'), findsOneWidget);
    expect(find.text('بی‌زمان'), findsOneWidget);
  });

  testWidgets('tapping the check toggles that entry', (tester) async {
    TodayEntry? toggled;
    await tester.pumpWidget(_card(agenda, onToggle: (e) => toggled = e));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('today-task-b@one-off')),
        matching: find.byType(RoundCheck),
      ),
    );
    expect(toggled?.taskId, 'b');
  });

  testWidgets('overflow: a small card shows 1 row and «و ۳ کار دیگر»', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      _card(
        agenda,
        size: TodayCardSize.small,
        width: 173,
        onShowAll: () => opened = 'all',
      ),
    );
    expect(find.byKey(const ValueKey('today-task-a@one-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-task-b@one-off')), findsNothing);
    expect(find.text('و ۳ کار دیگر'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-tasks-more')));
    expect(opened, 'all');
  });

  testWidgets('empty: «امروز کاری نداری»', (tester) async {
    await tester.pumpWidget(_card(TodayAgenda.empty(_day)));
    expect(find.text('امروز کاری نداری'), findsOneWidget);
  });

  testWidgets('semantics: one node per row with title, time and state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(agenda));
    expect(
      tester.getSemantics(find.bySemanticsLabel('کار b، ۱۵:۰۰')),
      matchesSemantics(
        label: 'کار b، ۱۵:۰۰',
        hasCheckedState: true,
        isChecked: false,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(find.bySemanticsLabel('کار b، ۱۵:۰۰'), findsOneWidget);
    expect(find.bySemanticsLabel('کار b'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('کار a، ۷:۰۰')),
      matchesSemantics(
        label: 'کار a، ۷:۰۰',
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(find.bySemanticsLabel('کار d'), findsOneWidget);
    handle.dispose();
  });

  final wideWindow = const Size(1440, 900);

  for (final size in [TodayCardSize.small, TodayCardSize.wide]) {
    testWidgets('grouped ${size.name}: header + 1 row + overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _card(agenda, size: size, width: 300, window: wideWindow),
      );
      expect(find.text('صبح'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('today-task-a@one-off')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('today-task-b@one-off')), findsNothing);
      expect(find.text('و ۳ کار دیگر'), findsOneWidget);
    });

    testWidgets('${size.name} at 1.3 text scale ellipsizes, no overflow', (
      tester,
    ) async {
      final long = TodayAgenda(
        day: _day,
        timed: [
          TodayEntry(
            taskId: 'x',
            title: 'یک عنوان خیلی خیلی طولانی برای آزمون کوتاه شدن متن',
            done: false,
            recurring: false,
            localStart: DateTime(2026, 11, 4, 15),
          ),
        ],
        untimed: [_u('y'), _u('z')],
      );
      await tester.pumpWidget(_card(long, size: size, width: 173, s: 1.3));
      expect(tester.takeException(), isNull);
      final t = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('today-task-x@one-off')),
          matching: find.textContaining('یک عنوان'),
        ),
      );
      expect(t.overflow, TextOverflow.ellipsis);
    });
  }

  testWidgets('large ungrouped: 8 entries show 5 rows + «و ۳ کار دیگر»', (
    tester,
  ) async {
    final many = TodayAgenda(
      day: _day,
      timed: const [],
      untimed: [for (var i = 0; i < 8; i++) _u('e$i')],
    );
    await tester.pumpWidget(_card(many));
    expect(find.byKey(const ValueKey('today-task-e4@one-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-task-e5@one-off')), findsNothing);
    expect(find.text('و ۳ کار دیگر'), findsOneWidget);
  });

  testWidgets('large with exactly 6 entries shows all, no overflow', (
    tester,
  ) async {
    final six = TodayAgenda(
      day: _day,
      timed: const [],
      untimed: [for (var i = 0; i < 6; i++) _u('e$i')],
    );
    await tester.pumpWidget(_card(six));
    expect(find.byKey(const ValueKey('today-task-e5@one-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-tasks-more')), findsNothing);
  });

  testWidgets('row body and check each toggle exactly once', (tester) async {
    final toggled = <String>[];
    await tester.pumpWidget(
      _card(agenda, onToggle: (e) => toggled.add(e.taskId)),
    );
    await tester.tap(find.text('کار b'));
    expect(toggled, ['b']);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('today-task-c@one-off')),
        matching: find.byType(RoundCheck),
      ),
    );
    expect(toggled, ['b', 'c']);
  });

  testWidgets('one keyboard stop per row (the check only)', (tester) async {
    final two = TodayAgenda(
      day: _day,
      timed: [_t('a', 15), _t('b', 18)],
      untimed: const [],
    );
    await tester.pumpWidget(_card(two));
    final stops = FocusManager.instance.rootScope.traversalDescendants.where(
      (n) => n is! FocusScopeNode && n.canRequestFocus,
    );
    expect(stops.length, 2);
    // The row tap still works.
    var toggled = 0;
    await tester.pumpWidget(_card(two, onToggle: (_) => toggled++));
    await tester.tap(find.text('کار a'));
    expect(toggled, 1);
  });
}
