import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/data/task_template_codec.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = TaskTemplateCodec();

  test('round-trips reminder defaults in stable order', () {
    const source = <TaskTemplateReminderDefault>[
      TaskTemplateReminderDefault(
        trigger: TaskReminderTrigger.oneDayBefore,
        privacyMode: NotificationPrivacyMode.private,
      ),
      TaskTemplateReminderDefault(
        trigger: TaskReminderTrigger.atDue,
        privacyMode: NotificationPrivacyMode.full,
      ),
    ];

    final decoded = codec.decodeReminderDefaults(
      codec.encodeReminderDefaults(source),
    );

    expect(decoded, source);
  });

  test('rejects unsupported reminder payload versions', () {
    expect(
      () => codec.decodeReminderDefaults('{"version":99,"items":[]}'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('round-trips anchor-free daily recurrence with relative end', () {
    final source = TaskTemplateRecurrence(
      frequency: RecurrenceFrequency.daily,
      interval: 2,
      calendar: RecurrenceCalendar.gregorian,
      timeZone: const RecurrenceTimeZone.floating(),
      weeklyDays: const <RecurrenceWeekday>{},
      monthlySelectors: const [],
      annualDates: const [],
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      end: TaskTemplateRecurrenceEnd.daysAfterAnchor(30),
    );

    final decoded = codec.decodeRecurrenceDefault(
      codec.encodeRecurrenceDefault(source),
    );

    expect(decoded, isNotNull);
    expect(decoded!.frequency, RecurrenceFrequency.daily);
    expect(decoded.interval, 2);
    expect(decoded.end.kind, TaskTemplateRecurrenceEndKind.daysAfterAnchor);
    expect(decoded.end.days, 30);
  });

  test('stores null recurrence as null', () {
    expect(codec.encodeRecurrenceDefault(null), isNull);
    expect(codec.decodeRecurrenceDefault(null), isNull);
  });

  test('rejects unsupported recurrence payload versions', () {
    expect(
      () => codec.decodeRecurrenceDefault('{"version":99}'),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
