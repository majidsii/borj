import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_quick_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/borj_test_app.dart';

// 13:30 in Tehran (UTC+3:30) on 2026-11-11.
final DateTime _now = DateTime.utc(2026, 11, 11, 10);

Future<_Handle> _open(WidgetTester tester) async {
  useWindowSize(tester, const Size(800, 1000));
  final container = await pumpBorjTestApp(
    tester,
    overrides: [
      appClockProvider.overrideWithValue(
        FixedAppClock(utcValue: _now, localValue: _now),
      ),
    ],
  );
  final context = tester.element(find.byType(Text).first);
  // Not awaited: the future resolves when the sheet closes.
  unawaited(showTaskQuickEntry(context));
  await tester.pumpAndSettle();
  return _Handle(container, tester);
}

final class _Handle {
  _Handle(this.container, this.tester);
  final ProviderContainer container;
  final WidgetTester tester;
  Future<List<TaskItem>> tasks() async {
    final list = await tester.runAsync(
      () => container.read(taskRepositoryProvider).watchAll().first,
    );
    return list!;
  }
}

bool _submitEnabled(WidgetTester tester) =>
    tester
        .widget<GlassButton>(find.widgetWithText(GlassButton, 'ثبت'))
        .onPressed !=
    null;

void main() {
  testWidgets('submit is disabled while the title is empty', (tester) async {
    await _open(tester);
    expect(find.text('کار جدید'), findsOneWidget);
    expect(_submitEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), 'خرید نان');
    await tester.pump();
    expect(_submitEnabled(tester), isTrue);
  });

  testWidgets('creates a planned task due tomorrow 23:59 Tehran', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.enterText(find.byType(TextField), 'خرید نان');
    await tester.tap(find.text('فردا'));
    await tester.tap(find.text('بالا'));
    await tester.pump();
    await tester.tap(find.widgetWithText(GlassButton, 'ثبت'));
    await tester.pumpAndSettle();

    final tasks = await h.tasks();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'خرید نان');
    expect(tasks.single.priority, 3);
    expect(tasks.single.status, TaskStatus.planned);
    // 2026-11-12 23:59 at UTC+3:30 is 20:29 UTC.
    expect(tasks.single.dueAtUtc, DateTime.utc(2026, 11, 12, 20, 29));
    expect(find.text('کار جدید'), findsNothing);
    expect(find.text('کار اضافه شد'), findsOneWidget);
  });

  testWidgets('today chip and the default no-date chip', (tester) async {
    final h = await _open(tester);
    await tester.enterText(find.byType(TextField), 'الف');
    await tester.tap(find.text('امروز'));
    await tester.pump();
    await tester.tap(find.widgetWithText(GlassButton, 'ثبت'));
    await tester.pumpAndSettle();
    expect(
      (await h.tasks()).single.dueAtUtc,
      DateTime.utc(2026, 11, 11, 20, 29),
    );
  });

  testWidgets('undo of the toast deletes the new task', (tester) async {
    final h = await _open(tester);
    await tester.enterText(find.byType(TextField), 'خرید نان');
    await tester.pump();
    await tester.tap(find.widgetWithText(GlassButton, 'ثبت'));
    await tester.pumpAndSettle();
    expect(await h.tasks(), hasLength(1));

    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect(await h.tasks(), isEmpty);
  });

  testWidgets('Enter in the field submits', (tester) async {
    final h = await _open(tester);
    await tester.enterText(find.byType(TextField), 'خرید نان');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final tasks = await h.tasks();
    expect(tasks.single.title, 'خرید نان');
    expect(tasks.single.priority, 0);
    expect(tasks.single.dueAtUtc, isNull);
  });

  testWidgets('details opens the legacy dialog prefilled', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'خرید نان');
    await tester.tap(find.text('بالا'));
    await tester.pump();
    await tester.tap(find.text('ویرایش جزئیات'));
    await tester.pumpAndSettle();
    expect(find.text('کار جدید'), findsNothing);
    expect(find.text('خرید نان'), findsOneWidget);
    expect(find.text('اولویت'), findsWidgets);
  });
}
