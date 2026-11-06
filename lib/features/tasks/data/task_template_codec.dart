import 'dart:convert';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';

final class TaskTemplateCodec {
  const TaskTemplateCodec();

  String encodeReminderDefaults(List<TaskTemplateReminderDefault> reminders) {
    return jsonEncode(<String, Object?>{
      'version': 1,
      'items': reminders
          .map(
            (item) => <String, Object?>{
              'trigger': item.trigger.name,
              'privacyMode': item.privacyMode.name,
            },
          )
          .toList(growable: false),
    });
  }

  List<TaskTemplateReminderDefault> decodeReminderDefaults(String source) {
    final json = _decodeObject(source, 'یادآورهای قالب');
    _requireVersion(json, 'یادآورهای قالب');

    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const ValidationFailure('ساختار یادآورهای قالب نامعتبر است.');
    }

    return List<TaskTemplateReminderDefault>.unmodifiable(
      rawItems.map((raw) {
        if (raw is! Map) {
          throw const ValidationFailure('ساختار یادآور قالب نامعتبر است.');
        }
        final item = Map<String, Object?>.from(raw);
        return TaskTemplateReminderDefault(
          trigger: _enumByName(
            TaskReminderTrigger.values,
            _requiredString(item, 'trigger'),
            'نوع یادآور قالب',
          ),
          privacyMode: _enumByName(
            NotificationPrivacyMode.values,
            _requiredString(item, 'privacyMode'),
            'حریم خصوصی یادآور قالب',
          ),
        );
      }),
    );
  }

  String? encodeRecurrenceDefault(TaskTemplateRecurrence? recurrence) {
    if (recurrence == null) return null;

    return jsonEncode(<String, Object?>{
      'version': 1,
      'frequency': recurrence.frequency.name,
      'interval': recurrence.interval,
      'calendar': recurrence.calendar.name,
      'timeZoneMode': recurrence.timeZone.mode.name,
      'fixedTimeZoneId': recurrence.timeZone.fixedTimeZoneId,
      'endKind': recurrence.end.kind.name,
      'count': recurrence.end.count,
      'days': recurrence.end.days,
      'weeklyDays': recurrence.weeklyDays
          .map((value) => value.isoNumber)
          .toList(growable: false),
      'monthlySelectors': recurrence.monthlySelectors
          .map(
            (value) => <String, Object?>{
              'kind': value.kind.name,
              'day': value.day,
            },
          )
          .toList(growable: false),
      'annualDates': recurrence.annualDates
          .map(
            (value) => <String, Object?>{
              'month': value.month,
              'day': value.day,
            },
          )
          .toList(growable: false),
      'invalidDatePolicy': recurrence.invalidDatePolicy.name,
    });
  }

  TaskTemplateRecurrence? decodeRecurrenceDefault(String? source) {
    if (source == null) return null;

    final json = _decodeObject(source, 'تکرار قالب');
    _requireVersion(json, 'تکرار قالب');

    final frequency = _enumByName(
      RecurrenceFrequency.values,
      _requiredString(json, 'frequency'),
      'نوع تکرار قالب',
    );
    final calendar = _enumByName(
      RecurrenceCalendar.values,
      _requiredString(json, 'calendar'),
      'تقویم تکرار قالب',
    );
    final timeZoneMode = _enumByName(
      RecurrenceTimeZoneMode.values,
      _requiredString(json, 'timeZoneMode'),
      'حالت منطقه زمانی قالب',
    );
    final timeZone = switch (timeZoneMode) {
      RecurrenceTimeZoneMode.floating => const RecurrenceTimeZone.floating(),
      RecurrenceTimeZoneMode.fixed => RecurrenceTimeZone.fixed(
        _requiredString(json, 'fixedTimeZoneId'),
      ),
    };

    final endKind = _enumByName(
      TaskTemplateRecurrenceEndKind.values,
      _requiredString(json, 'endKind'),
      'پایان تکرار قالب',
    );
    final end = switch (endKind) {
      TaskTemplateRecurrenceEndKind.never =>
        const TaskTemplateRecurrenceEnd.never(),
      TaskTemplateRecurrenceEndKind.afterCount =>
        TaskTemplateRecurrenceEnd.afterCount(_requiredInt(json, 'count')),
      TaskTemplateRecurrenceEndKind.daysAfterAnchor =>
        TaskTemplateRecurrenceEnd.daysAfterAnchor(_requiredInt(json, 'days')),
    };

    final weeklyDays = _requiredList(json, 'weeklyDays').map((value) {
      if (value is! int) {
        throw const ValidationFailure('روز هفتگی قالب نامعتبر است.');
      }
      return RecurrenceWeekday.fromIsoNumber(value);
    }).toSet();

    final monthlySelectors = _requiredList(json, 'monthlySelectors')
        .map((raw) {
          if (raw is! Map) {
            throw const ValidationFailure('انتخاب ماهانه قالب نامعتبر است.');
          }
          final item = Map<String, Object?>.from(raw);
          final kind = _enumByName(
            RecurrenceMonthSelectorKind.values,
            _requiredString(item, 'kind'),
            'انتخاب روز ماه قالب',
          );
          return switch (kind) {
            RecurrenceMonthSelectorKind.lastDay =>
              const RecurrenceMonthSelector.lastDay(),
            RecurrenceMonthSelectorKind.dayOfMonth =>
              RecurrenceMonthSelector.dayOfMonth(_requiredInt(item, 'day')),
          };
        })
        .toList(growable: false);

    final annualDates = _requiredList(json, 'annualDates')
        .map((raw) {
          if (raw is! Map) {
            throw const ValidationFailure('تاریخ سالانه قالب نامعتبر است.');
          }
          final item = Map<String, Object?>.from(raw);
          return RecurrenceAnnualDate(
            month: _requiredInt(item, 'month'),
            day: _requiredInt(item, 'day'),
          );
        })
        .toList(growable: false);

    return TaskTemplateRecurrence(
      frequency: frequency,
      interval: _requiredInt(json, 'interval'),
      calendar: calendar,
      timeZone: timeZone,
      weeklyDays: weeklyDays,
      monthlySelectors: monthlySelectors,
      annualDates: annualDates,
      invalidDatePolicy: _enumByName(
        RecurrenceInvalidDatePolicy.values,
        _requiredString(json, 'invalidDatePolicy'),
        'سیاست تاریخ نامعتبر قالب',
      ),
      end: end,
    );
  }

  Map<String, Object?> _decodeObject(String source, String label) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw ValidationFailure('$label نامعتبر است.');
      }
      return Map<String, Object?>.from(decoded);
    } on ValidationFailure {
      rethrow;
    } on Object {
      throw ValidationFailure('$label نامعتبر است.');
    }
  }

  void _requireVersion(Map<String, Object?> json, String label) {
    if (json['version'] != 1) {
      throw ValidationFailure('نسخه ذخیره‌سازی $label پشتیبانی نمی‌شود.');
    }
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw ValidationFailure('فیلد $key نامعتبر است.');
    }
    return value;
  }

  int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw ValidationFailure('فیلد $key نامعتبر است.');
    }
    return value;
  }

  List<Object?> _requiredList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw ValidationFailure('فیلد $key نامعتبر است.');
    }
    return List<Object?>.from(value);
  }

  T _enumByName<T extends Enum>(List<T> values, String name, String label) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ValidationFailure('$label نامعتبر است.');
  }
}
