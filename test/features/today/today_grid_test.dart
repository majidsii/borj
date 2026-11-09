import 'package:borj/features/today/presentation/today_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  test('sizes and heights', () {
    expect([TodayCardSize.small.columns, TodayCardSize.small.rows], [1, 2]);
    expect([TodayCardSize.wide.columns, TodayCardSize.wide.rows], [2, 2]);
    expect([TodayCardSize.large.columns, TodayCardSize.large.rows], [2, 4]);
    expect(todayCardHeight(TodayCardSize.small), 164);
    expect(todayCardHeight(TodayCardSize.large), 340);
  });

  test('columns follow the grid width', () {
    expect(todayColumnsForWidth(412), 2);
    expect(todayColumnsForWidth(719), 2);
    expect(todayColumnsForWidth(720), 4);
    expect(todayColumnsForWidth(1188), 4);
  });

  String slots(List<TodayCardSize> sizes, int columns) => [
    for (final s in packTodayGrid(sizes, columns: columns))
      '${s.column},${s.row}',
  ].join(' ');

  test('default layout on 2 columns stacks', () {
    expect(
      slots([TodayCardSize.wide, TodayCardSize.large, TodayCardSize.wide], 2),
      '0,0 0,2 0,6',
    );
  });

  test(
    'default layout on 4 columns: large beside wide, then wide under the first',
    () {
      expect(
        slots([TodayCardSize.wide, TodayCardSize.large, TodayCardSize.wide], 4),
        '0,0 2,0 0,2',
      );
    },
  );

  test('dense flow pulls a later small card into a gap', () {
    expect(
      slots([TodayCardSize.small, TodayCardSize.wide, TodayCardSize.small], 2),
      '0,0 0,2 1,0',
    );
  });

  test('a card wider than the grid is clamped', () {
    final s = packTodayGrid([TodayCardSize.wide], columns: 1).single;
    expect(s.columns, 1);
  });

  testWidgets('TodayGrid places items in RTL from the right with gap 12', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 412, // 2 × 200 + 12
          child: TodayGrid(
            items: const [
              TodayGridItem(
                id: 'a',
                size: TodayCardSize.small,
                child: SizedBox.expand(key: ValueKey('a')),
              ),
              TodayGridItem(
                id: 'b',
                size: TodayCardSize.small,
                child: SizedBox.expand(key: ValueKey('b')),
              ),
              TodayGridItem(
                id: 'c',
                size: TodayCardSize.wide,
                child: SizedBox.expand(key: ValueKey('c')),
              ),
            ],
          ),
        ),
      ),
    );
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    final c = tester.getRect(find.byKey(const ValueKey('c')));
    expect(a.width, 200);
    expect(a.height, 164);
    expect(
      a.left,
      greaterThan(b.left),
      reason: 'column 0 is on the right in RTL',
    );
    expect(a.left - b.right, 12);
    expect(c.top - a.bottom, 12);
    expect(c.width, 412);
    expect(tester.getSize(find.byType(TodayGrid)).height, 164 * 2 + 12);
  });

  testWidgets('a 1188 px grid has 4 columns: tasks beside the timeline', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1300, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      glassTestApp(
        SizedBox(
          width: 1188,
          child: TodayGrid(
            items: const [
              TodayGridItem(
                id: 'a',
                size: TodayCardSize.wide,
                child: SizedBox.expand(key: ValueKey('a')),
              ),
              TodayGridItem(
                id: 'b',
                size: TodayCardSize.large,
                child: SizedBox.expand(key: ValueKey('b')),
              ),
            ],
          ),
        ),
      ),
    );
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(a.top, b.top, reason: 'two wide-ish cards share the first row');
    expect(a.width, (1188 - 36) / 4 * 2 + 12);
  });
}
