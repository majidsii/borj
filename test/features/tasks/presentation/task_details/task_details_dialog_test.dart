// Task 2.2 Heavy UI RED
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Finder textFieldInsideSemantics(String label) {
    return find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byType(TextField),
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> pressOriginal(WidgetTester tester, Finder finder) async {
    final direct = tester
        .widgetList<Widget>(finder)
        .whereType<OriginalPressable>()
        .toList(growable: false);

    OriginalPressable pressable;
    if (direct.length == 1) {
      pressable = direct.single;
    } else {
      final ancestor = find.ancestor(
        of: finder,
        matching: find.byType(OriginalPressable),
      );
      expect(ancestor, findsOneWidget);
      pressable = tester.widget<OriginalPressable>(ancestor);
    }

    expect(pressable.onPressed, isNotNull);
    pressable.onPressed!();
    await pumpUi(tester);
  }

  Future<void> pressBySemantics(WidgetTester tester, String label) {
    return pressOriginal(tester, find.bySemanticsLabel(label));
  }

  Future<void> pressPrimaryButton(WidgetTester tester, String label) async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is OriginalPrimaryButton && widget.label == label,
    );
    expect(finder, findsOneWidget);
    final button = tester.widget<OriginalPrimaryButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await pumpUi(tester);
  }

  Widget launcher({
    required TaskDetailsDialogMode mode,
    required ValueChanged<TaskItem?> onResult,
    TaskItem? initialTask,
    DateTime Function()? now,
    String Function()? nextId,
    double width = 900,
  }) {
    return ProviderScope(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: width,
              child: Builder(
                builder: (context) {
                  return Center(
                    child: TextButton(
                      onPressed: () async {
                        final result = await showTaskDetailsDialog(
                          context: context,
                          mode: mode,
                          initialTask: initialTask,
                          now: now,
                          nextId: nextId,
                        );
                        onResult(result);
                      },
                      child: const Text('باز کردن فرم'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('create mode renders one complete shared task form', (
    tester,
  ) async {
    await tester.pumpWidget(
      launcher(mode: TaskDetailsDialogMode.create, onResult: (_) {}),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    expect(find.text('افزودن کار با جزئیات'), findsOneWidget);
    expect(find.text('عنوان'), findsOneWidget);
    expect(find.text('اولویت'), findsOneWidget);
    expect(find.text('توضیحات'), findsOneWidget);
    expect(find.text('زمان شروع'), findsOneWidget);
    expect(find.text('زمان سررسید'), findsOneWidget);
    expect(find.text('مدت تخمینی'), findsOneWidget);
    expect(find.bySemanticsLabel('بستن فرم کار'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('blank title stays open and renders inline validation', (
    tester,
  ) async {
    TaskItem? result;

    await tester.pumpWidget(
      launcher(
        mode: TaskDetailsDialogMode.create,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    await pressPrimaryButton(tester, 'افزودن کار');

    expect(find.text('عنوان کار نمی‌تواند خالی باشد.'), findsOneWidget);
    expect(find.text('افزودن کار با جزئیات'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('create save returns one canonical task and blocks duplicates', (
    tester,
  ) async {
    TaskItem? result;
    var idCalls = 0;
    final savedAt = DateTime.utc(2026, 8, 4, 12);

    await tester.pumpWidget(
      launcher(
        mode: TaskDetailsDialogMode.create,
        now: () => savedAt,
        nextId: () {
          idCalls += 1;
          return 'dialog-task';
        },
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    await tester.enterText(textFieldWithHint('عنوان کار'), '  کار کامل  ');
    await tester.enterText(
      textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      '  شرح کامل  ',
    );
    await tester.tap(find.text('بالا'));
    await tester.enterText(textFieldInsideSemantics('ساعت مدت تخمینی'), '1');
    await tester.enterText(textFieldInsideSemantics('دقیقه مدت تخمینی'), '30');

    final saveFinder = find.byWidgetPredicate(
      (widget) =>
          widget is OriginalPrimaryButton && widget.label == 'افزودن کار',
    );
    final saveButton = tester.widget<OriginalPrimaryButton>(saveFinder);
    saveButton.onPressed!();
    saveButton.onPressed!();
    await tester.pumpAndSettle();

    expect(idCalls, 1);
    expect(result, isNotNull);
    expect(result!.id, 'dialog-task');
    expect(result!.displayNumber, 1);
    expect(result!.title, 'کار کامل');
    expect(result!.description, 'شرح کامل');
    expect(result!.priority, 3);
    expect(result!.status, TaskStatus.planned);
    expect(result!.positionInStatus, 0);
    expect(result!.estimatedDurationMinutes, 90);
    expect(result!.createdAtUtc, savedAt);
    expect(result!.updatedAtUtc, savedAt);
  });

  testWidgets(
    'edit mode prepopulates and preserves immutable workflow fields',
    (tester) async {
      TaskItem? result;
      final startLocal = Jalali(
        1405,
        5,
        10,
      ).toDateTime().copyWith(hour: 9, minute: 15);
      final dueLocal = startLocal.copyWith(hour: 12, minute: 30);
      final existing = TaskItem(
        id: 'existing',
        displayNumber: 42,
        title: 'عنوان موجود',
        description: 'شرح موجود',
        priority: 2,
        status: TaskStatus.inProgress,
        positionInStatus: 4,
        startAtUtc: startLocal.toUtc(),
        dueAtUtc: dueLocal.toUtc(),
        estimatedDurationMinutes: 195,
        createdAtUtc: DateTime.utc(2026, 8, 1, 8),
        updatedAtUtc: DateTime.utc(2026, 8, 2, 9),
      );
      final savedAt = DateTime.utc(2026, 8, 4, 13);

      await tester.pumpWidget(
        launcher(
          mode: TaskDetailsDialogMode.edit,
          initialTask: existing,
          now: () => savedAt,
          onResult: (value) => result = value,
        ),
      );
      await tester.tap(find.text('باز کردن فرم'));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(
        textFieldWithHint('ویرایش کار'),
      );
      final descriptionField = tester.widget<TextField>(
        textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      );
      expect(titleField.controller!.text, 'عنوان موجود');
      expect(descriptionField.controller!.text, 'شرح موجود');
      expect(find.text('متوسط'), findsOneWidget);

      await tester.enterText(textFieldWithHint('ویرایش کار'), 'عنوان تازه');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.id, existing.id);
      expect(result!.displayNumber, existing.displayNumber);
      expect(result!.createdAtUtc, existing.createdAtUtc);
      expect(result!.status, existing.status);
      expect(result!.positionInStatus, existing.positionInStatus);
      expect(result!.title, 'عنوان تازه');
      expect(result!.description, existing.description);
      expect(result!.startAtUtc, existing.startAtUtc);
      expect(result!.dueAtUtc, existing.dueAtUtc);
      expect(result!.estimatedDurationMinutes, 195);
      expect(result!.updatedAtUtc, savedAt);
    },
  );

  testWidgets('clear actions remove every optional planning value', (
    tester,
  ) async {
    TaskItem? result;
    final startLocal = Jalali(1405, 5, 10).toDateTime().copyWith(hour: 9);
    final existing = TaskItem(
      id: 'clear',
      displayNumber: 7,
      title: 'کار',
      description: 'شرح',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 1,
      startAtUtc: startLocal.toUtc(),
      dueAtUtc: startLocal.copyWith(hour: 11).toUtc(),
      estimatedDurationMinutes: 120,
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 1),
    );

    await tester.pumpWidget(
      launcher(
        mode: TaskDetailsDialogMode.edit,
        initialTask: existing,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    await tester.enterText(
      textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      '',
    );
    await pressBySemantics(tester, 'پاک کردن زمان شروع');
    await pressBySemantics(tester, 'پاک کردن زمان سررسید');
    await pressBySemantics(tester, 'پاک کردن مدت تخمینی');
    await pressPrimaryButton(tester, 'ذخیره تغییرات');

    expect(result, isNotNull);
    expect(result!.description, isNull);
    expect(result!.startAtUtc, isNull);
    expect(result!.dueAtUtc, isNull);
    expect(result!.estimatedDurationMinutes, isNull);
  });

  testWidgets('due-before-start and duration errors remain inline', (
    tester,
  ) async {
    TaskItem? result;
    final startLocal = Jalali(1405, 5, 10).toDateTime().copyWith(hour: 9);
    final existing = TaskItem(
      id: 'invalid-edit',
      displayNumber: 8,
      title: 'کار',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 0,
      startAtUtc: startLocal.toUtc(),
      dueAtUtc: Jalali(1405, 5, 11).toDateTime().copyWith(hour: 9).toUtc(),
      estimatedDurationMinutes: 60,
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 1),
    );

    await tester.pumpWidget(
      launcher(
        mode: TaskDetailsDialogMode.edit,
        initialTask: existing,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    await pressBySemantics(tester, 'انتخاب تاریخ سررسید');
    await pressOriginal(
      tester,
      find.byKey(const ValueKey<String>('task-jalali-day-9')),
    );

    await tester.enterText(textFieldInsideSemantics('دقیقه مدت تخمینی'), '75');
    await pressPrimaryButton(tester, 'ذخیره تغییرات');

    expect(
      find.text('زمان سررسید نمی‌تواند قبل از زمان شروع باشد.'),
      findsOneWidget,
    );
    expect(
      find.text('دقیقه مدت تخمینی باید بین ۰ تا ۵۹ باشد.'),
      findsOneWidget,
    );
    expect(result, isNull);
  });

  testWidgets('narrow layout is near full screen without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      launcher(
        width: 390,
        mode: TaskDetailsDialogMode.create,
        onResult: (_) {},
      ),
    );
    await tester.tap(find.text('باز کردن فرم'));
    await tester.pumpAndSettle();

    expect(find.text('افزودن کار با جزئیات'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
  });
}
