import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_dialog.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Widget testApp(Widget home) {
    return ProviderScope(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(theme: OriginalTheme.light(), home: home),
    );
  }

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> pressGhost(WidgetTester tester, String label) async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is OriginalGhostButton && widget.label == label,
    );
    expect(finder, findsOneWidget);
    final button = tester.widget<OriginalGhostButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await pumpUi(tester);
  }

  testWidgets('create mode accepts template-derived initial draft', (
    tester,
  ) async {
    final initial = TaskDetailsDraft.create(nowLocal: DateTime(2026, 8, 8, 12))
      ..title = 'عنوان از قالب'
      ..description = 'شرح از قالب'
      ..priority = 3
      ..startLocal = null
      ..dueLocal = null;

    TaskDetailsDialogResult? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showTaskDetailsEditorDialog(
                  context: context,
                  mode: TaskDetailsDialogMode.create,
                  initialCreateDraft: initial,
                  nextId: () => 'template-task-id',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await pumpUi(tester);

    final title = tester.widget<TextField>(textFieldWithHint('عنوان کار'));
    final description = tester.widget<TextField>(
      textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
    );

    expect(title.controller!.text, 'عنوان از قالب');
    expect(description.controller!.text, 'شرح از قالب');
    expect(find.text('بالا'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('انصراف'));
    await pumpUi(tester);
    expect(result, isNull);
  });

  testWidgets('edit mode exposes save-as-template without closing dialog', (
    tester,
  ) async {
    TaskDetailsDraft? captured;
    final task = TaskItem(
      id: 'edit-template-source',
      displayNumber: 4,
      title: 'کار قابل قالب',
      description: 'شرح قابل قالب',
      priority: 2,
      status: TaskStatus.inProgress,
      positionInStatus: 1,
      estimatedDurationMinutes: 45,
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 2),
    );

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showTaskDetailsEditorDialog(
                  context: context,
                  mode: TaskDetailsDialogMode.edit,
                  initialTask: task,
                  onSaveAsTemplate: (draft) async {
                    captured = draft;
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await pumpUi(tester);

    await pressGhost(tester, 'ذخیره به‌عنوان قالب');

    expect(captured, isNotNull);
    expect(captured!.title, 'کار قابل قالب');
    expect(captured!.description, 'شرح قابل قالب');
    expect(find.text('ویرایش کار'), findsWidgets);

    await tester.tap(find.text('انصراف'));
    await pumpUi(tester);
  });
}
