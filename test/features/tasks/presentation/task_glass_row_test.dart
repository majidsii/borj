import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/glass_test_app.dart';
import '../../../support/reduced_motion_expectations.dart';

final _stamp = DateTime.utc(2026, 11, 1);

TaskListEntry _entry({
  String id = 't1',
  String title = 'خرید نان',
  int priority = 0,
  TaskStatus status = TaskStatus.planned,
  DateTime? at,
}) {
  final done = status == TaskStatus.completed;
  final canceled = status == TaskStatus.canceled;
  return TaskListEntry(
    task: TaskItem(
      id: id,
      displayNumber: 1,
      title: title,
      priority: priority,
      status: status,
      positionInStatus: 0,
      dueAtUtc: at,
      createdAtUtc: _stamp,
      updatedAtUtc: _stamp,
      completedAtUtc: done ? _stamp : null,
      canceledAtUtc: canceled ? _stamp : null,
    ),
    localInstant: at,
  );
}

class _Calls {
  final log = <String>[];
  TaskGlassRow row(
    TaskListEntry entry, {
    bool showDate = false,
    bool divider = true,
  }) => TaskGlassRow(
    entry: entry,
    showDate: showDate,
    divider: divider,
    onToggle: () => log.add('toggle'),
    onOpen: () => log.add('open'),
    onDelete: () => log.add('delete'),
    menu: TaskRowMenuActions(
      onEdit: () => log.add('edit'),
      onCyclePriority: () => log.add('priority'),
      onToggleInProgress: () => log.add('progress'),
      onToggleCanceled: () => log.add('cancel'),
      onDelete: () => log.add('menu-delete'),
    ),
  );
}

Widget _app(
  Widget row, {
  Brightness b = Brightness.light,
  double s = 1.0,
  bool reduce = false,
}) => glassTestApp(
  SizedBox(width: 360, child: row),
  brightness: b,
  textScale: s,
  reduceMotion: reduce,
  overlayBackdrop: true,
);

// RTL: the start side is the right edge, so a drag toward start is +x.
const _towardStart = 80.0;

Future<void> _swipeOpen(WidgetTester tester) async {
  await tester.drag(find.byType(TaskGlassRow), const Offset(_towardStart, 0));
  await tester.pumpAndSettle();
}

