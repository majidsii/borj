import 'dart:convert';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_annual_date.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';

final class TaskRecurrenceCodec {
  const TaskRecurrenceCodec();

  String encodeRule(RecurrenceRule rule) {
    return jsonEncode(<String, Object?>{
      'version': 1,
      'frequency': rule.frequency.name,
      'interval': rule.interval,
      'calendar': rule.calendar.name,
      'anchor': rule.anchorLocalDateTime.storageKey,
      'timeZoneMode': rule.timeZone.mode.name,
      'fixedTimeZoneId': rule.timeZone.fixedTimeZoneId,
      'endKind': rule.end.kind.name,
      'untilUtc': rule.end.untilUtc?.toIso8601String(),
      'count': rule.end.count,
      'weeklyDays': rule.weeklyDays
          .map((value) => value.isoNumber)
          .toList(growable: false),
      'monthlySelectors': rule.monthlySelectors
          .map(
            (value) => <String, Object?>{
              'kind': value.kind.name,
              'day': value.day,
            },
          )
          .toList(growable: false),
      'annualDates': rule.annualDates
          .map(
            (value) => <String, Object?>{
              'month': value.month,
              'day': value.day,
            },
          )
          .toList(growable: false),
      'invalidDatePolicy': rule.invalidDatePolicy.name,
    });
  }

  RecurrenceRule decodeRule(String source) {
    final json = _decodeObject(source, 'قانون تکرار');
    final version = json['version'];
    if (version != 1) {
      throw const ValidationFailure('نسخه قانون تکرار پشتیبانی نمی‌شود.');
    }

    final frequency = _enumValue(
      RecurrenceFrequency.values,
      _requiredString(json, 'frequency'),
      'نوع تکرار',
    );
    final interval = _requiredInt(json, 'interval');
    final calendar = _enumValue(
      RecurrenceCalendar.values,
      _requiredString(json, 'calendar'),
      'تقویم تکرار',
    );
    final anchor = decodeLocalDateTime(_requiredString(json, 'anchor'));
    final timeZoneMode = _enumValue(
      RecurrenceTimeZoneMode.values,
      _requiredString(json, 'timeZoneMode'),
      'حالت منطقه زمانی',
    );
    final timeZone = switch (timeZoneMode) {
      RecurrenceTimeZoneMode.floating => const RecurrenceTimeZone.floating(),
      RecurrenceTimeZoneMode.fixed => RecurrenceTimeZone.fixed(
        _requiredString(json, 'fixedTimeZoneId'),
      ),
    };
    final endKind = _enumValue(
      RecurrenceEndKind.values,
      _requiredString(json, 'endKind'),
      'پایان تکرار',
    );
    final end = switch (endKind) {
      RecurrenceEndKind.never => const RecurrenceEnd.never(),
      RecurrenceEndKind.until => RecurrenceEnd.until(
        DateTime.parse(_requiredString(json, 'untilUtc')).toUtc(),
      ),
      RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(
        _requiredInt(json, 'count'),
      ),
    };
    final invalidDatePolicy = _enumValue(
      RecurrenceInvalidDatePolicy.values,
      _requiredString(json, 'invalidDatePolicy'),
      'سیاست تاریخ نامعتبر',
    );

    return switch (frequency) {
      RecurrenceFrequency.daily => RecurrenceRule.daily(
        anchorLocalDateTime: anchor,
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
      ),
      RecurrenceFrequency.weekly => RecurrenceRule.weekly(
        anchorLocalDateTime: anchor,
        weeklyDays: _requiredList(
          json,
          'weeklyDays',
        ).map((value) => RecurrenceWeekday.fromIsoNumber(value as int)).toSet(),
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
      ),
      RecurrenceFrequency.monthly => RecurrenceRule.monthly(
        anchorLocalDateTime: anchor,
        monthlySelectors: _requiredList(json, 'monthlySelectors')
            .map((value) {
              final item = Map<String, Object?>.from(value as Map);
              final kind = _enumValue(
                RecurrenceMonthSelectorKind.values,
                _requiredString(item, 'kind'),
                'انتخاب روز ماه',
              );
              return switch (kind) {
                RecurrenceMonthSelectorKind.lastDay =>
                  const RecurrenceMonthSelector.lastDay(),
                RecurrenceMonthSelectorKind.dayOfMonth =>
                  RecurrenceMonthSelector.dayOfMonth(_requiredInt(item, 'day')),
              };
            })
            .toList(growable: false),
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
        invalidDatePolicy: invalidDatePolicy,
      ),
      RecurrenceFrequency.yearly => RecurrenceRule.yearly(
        anchorLocalDateTime: anchor,
        annualDates: _requiredList(json, 'annualDates')
            .map((value) {
              final item = Map<String, Object?>.from(value as Map);
              return RecurrenceAnnualDate(
                month: _requiredInt(item, 'month'),
                day: _requiredInt(item, 'day'),
              );
            })
            .toList(growable: false),
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
        invalidDatePolicy: invalidDatePolicy,
      ),
    };
  }

  String encodeException(RecurrenceException exception) {
    return jsonEncode(<String, Object?>{
      'version': 1,
      'original': exception.originalLocalDateTime.storageKey,
      'action': exception.action.name,
      'movedTo': exception.movedToLocalDateTime?.storageKey,
    });
  }

  RecurrenceException decodeException(String source) {
    final json = _decodeObject(source, 'استثنای تکرار');
    if (json['version'] != 1) {
      throw const ValidationFailure('نسخه استثنای تکرار پشتیبانی نمی‌شود.');
    }
    final original = decodeLocalDateTime(_requiredString(json, 'original'));
    final action = _enumValue(
      RecurrenceExceptionAction.values,
      _requiredString(json, 'action'),
      'نوع استثنای تکرار',
    );
    return switch (action) {
      RecurrenceExceptionAction.skip => RecurrenceException.skip(
        originalLocalDateTime: original,
      ),
      RecurrenceExceptionAction.cancel => RecurrenceException.cancel(
        originalLocalDateTime: original,
      ),
      RecurrenceExceptionAction.move => RecurrenceException.move(
        originalLocalDateTime: original,
        movedToLocalDateTime: decodeLocalDateTime(
          _requiredString(json, 'movedTo'),
        ),
      ),
    };
  }

  RecurrenceLocalDateTime decodeLocalDateTime(String source) {
    final match = RegExp(
      r'^(\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$',
    ).firstMatch(source.trim());
    if (match == null) {
      throw const ValidationFailure('کلید زمان محلی تکرار نامعتبر است.');
    }
    return RecurrenceLocalDateTime(
      year: int.parse(match.group(1)!),
      month: int.parse(match.group(2)!),
      day: int.parse(match.group(3)!),
      hour: int.parse(match.group(4)!),
      minute: int.parse(match.group(5)!),
    );
  }
}

Map<String, Object?> _decodeObject(String source, String label) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException();
    }
    return Map<String, Object?>.from(decoded);
  } on Object {
    throw ValidationFailure('$label ذخیره‌شده معتبر نیست.');
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ValidationFailure('فیلد $key در داده تکرار نامعتبر است.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw ValidationFailure('فیلد $key در داده تکرار نامعتبر است.');
  }
  return value;
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw ValidationFailure('فیلد $key در داده تکرار نامعتبر است.');
  }
  return List<Object?>.from(value);
}

T _enumValue<T extends Enum>(List<T> values, String name, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw ValidationFailure('$label ذخیره‌شده شناخته نمی‌شود.');
}
