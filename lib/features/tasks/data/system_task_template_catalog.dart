import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';

final class SystemTaskTemplateCatalog {
  const SystemTaskTemplateCatalog();

  List<TaskTemplate> build({required DateTime nowUtc}) {
    return <TaskTemplate>[
      _system(
        key: 'meeting',
        name: 'جلسه',
        title: 'جلسه با …',
        priority: 2,
        durationMinutes: 60,
        order: 0,
        nowUtc: nowUtc,
        reminders: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.fifteenMinutesBefore,
            privacyMode: NotificationPrivacyMode.full,
          ),
        ],
      ),
      _system(
        key: 'follow_up',
        name: 'پیگیری',
        title: 'پیگیری …',
        priority: 2,
        durationMinutes: 20,
        order: 1,
        nowUtc: nowUtc,
        reminders: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.atDue,
            privacyMode: NotificationPrivacyMode.full,
          ),
        ],
      ),
      _system(
        key: 'deep_work',
        name: 'کار عمیق',
        title: 'کار عمیق روی …',
        priority: 3,
        durationMinutes: 120,
        order: 2,
        nowUtc: nowUtc,
      ),
      _system(
        key: 'daily_work',
        name: 'کار روزانه',
        title: 'کار روزانه …',
        priority: 1,
        durationMinutes: 30,
        order: 3,
        nowUtc: nowUtc,
        recurrence: TaskTemplateRecurrence(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          calendar: RecurrenceCalendar.jalali,
          timeZone: const RecurrenceTimeZone.floating(),
          weeklyDays: const <RecurrenceWeekday>{},
          monthlySelectors: const [],
          annualDates: const [],
          invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
          end: const TaskTemplateRecurrenceEnd.never(),
        ),
      ),
      _system(
        key: 'payment_due',
        name: 'موعد پرداخت',
        title: 'پرداخت …',
        priority: 3,
        durationMinutes: 10,
        order: 4,
        nowUtc: nowUtc,
        reminders: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.oneDayBefore,
            privacyMode: NotificationPrivacyMode.full,
          ),
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.atDue,
            privacyMode: NotificationPrivacyMode.full,
          ),
        ],
      ),
      _system(
        key: 'call_message',
        name: 'تماس / پیام',
        title: 'تماس / پیام با …',
        priority: 1,
        durationMinutes: 15,
        order: 5,
        nowUtc: nowUtc,
        reminders: const <TaskTemplateReminderDefault>[
          TaskTemplateReminderDefault(
            trigger: TaskReminderTrigger.fifteenMinutesBefore,
            privacyMode: NotificationPrivacyMode.full,
          ),
        ],
      ),
      _system(
        key: 'personal_errand',
        name: 'خرید / کار شخصی',
        title: 'خرید / کار شخصی …',
        priority: 0,
        durationMinutes: 30,
        order: 6,
        nowUtc: nowUtc,
      ),
    ];
  }

  TaskTemplate _system({
    required String key,
    required String name,
    required String title,
    required int priority,
    required int durationMinutes,
    required int order,
    required DateTime nowUtc,
    List<TaskTemplateReminderDefault> reminders = const [],
    TaskTemplateRecurrence? recurrence,
  }) {
    return TaskTemplate(
      id: 'system-template-$key',
      kind: TaskTemplateKind.system,
      systemKey: key,
      templateName: name,
      initialTaskTitle: title,
      priority: priority,
      estimatedDurationMinutes: durationMinutes,
      reminderDefaults: reminders,
      recurrenceDefault: recurrence,
      hidden: false,
      displayOrder: order,
      createdAtUtc: nowUtc,
      updatedAtUtc: nowUtc,
    );
  }
}
