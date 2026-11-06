import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_dialog.dart';
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

  testWidgets('editor dialog returns task and canonical reminder rules', (
    tester,
  ) async {
    TaskDetailsDialogResult? result;
    var id = 0;
    final task = TaskItem(
      id: 'task-1',
      displayNumber: 1,
      title: 'کار موجود',
      priority: 1,
      status: TaskStatus.planned,
      positionInStatus: 0,
      dueAtUtc: DateTime.utc(2026, 8, 6, 12),
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 2),
    );
    final existing = TaskReminderRule(
      id: 'existing',
      taskId: task.id,
      trigger: TaskReminderTrigger.oneHourBefore,
      privacyMode: NotificationPrivacyMode.private,
      createdAtUtc: DateTime.utc(2026, 8, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 2),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTaskDetailsEditorDialog(
                    context: context,
                    mode: TaskDetailsDialogMode.edit,
                    initialTask: task,
                    initialReminderRules: <TaskReminderRule>[existing],
                    now: () => DateTime.utc(2026, 8, 4, 12),
                    nextId: () => 'rule-${++id}',
                  );
                },
                child: const Text('باز کردن'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('باز کردن'));
    await tester.pumpAndSettle();

    expect(find.text('یادآورها'), findsOneWidget);
    expect(find.text('1 فعال'), findsOneWidget);

    final atDueToggle = find.byKey(
      const ValueKey<String>('task-reminder-atDue'),
    );
    await tester.ensureVisible(atDueToggle);
    await tester.pump();
    await tester.tap(atDueToggle);
    await tester.pump();

    final save = tester.widget<OriginalPrimaryButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is OriginalPrimaryButton && widget.label == 'ذخیره تغییرات',
      ),
    );
    save.onPressed!();
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.task.id, task.id);
    expect(result!.reminderRules, hasLength(2));
    expect(
      result!.reminderRules
          .singleWhere(
            (rule) => rule.trigger == TaskReminderTrigger.oneHourBefore,
          )
          .id,
      'existing',
    );
    expect(
      result!.reminderRules
          .singleWhere((rule) => rule.trigger == TaskReminderTrigger.atDue)
          .id,
      'rule-1',
    );
  });
}