void main() {
  final at = DateTime.utc(2026, 11, 11, 15);

  testWidgets('anatomy: title, time, priority in danger', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(at: at, priority: 3))));
    expect(find.text('خرید نان'), findsOneWidget);
    expect(find.text('۱۵:۰۰'), findsOneWidget);
    final p = tester.widget<Text>(find.text('اولویت بالا'));
    expect(p.style!.color, AppTheme.light.colors.danger);
    expect(find.byKey(const ValueKey('task-row-t1')), findsOneWidget);
  });

  testWidgets('showDate shows the Jalali day and month', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(
      _app(c.row(_entry(at: DateTime.utc(2026, 11, 5, 9)), showDate: true)),
    );
    expect(find.text('۱۴ آبان'), findsOneWidget);
    expect(find.text('۹:۰۰'), findsNothing);
  });

  testWidgets('a 23:59 instant is date-only: no clock in امروز', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(
      _app(c.row(_entry(at: DateTime.utc(2026, 11, 11, 23, 59)))),
    );
    expect(find.text('۲۳:۵۹'), findsNothing);
    expect(find.text('۱۹ آبان'), findsNothing);
    expect(find.text('خرید نان'), findsOneWidget);
  });

  testWidgets('a 23:59 instant shows the date when showDate is true', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(
      _app(
        c.row(_entry(at: DateTime.utc(2026, 11, 5, 23, 59)), showDate: true),
      ),
    );
    expect(find.text('۱۴ آبان'), findsOneWidget);
    expect(find.text('۲۳:۵۹'), findsNothing);
  });

  testWidgets('canceled: لغوشده first in the subline, title struck', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(
      _app(
        c.row(
          _entry(status: TaskStatus.canceled, at: at, priority: 3),
          showDate: true,
        ),
      ),
    );
    expect(find.text('لغوشده'), findsOneWidget);
    final canceled = tester.widget<Text>(find.text('لغوشده'));
    expect(canceled.style!.color, AppTheme.light.colors.textSecondary);
    final title = tester.widget<Text>(find.text('خرید نان'));
    expect(title.style!.color, AppTheme.light.colors.textTertiary);
    expect(title.style!.decoration, TextDecoration.lineThrough);
    expect(
      tester.getTopLeft(find.text('لغوشده')).dx,
      greaterThan(tester.getTopLeft(find.text('اولویت بالا')).dx),
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('^خرید نان، لغوشده')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('priority labels and tones', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(priority: 2))));
    expect(
      tester.widget<Text>(find.text('اولویت متوسط')).style!.color,
      AppTheme.light.colors.warn,
    );
    await tester.pumpWidget(_app(c.row(_entry(priority: 1))));
    expect(
      tester.widget<Text>(find.text('اولویت پایین')).style!.color,
      AppTheme.light.colors.textSecondary,
    );
  });

  testWidgets('done: line-through in tertiary', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(status: TaskStatus.completed))));
    final style = tester.widget<Text>(find.text('خرید نان')).style!;
    expect(style.decoration, TextDecoration.lineThrough);
    expect(style.color, AppTheme.light.colors.textTertiary);
  });

  testWidgets('check tap calls onToggle once', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.tap(find.byType(RoundCheck));
    await tester.pumpAndSettle();
    expect(c.log, ['toggle']);
  });

  testWidgets('row tap calls onOpen once', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.tap(find.text('خرید نان'));
    await tester.pumpAndSettle();
    expect(c.log, ['open']);
  });

  testWidgets('swipe toward start reveals تکمیل and حذف', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    expect(find.text('تکمیل'), findsNothing);
    await _swipeOpen(tester);
    expect(find.text('تکمیل'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('swipe-complete'))).width,
      58,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('swipe-delete'))).width,
      58,
    );
    expect(c.log, isEmpty);
  });

  testWidgets('action labels are inverse on teal and danger fills', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await _swipeOpen(tester);
    final colors = AppTheme.light.colors;
    expect(
      tester.widget<Text>(find.text('تکمیل')).style!.color,
      colors.background,
    );
    final complete = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('swipe-complete')),
        matching: find.byType(ColoredBox),
      ),
    );
    final delete = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('swipe-delete')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(complete.color, colors.teal);
    expect(delete.color, colors.danger);
  });

  testWidgets('tapping حذف calls onDelete once and closes', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await _swipeOpen(tester);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(c.log, ['delete']);
    expect(find.text('حذف'), findsNothing);
  });

  testWidgets('tapping تکمیل calls onToggle once and closes', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await _swipeOpen(tester);
    await tester.tap(find.text('تکمیل'));
    await tester.pumpAndSettle();
    expect(c.log, ['toggle']);
    expect(find.text('تکمیل'), findsNothing);
  });

  testWidgets('a short drag snaps back closed', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.drag(find.byType(TaskGlassRow), const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(find.text('تکمیل'), findsNothing);
    expect(c.log, isEmpty);
  });

  testWidgets('a drag away from start never opens', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.drag(find.byType(TaskGlassRow), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('تکمیل'), findsNothing);
  });

  testWidgets('a fling never triggers an action, only opens', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.fling(find.byType(TaskGlassRow), const Offset(300, 0), 2000);
    await tester.pumpAndSettle();
    expect(c.log, isEmpty);
    expect(find.text('تکمیل'), findsOneWidget);
  });

  testWidgets('tapping the row while open closes it without opening', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await _swipeOpen(tester);
    await tester.tapAt(
      tester.getTopLeft(find.byType(TaskGlassRow)) + const Offset(300, 20),
    );
    await tester.pumpAndSettle();
    expect(c.log, isEmpty);
    expect(find.text('تکمیل'), findsNothing);
  });

  Future<void> expectMenu(WidgetTester tester) async {
    for (final label in [
      'ویرایش',
      'اولویت',
      'در حال انجام',
      'لغو کار',
      'حذف',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  }

  testWidgets('long-press opens the menu; items call their callbacks', (
    tester,
  ) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    final items = <String, String>{
      'ویرایش': 'edit',
      'اولویت': 'priority',
      'در حال انجام': 'progress',
      'لغو کار': 'cancel',
      'حذف': 'menu-delete',
    };
    for (final item in items.entries) {
      await tester.longPress(find.text('خرید نان'));
      await tester.pumpAndSettle();
      await expectMenu(tester);
      await tester.tap(find.text(item.key));
      await tester.pumpAndSettle();
      expect(c.log.last, item.value);
      expect(find.text('لغو کار'), findsNothing, reason: 'sheet closed');
    }
    expect(c.log.length, items.length);
  });

  testWidgets('secondary click opens the menu', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    await tester.tap(find.text('خرید نان'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await expectMenu(tester);
  });

  testWidgets('menu toggles read the task status', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(status: TaskStatus.inProgress))));
    await tester.longPress(find.text('خرید نان'));
    await tester.pumpAndSettle();
    expect(find.text('برنامه‌ریزی‌شده'), findsOneWidget);
    expect(find.text('در حال انجام'), findsNothing);
    await tester.tap(find.text('ویرایش'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(c.row(_entry(status: TaskStatus.canceled))));
    await tester.longPress(find.text('خرید نان'));
    await tester.pumpAndSettle();
    expect(find.text('بازگردانی'), findsOneWidget);
    expect(find.text('لغو کار'), findsNothing);
  });

  testWidgets('semantics: one node with label, state and custom actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = _Calls();
    await tester.pumpWidget(
      _app(c.row(_entry(at: at, priority: 3, status: TaskStatus.completed))),
    );
    const label = 'خرید نان، ۱۵:۰۰، اولویت بالا';
    expect(find.bySemanticsLabel(label), findsOneWidget);
    expect(find.bySemanticsLabel('خرید نان'), findsNothing);
    expect(find.bySemanticsLabel('۱۵:۰۰'), findsNothing);
    final node = tester.getSemantics(find.bySemanticsLabel(label));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isChecked.name, 'isTrue');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    final actions = data.customSemanticsActionIds!
        .map((id) => CustomSemanticsAction.getAction(id)!.label)
        .toSet();
    expect(actions, {'تکمیل', 'حذف', 'ویرایش'});

    // The custom actions run the callbacks.
    final ids = {
      for (final id in data.customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label: id,
    };
    for (final name in ['تکمیل', 'حذف', 'ویرایش']) {
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.customAction,
        ids[name],
      );
    }
    expect(c.log, ['toggle', 'delete', 'open']);
    handle.dispose();
  });

  testWidgets('no AppGlass inside the row', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(at: at, priority: 2))));
    await _swipeOpen(tester);
    expect(
      find.descendant(
        of: find.byType(TaskGlassRow),
        matching: find.byType(AppGlass),
      ),
      findsNothing,
    );
  });

  testWidgets('targets are at least 44 pt', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry())));
    expect(
      tester.getSize(find.byType(RoundCheck)).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byType(RoundCheck)).width,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byType(TaskGlassRow)).height,
      greaterThanOrEqualTo(48),
    );
    await _swipeOpen(tester);
    for (final k in ['swipe-complete', 'swipe-delete']) {
      final s = tester.getSize(find.byKey(ValueKey(k)));
      expect(s.width, greaterThanOrEqualTo(44));
      expect(s.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('Reduce Motion: the reveal jumps, nothing moves', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry(at: at)), reduce: true));
    await expectNoMovement(
      tester,
      within: find.byType(TaskGlassRow),
      trigger: () async {
        final g = await tester.startGesture(
          tester.getCenter(find.byType(TaskGlassRow)),
        );
        await g.moveBy(const Offset(40, 0));
        await g.moveBy(const Offset(_towardStart, 0));
        await g.up();
      },
    );
    expect(find.text('تکمیل'), findsOneWidget);
    final rest = tester.getTopLeft(
      find.byKey(const ValueKey('swipe-complete')),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('swipe-complete'))),
      rest,
    );
  });

  testWidgets('Reduce Motion: a short release closes at once', (tester) async {
    final c = _Calls();
    await tester.pumpWidget(_app(c.row(_entry()), reduce: true));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(TaskGlassRow)),
    );
    await g.moveBy(const Offset(30, 0));
    await g.moveBy(const Offset(10, 0));
    await g.up();
    await tester.pump();
    expect(find.text('تکمیل'), findsNothing);
  });

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      final c = _Calls();
      await tester.pumpWidget(
        _app(
          c.row(_entry(at: at, priority: 3, title: 'عنوان بلند ' * 8)),
          b: v.brightness,
          s: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
      await _swipeOpen(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('تکمیل'), findsOneWidget);
    });
  }
}
