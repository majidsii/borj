import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = openTestDatabase();
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 780, child: TasksPanel()),
          ),
        ),
      ),
    );
  }

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  testWidgets('adds a numbered task with the selected priority chip', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('اولویت'));
    await tester.pumpAndSettle();
    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'تکمیل گزارش ماهانه',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    final taskRow = find.ancestor(
      of: find.text('تکمیل گزارش ماهانه'),
      matching: find.byType(OriginalFieldSurface),
    );

    expect(find.text('تکمیل گزارش ماهانه'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('task-number-1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('task-number-1')),
        matching: find.text('۱'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: taskRow.first, matching: find.text('پایین')),
      findsOneWidget,
    );
    expect(find.text('۱ کار باقی مانده'), findsOneWidget);
    expect(find.text('۱ فعال · ۰ انجام‌شده'), findsOneWidget);
    expect(find.bySemanticsLabel('ویرایش کار'), findsOneWidget);
    expect(find.bySemanticsLabel('حذف کار'), findsOneWidget);
  });

  testWidgets('completes and edits a task with the original row controls', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'نسخه اولیه',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('ویرایش کار'));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldWithHint('ویرایش کار'), 'نسخه ویرایش‌شده');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('نسخه ویرایش‌شده'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('علامت به عنوان انجام‌شده'));
    await tester.pumpAndSettle();

    expect(find.text('همه کارها انجام شد 🎉'), findsOneWidget);
    expect(find.text('۰ فعال · ۱ انجام‌شده'), findsOneWidget);
  });

  testWidgets('deletes a task through the original delete action', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'کار قابل حذف',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('حذف کار'));
    await tester.pumpAndSettle();

    expect(find.text('کار قابل حذف'), findsNothing);
    expect(find.text('هنوز کاری اضافه نکرده‌اید'), findsOneWidget);
  });

  testWidgets('current panel excludes canceled from rows counts and progress', (
    tester,
  ) async {
    final repository = container.read(taskRepositoryProvider);
    final now = DateTime.utc(2026, 7, 26, 8);

    await repository.create(
      TaskItem(
        id: 'planned',
        displayNumber: 1,
        title: 'برنامه واقعی',
        priority: 3,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.create(
      TaskItem(
        id: 'working',
        displayNumber: 2,
        title: 'اجرای واقعی',
        priority: 0,
        status: TaskStatus.inProgress,
        positionInStatus: 0,
        createdAtUtc: now.add(const Duration(minutes: 1)),
        updatedAtUtc: now.add(const Duration(minutes: 1)),
      ),
    );
    await repository.create(
      TaskItem(
        id: 'done',
        displayNumber: 3,
        title: 'پایان واقعی',
        priority: 0,
        status: TaskStatus.completed,
        positionInStatus: 0,
        createdAtUtc: now.add(const Duration(minutes: 2)),
        updatedAtUtc: now.add(const Duration(minutes: 2)),
        completedAtUtc: now.add(const Duration(minutes: 2)),
      ),
    );
    await repository.create(
      TaskItem(
        id: 'canceled',
        displayNumber: 4,
        title: 'لغو واقعی و مخفی',
        priority: 3,
        status: TaskStatus.canceled,
        positionInStatus: 0,
        createdAtUtc: now.add(const Duration(minutes: 3)),
        updatedAtUtc: now.add(const Duration(minutes: 3)),
        canceledAtUtc: now.add(const Duration(minutes: 3)),
      ),
    );

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('برنامه واقعی'), findsOneWidget);
    expect(find.text('اجرای واقعی'), findsOneWidget);
    expect(find.text('پایان واقعی'), findsOneWidget);
    expect(find.text('لغو واقعی و مخفی'), findsNothing);
    expect(find.text('۲ فعال · ۱ انجام‌شده'), findsOneWidget);
    expect(find.text('۲ کار باقی مانده · ۱ با اولویت بالا'), findsOneWidget);
  });
}
