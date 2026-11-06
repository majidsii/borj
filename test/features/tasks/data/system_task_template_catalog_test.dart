import 'package:borj/features/tasks/data/system_task_template_catalog.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const catalog = SystemTaskTemplateCatalog();
  final now = DateTime.utc(2026, 8, 8, 2);

  test('defines the seven approved built-in templates in canonical order', () {
    final templates = catalog.build(nowUtc: now);

    expect(templates, hasLength(7));
    expect(templates.map((item) => item.systemKey), <String?>[
      'meeting',
      'follow_up',
      'deep_work',
      'daily_work',
      'payment_due',
      'call_message',
      'personal_errand',
    ]);
    expect(templates.map((item) => item.templateName), <String>[
      'جلسه',
      'پیگیری',
      'کار عمیق',
      'کار روزانه',
      'موعد پرداخت',
      'تماس / پیام',
      'خرید / کار شخصی',
    ]);
    expect(templates.map((item) => item.displayOrder), <int>[
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    ]);
    expect(
      templates.every((item) => item.kind == TaskTemplateKind.system),
      isTrue,
    );
  });

  test('defines frozen built-in defaults', () {
    final templates = catalog.build(nowUtc: now);
    final byKey = <String, TaskTemplate>{
      for (final item in templates) item.systemKey!: item,
    };

    expect(byKey['meeting']!.initialTaskTitle, 'جلسه با …');
    expect(byKey['meeting']!.priority, 2);
    expect(byKey['meeting']!.estimatedDurationMinutes, 60);
    expect(
      byKey['meeting']!.reminderDefaults.map((item) => item.trigger),
      <TaskReminderTrigger>[TaskReminderTrigger.fifteenMinutesBefore],
    );

    expect(byKey['follow_up']!.initialTaskTitle, 'پیگیری …');
    expect(byKey['deep_work']!.initialTaskTitle, 'کار عمیق روی …');
    expect(byKey['daily_work']!.initialTaskTitle, 'کار روزانه …');
    expect(
      byKey['daily_work']!.recurrenceDefault!.end.kind,
      TaskTemplateRecurrenceEndKind.never,
    );
    expect(byKey['payment_due']!.initialTaskTitle, 'پرداخت …');
    expect(
      byKey['payment_due']!.reminderDefaults.map((item) => item.trigger),
      <TaskReminderTrigger>[
        TaskReminderTrigger.oneDayBefore,
        TaskReminderTrigger.atDue,
      ],
    );
    expect(byKey['call_message']!.initialTaskTitle, 'تماس / پیام با …');
    expect(byKey['personal_errand']!.initialTaskTitle, 'خرید / کار شخصی …');
  });
}
