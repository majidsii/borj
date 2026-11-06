import 'package:borj/features/tasks/presentation/task_templates/task_template_draft.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('editor requires template name but allows blank initial title', (
    tester,
  ) async {
    TaskTemplateDraft? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showTaskTemplateEditorDialog(
                  context: context,
                  initialDraft: TaskTemplateDraft.create(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('نام قالب'), findsOneWidget);
    expect(find.text('عنوان اولیه کار'), findsOneWidget);
    expect(find.text('زمان شروع'), findsNothing);
    expect(find.text('زمان سررسید'), findsNothing);

    await tester.tap(find.text('ذخیره قالب'));
    await tester.pump();

    expect(find.text('نام قالب نمی‌تواند خالی باشد.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'نام قالب'),
      'قالب سریع',
    );
    await tester.tap(find.text('ذخیره قالب'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.templateName, 'قالب سریع');
    expect(result!.initialTaskTitle, isEmpty);
  });
}
