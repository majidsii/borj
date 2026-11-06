import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_manager_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 8);

  TaskTemplate template({
    required String id,
    required TaskTemplateKind kind,
    required String name,
    required int order,
    bool hidden = false,
    String? systemKey,
  }) {
    return TaskTemplate(
      id: id,
      kind: kind,
      systemKey: systemKey,
      templateName: name,
      initialTaskTitle: '',
      priority: 1,
      hidden: hidden,
      displayOrder: order,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  testWidgets('manager distinguishes system/custom actions', (tester) async {
    var duplicateId = '';
    var hiddenId = '';
    var restoreCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTemplateManagerDialog(
            templates: <TaskTemplate>[
              template(
                id: 's1',
                kind: TaskTemplateKind.system,
                systemKey: 'meeting',
                name: 'جلسه',
                order: 0,
              ),
              template(
                id: 'c1',
                kind: TaskTemplateKind.custom,
                name: 'قالب من',
                order: 0,
              ),
            ],
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) async {},
            onDuplicate: (item) async => duplicateId = item.id,
            onSetHidden: (item, hidden) async => hiddenId = item.id,
            onReorder: (_, _) async {},
            onRestoreSystemDefaults: () async => restoreCalls++,
          ),
        ),
      ),
    );

    expect(find.text('سیستمی'), findsWidgets);
    expect(find.text('شخصی'), findsWidgets);
    expect(find.byTooltip('ویرایش قالب سیستمی'), findsNothing);
    expect(find.byTooltip('حذف قالب سیستمی'), findsNothing);
    expect(find.byTooltip('ویرایش قالب من'), findsOneWidget);
    expect(find.byTooltip('حذف قالب من'), findsOneWidget);

    await tester.tap(find.byTooltip('تکثیر جلسه'));
    await tester.pump();
    expect(duplicateId, 's1');

    await tester.tap(find.byTooltip('مخفی‌کردن جلسه'));
    await tester.pump();
    expect(hiddenId, 's1');

    await tester.tap(find.text('بازگردانی قالب‌های سیستمی'));
    await tester.pump();
    expect(restoreCalls, 1);

    expect(find.byType(ReorderableListView), findsNWidgets(2));
  });
}
