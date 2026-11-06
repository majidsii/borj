import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 7);

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

  testWidgets('picker groups active templates and excludes hidden ones', (
    tester,
  ) async {
    TaskTemplate? selected;
    var manageCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTemplatePicker(
            templates: <TaskTemplate>[
              template(
                id: 's1',
                kind: TaskTemplateKind.system,
                systemKey: 'meeting',
                name: 'جلسه',
                order: 0,
              ),
              template(
                id: 's2',
                kind: TaskTemplateKind.system,
                systemKey: 'hidden',
                name: 'مخفی سیستمی',
                order: 1,
                hidden: true,
              ),
              template(
                id: 'c1',
                kind: TaskTemplateKind.custom,
                name: 'شخصی من',
                order: 0,
              ),
              template(
                id: 'c2',
                kind: TaskTemplateKind.custom,
                name: 'مخفی شخصی',
                order: 1,
                hidden: true,
              ),
            ],
            onSelected: (value) => selected = value,
            onManage: () => manageCalls++,
          ),
        ),
      ),
    );

    expect(find.text('قالب‌های سیستمی'), findsOneWidget);
    expect(find.text('قالب‌های شخصی'), findsOneWidget);
    expect(find.text('جلسه'), findsOneWidget);
    expect(find.text('شخصی من'), findsOneWidget);
    expect(find.text('مخفی سیستمی'), findsNothing);
    expect(find.text('مخفی شخصی'), findsNothing);

    await tester.tap(find.text('جلسه'));
    await tester.pump();
    expect(selected?.id, 's1');

    await tester.tap(find.text('مدیریت قالب‌ها'));
    await tester.pump();
    expect(manageCalls, 1);
  });
}
