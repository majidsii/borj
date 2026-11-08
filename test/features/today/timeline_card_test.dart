import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/today/application/today_agenda_builder.dart';
import 'package:borj/features/today/presentation/timeline_card.dart';
import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_fade_expectations.dart';
import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

// Naive DateTimes are zone wall-clock values here (amendment A1).
final _day = DateTime(2026, 11, 4);
TodayEntry _e(String id, int h, int m, {int? minutes, bool done = false}) =>
    TodayEntry(
      taskId: id,
      title: id,
      done: done,
      recurring: false,
      localStart: DateTime(2026, 11, 4, h, m),
      durationMinutes: minutes,
    );

Widget _card(
  TodayAgenda agenda,
  DateTime now, {
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  brightness: b,
  textScale: s,
  SizedBox(
    width: 358,
    height: todayCardHeight(TodayCardSize.wide),
    child: TimelineCard(agenda: agenda, now: now),
  ),
);

void main() {
  final agenda = TodayAgenda(
    day: _day,
    timed: [
      _e('deep', 8, 30, minutes: 180, done: true),
      _e('meet', 15, 0, minutes: 90),
      _e('insurance', 18, 0),
    ],
    untimed: const [],
  );
  final now = DateTime(2026, 11, 4, 14, 30);

  test('range: default 8–20, widened to even hours that cover every block', () {
    expect(timelineRange(const []), (8, 20));
    expect(timelineRange([_e('early', 6, 15)]), (6, 20));
    expect(timelineRange([_e('late', 21, 0, minutes: 60)]), (8, 22));
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(
        _card(agenda, now, b: v.brightness, s: v.textScale),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('برنامهٔ امروز'), findsOneWidget);
    });
  }

  testWidgets('header names the next unfinished entry', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    expect(find.textContaining('meet'), findsWidgets);
    expect(find.text('بعدی:'), findsOneWidget);
  });

  testWidgets(
    'RTL: earlier blocks sit to the right; the now-line between them',
    (tester) async {
      await tester.pumpWidget(_card(agenda, now));
      final deep = tester.getRect(
        find.byKey(const ValueKey('timeline-block-deep')),
      );
      final meet = tester.getRect(
        find.byKey(const ValueKey('timeline-block-meet')),
      );
      final line = tester.getRect(find.byKey(const ValueKey('timeline-now')));
      expect(deep.center.dx, greaterThan(meet.center.dx));
      expect(line.center.dx, lessThan(deep.left));
      expect(line.center.dx, greaterThan(meet.right));
      expect(line.width, 2);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('timeline-now-pill')),
          matching: find.text('۱۴:۳۰'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a done block shows the check mark; blocks are flat GlassInner', (
    tester,
  ) async {
    await tester.pumpWidget(_card(agenda, now));
    expect(find.textContaining('deep ✓'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('timeline-block-meet')),
        matching: find.byType(GlassInner),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the card has no bare fade above its glass', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    expect(bareFadesAboveGlass(tester, find.byType(TimelineCard)), isEmpty);
  });

  testWidgets('elapsed tint spans from the start side to the now-line', (
    tester,
  ) async {
    await tester.pumpWidget(_card(agenda, now));
    final elapsed = tester.getRect(
      find.byKey(const ValueKey('timeline-elapsed')),
    );
    final line = tester.getRect(find.byKey(const ValueKey('timeline-now')));
    expect((elapsed.left - line.center.dx).abs(), lessThan(1.5));
  });

  testWidgets('now-line moves when now changes; no animation', (tester) async {
    await tester.pumpWidget(_card(agenda, now));
    final before = tester
        .getRect(find.byKey(const ValueKey('timeline-now')))
        .center
        .dx;
    await tester.pumpWidget(_card(agenda, now.add(const Duration(hours: 1))));
    final after = tester
        .getRect(find.byKey(const ValueKey('timeline-now')))
        .center
        .dx;
    expect(after, lessThan(before));
  });

  testWidgets('now outside the range: no now-line', (tester) async {
    await tester.pumpWidget(_card(agenda, DateTime(2026, 11, 4, 23, 0)));
    expect(find.byKey(const ValueKey('timeline-now')), findsNothing);
  });

  testWidgets('empty agenda: a calm message, no blocks', (tester) async {
    await tester.pumpWidget(_card(TodayAgenda.empty(_day), now));
    expect(find.text('برای امروز برنامهٔ زمان‌داری نداری'), findsOneWidget);
  });

  testWidgets('large size: overlapping entries use the second lane', (
    tester,
  ) async {
    final overlapping = TodayAgenda(
      day: _day,
      timed: [_e('a', 9, 0, minutes: 120), _e('b', 10, 0, minutes: 60)],
      untimed: const [],
    );
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 358,
          height: todayCardHeight(TodayCardSize.large),
          child: TimelineCard(
            agenda: overlapping,
            now: now,
            size: TodayCardSize.large,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final a = tester.getRect(find.byKey(const ValueKey('timeline-block-a')));
    final b = tester.getRect(find.byKey(const ValueKey('timeline-block-b')));
    expect(b.top, greaterThan(a.top));
  });

  testWidgets('inside a TodayGrid slot the card is exactly slot-sized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 358,
          child: TodayGrid(
            items: [
              TodayGridItem(
                id: 'timeline',
                size: TodayCardSize.wide,
                child: TimelineCard(agenda: agenda, now: now),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TimelineCard)),
      tester.getSize(find.byKey(const ValueKey('today-slot-timeline'))),
    );
    expect(
      tester.getSize(find.byType(TimelineCard)).height,
      todayCardHeight(TodayCardSize.wide),
    );
  });

  testWidgets('reduce motion: nothing moves', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        reduceMotion: true,
        SizedBox(
          width: 358,
          height: 164,
          child: TimelineCard(agenda: agenda, now: now),
        ),
      ),
    );
    await expectNoMovement(
      tester,
      within: find.byType(TimelineCard),
      trigger: () async => tester.pump(),
    );
  });

  double luminance(Color c) => c.computeLuminance();
  double contrast(Color a, Color b) {
    final l1 = luminance(a), l2 = luminance(b);
    return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
  }

  testWidgets('now-pill text is readable over danger in light and dark', (
    tester,
  ) async {
    for (final b in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(_card(agenda, now, b: b));
      await tester.pump(const Duration(seconds: 1)); // theme cross-fade
      final colors =
          (b == Brightness.dark ? AppTheme.dark : AppTheme.light).colors;
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('timeline-now-pill')),
          matching: find.text('۱۴:۳۰'),
        ),
      );
      expect(
        contrast(text.style!.color!, colors.danger),
        greaterThanOrEqualTo(4.5),
        reason: '$b',
      );
    }
    // Not vacuous: the old onTint white fails in dark.
    final dark = AppTheme.dark.colors;
    expect(
      contrast(AppTextTone.onTint.resolve(dark), dark.danger),
      lessThan(4.5),
    );
  });
}
