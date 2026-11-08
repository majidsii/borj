import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Card sizes of motion spec §5.1.
enum TodayCardSize {
  small(1, 2),
  wide(2, 2),
  large(2, 4);

  const TodayCardSize(this.columns, this.rows);

  final int columns;
  final int rows;
}

const double todayRowUnit = 76;
const double todayGap = 12;

double todayCardHeight(TodayCardSize size) =>
    size.rows * todayRowUnit + (size.rows - 1) * todayGap;

/// The column count follows the grid's own width (plan Decision 7).
int todayColumnsForWidth(double width) => width >= 720 ? 4 : 2;

@immutable
final class TodaySlot {
  const TodaySlot({
    required this.column,
    required this.row,
    required this.columns,
    required this.rows,
  });

  final int column;
  final int row;
  final int columns;
  final int rows;
}

/// Dense auto-flow: each card takes the first place where it fits.
List<TodaySlot> packTodayGrid(
  List<TodayCardSize> sizes, {
  required int columns,
}) {
  final taken = <(int, int)>{};
  final out = <TodaySlot>[];
  for (final size in sizes) {
    final w = math.min(size.columns, columns);
    final h = size.rows;
    for (var row = 0; ; row++) {
      int? found;
      for (var col = 0; col + w <= columns; col++) {
        var free = true;
        for (var r = row; r < row + h && free; r++) {
          for (var c = col; c < col + w && free; c++) {
            if (taken.contains((r, c))) free = false;
          }
        }
        if (free) {
          found = col;
          break;
        }
      }
      if (found != null) {
        for (var r = row; r < row + h; r++) {
          for (var c = found; c < found + w; c++) {
            taken.add((r, c));
          }
        }
        out.add(TodaySlot(column: found, row: row, columns: w, rows: h));
        break;
      }
    }
  }
  return out;
}

@immutable
final class TodayGridItem {
  const TodayGridItem({
    required this.id,
    required this.size,
    required this.child,
  });

  final String id;
  final TodayCardSize size;
  final Widget child;
}

/// Lays Today's cards on the §5.1 grid (start side first, so RTL fills from
/// the right).
class TodayGrid extends StatelessWidget {
  const TodayGrid({required this.items, super.key});

  final List<TodayGridItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = todayColumnsForWidth(constraints.maxWidth);
        final slots = packTodayGrid([
          for (final i in items) i.size,
        ], columns: columns);
        final colWidth =
            (constraints.maxWidth - (columns - 1) * todayGap) / columns;
        var bottom = 0.0;
        final children = <Widget>[];
        for (var i = 0; i < items.length; i++) {
          final s = slots[i];
          final top = s.row * (todayRowUnit + todayGap);
          final height = s.rows * todayRowUnit + (s.rows - 1) * todayGap;
          bottom = math.max(bottom, top + height);
          children.add(
            PositionedDirectional(
              key: ValueKey('today-slot-${items[i].id}'),
              start: s.column * (colWidth + todayGap),
              top: top,
              width: s.columns * colWidth + (s.columns - 1) * todayGap,
              height: height,
              child: items[i].child,
            ),
          );
        }
        return SizedBox(
          height: bottom,
          child: Stack(children: children),
        );
      },
    );
  }
}
