import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_rules_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reminder field enables presets and toggles privacy', (
    tester,
  ) async {
    var items = TaskReminderTrigger.values
        .map(TaskReminderDraft.empty)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: TaskReminderRulesField(
                  dueLocal: DateTime(2026, 8, 5, 12),
                  items: items,
                  onChanged: (value) => setState(() => items = value),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('task-reminder-oneHourBefore')),
    );
    await tester.pump();

    final hour = items.singleWhere(
      (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
    );
    expect(hour.selected, isTrue);
    expect(find.text('1 فعال'), findsOneWidget);

    final privacyFinder = find.bySemanticsLabel('خصوصی کردن یادآور ۱ ساعت قبل');
    final pressable = tester.widget<OriginalPressable>(
      find.ancestor(
        of: privacyFinder,
        matching: find.byType(OriginalPressable),
      ),
    );
    pressable.onPressed!();
    await tester.pump();

    expect(
      items
          .singleWhere(
            (item) => item.trigger == TaskReminderTrigger.oneHourBefore,
          )
          .privacyMode,
      NotificationPrivacyMode.private,
    );
    expect(find.text('خصوصی'), findsOneWidget);
  });

  testWidgets('reminder switches stay disabled without due time', (
    tester,
  ) async {
    final items = TaskReminderTrigger.values
        .map(TaskReminderDraft.empty)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: TaskReminderRulesField(
              dueLocal: null,
              items: items,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final toggle = tester.widget<Switch>(
      find.byKey(const ValueKey<String>('task-reminder-atDue')),
    );
    expect(toggle.onChanged, isNull);
    expect(
      find.text('یادآورها بر اساس زمان سررسید ساخته می‌شوند.'),
      findsOneWidget,
    );
  });
}
