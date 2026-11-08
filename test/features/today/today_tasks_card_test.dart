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
        tester.getTopLeft(find.byKey(ValueKey('today-task-$id'))).dy,
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
        of: find.byKey(const ValueKey('today-task-b')),
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
    expect(find.byKey(const ValueKey('today-task-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-task-b')), findsNothing);
    expect(find.text('و ۳ کار دیگر'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-tasks-more')));
    expect(opened, 'all');
  });

  testWidgets('empty: «امروز کاری نداری»', (tester) async {
    await tester.pumpWidget(_card(TodayAgenda.empty(_day)));
    expect(find.text('امروز کاری نداری'), findsOneWidget);
  });

  testWidgets('semantics: each check is a checkbox with the task title', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(agenda));
    expect(find.bySemanticsLabel('کار a'), findsWidgets);
    handle.dispose();
  });
}
