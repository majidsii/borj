import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/gregorian_recurrence_calendar.dart';
import 'package:borj/core/recurrence/jalali_recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_calendar_adapter.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_exception.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_month_selector.dart';
import 'package:borj/core/recurrence/recurrence_occurrence.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone_resolver.dart';

final class RecurrenceEngine {
  const RecurrenceEngine({
    this.gregorianCalendar = const GregorianRecurrenceCalendar(),
    this.jalaliCalendar = const JalaliRecurrenceCalendar(),
    this.timeZoneResolver = const TimezoneRecurrenceResolver(),
  });

  final RecurrenceCalendarAdapter gregorianCalendar;
  final RecurrenceCalendarAdapter jalaliCalendar;
  final RecurrenceTimeZoneResolver timeZoneResolver;

  List<RecurrenceOccurrence> expand({
    required RecurrenceRule rule,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
    required String floatingTimeZoneId,
    List<RecurrenceException> exceptions = const <RecurrenceException>[],
    int maximumOccurrences = 10000,
  }) {
    _validateUtcRange(rangeStartUtc, rangeEndUtc);
    if (maximumOccurrences < 1) {
      throw const ValidationFailure('حداکثر تعداد رخدادها باید حداقل یک باشد.');
    }

    final adapter = _adapterFor(rule.calendar);
    _validateRule(rule, adapter);

    final timeZoneId = rule.timeZone.resolveTimeZoneId(floatingTimeZoneId);
    final exceptionByKey = _validateExceptions(
      exceptions: exceptions,
      adapter: adapter,
    );
    final latestExceptionLocal = exceptions.isEmpty
        ? null
        : exceptions
              .map((item) => item.originalLocalDateTime)
              .reduce(
                (left, right) => left.compareTo(right) >= 0 ? left : right,
              );

    final output = <RecurrenceOccurrence>[];
    var sequence = 0;

    periodLoop:
    for (final period in _candidatePeriods(rule, adapter)) {
      final cursorResolution = _resolve(
        local: period.cursorLocal,
        adapter: adapter,
        timeZoneId: timeZoneId,
      );
      final periodBeyondRange = !cursorResolution.instantUtc.isBefore(
        rangeEndUtc,
      );
      final periodBeyondUntil =
          rule.end.kind == RecurrenceEndKind.until &&
          cursorResolution.instantUtc.isAfter(rule.end.untilUtc!);
      final periodBeyondExceptions =
          latestExceptionLocal == null ||
          period.cursorLocal.compareTo(latestExceptionLocal) > 0;
      if ((periodBeyondRange || periodBeyondUntil) && periodBeyondExceptions) {
        break;
      }

      for (final originalLocal in period.candidates) {
        if (rule.end.kind == RecurrenceEndKind.afterCount &&
            sequence >= rule.end.count!) {
          break periodLoop;
        }

        final originalResolution = _resolve(
          local: originalLocal,
          adapter: adapter,
          timeZoneId: timeZoneId,
        );

        if (rule.end.kind == RecurrenceEndKind.until &&
            originalResolution.instantUtc.isAfter(rule.end.untilUtc!)) {
          break periodLoop;
        }

        sequence += 1;

        final exception = exceptionByKey[originalLocal.storageKey];
        var effectiveResolution = originalResolution;
        var status = RecurrenceOccurrenceStatus.scheduled;

        if (exception != null) {
          switch (exception.action) {
            case RecurrenceExceptionAction.skip:
              status = RecurrenceOccurrenceStatus.skipped;
              break;
            case RecurrenceExceptionAction.cancel:
              status = RecurrenceOccurrenceStatus.canceled;
              break;
            case RecurrenceExceptionAction.move:
              effectiveResolution = _resolve(
                local: exception.movedToLocalDateTime!,
                adapter: adapter,
                timeZoneId: timeZoneId,
              );
              status = RecurrenceOccurrenceStatus.moved;
              break;
          }
        }

        final instantUtc = effectiveResolution.instantUtc;
        if (instantUtc.isBefore(rangeStartUtc) ||
            !instantUtc.isBefore(rangeEndUtc)) {
          continue;
        }

        if (output.length >= maximumOccurrences) {
          throw StateError(
            'Recurrence expansion exceeded maximumOccurrences '
            '($maximumOccurrences).',
          );
        }

        output.add(
          RecurrenceOccurrence(
            originalLocalDateTime: originalLocal,
            effectiveLocalDateTime: effectiveResolution.effectiveLocal,
            instantUtc: instantUtc,
            timeZoneId: timeZoneId,
            calendar: rule.calendar,
            sequence: sequence,
            status: status,
          ),
        );
      }
    }

    output.sort((left, right) {
      final instantComparison = left.instantUtc.compareTo(right.instantUtc);
      if (instantComparison != 0) {
        return instantComparison;
      }
      return left.originalLocalDateTime.compareTo(right.originalLocalDateTime);
    });
    return List<RecurrenceOccurrence>.unmodifiable(output);
  }

  RecurrenceCalendarAdapter _adapterFor(RecurrenceCalendar calendar) {
    return switch (calendar) {
      RecurrenceCalendar.gregorian => gregorianCalendar,
      RecurrenceCalendar.jalali => jalaliCalendar,
    };
  }

  void _validateUtcRange(DateTime start, DateTime end) {
    if (!start.isUtc || !end.isUtc) {
      throw const ValidationFailure('بازه گسترش تکرار باید به‌صورت UTC باشد.');
    }
    if (!start.isBefore(end)) {
      throw const ValidationFailure(
        'پایان بازه تکرار باید بعد از شروع آن باشد.',
      );
    }
  }

  void _validateRule(RecurrenceRule rule, RecurrenceCalendarAdapter adapter) {
    final anchor = rule.anchorLocalDateTime;
    if (!adapter.isValidDate(
      year: anchor.year,
      month: anchor.month,
      day: anchor.day,
    )) {
      throw const ValidationFailure(
        'تاریخ شروع تکرار در تقویم انتخاب‌شده معتبر نیست.',
      );
    }
  }

  Map<String, RecurrenceException> _validateExceptions({
    required List<RecurrenceException> exceptions,
    required RecurrenceCalendarAdapter adapter,
  }) {
    final byKey = <String, RecurrenceException>{};
    for (final exception in exceptions) {
      final original = exception.originalLocalDateTime;
      if (!adapter.isValidDate(
        year: original.year,
        month: original.month,
        day: original.day,
      )) {
        throw const ValidationFailure('تاریخ اصلی استثنای تکرار معتبر نیست.');
      }
      final moved = exception.movedToLocalDateTime;
      if (moved != null &&
          !adapter.isValidDate(
            year: moved.year,
            month: moved.month,
            day: moved.day,
          )) {
        throw const ValidationFailure('تاریخ جدید استثنای تکرار معتبر نیست.');
      }

      final key = original.storageKey;
      if (byKey.containsKey(key)) {
        throw const ValidationFailure(
          'برای یک رخداد تکراری نمی‌توان چند استثنا ثبت کرد.',
        );
      }
      byKey[key] = exception;
    }
    return byKey;
  }

  _ResolvedOccurrence _resolve({
    required RecurrenceLocalDateTime local,
    required RecurrenceCalendarAdapter adapter,
    required String timeZoneId,
  }) {
    final gregorianLocal = adapter.toGregorianCivil(local);
    final resolution = timeZoneResolver.resolve(
      gregorianLocalDateTime: gregorianLocal,
      timeZoneId: timeZoneId,
    );
    return _ResolvedOccurrence(
      effectiveLocal: adapter.fromGregorianCivil(
        resolution.effectiveGregorianLocalDateTime,
      ),
      instantUtc: resolution.instantUtc,
    );
  }

  Iterable<_CandidatePeriod> _candidatePeriods(
    RecurrenceRule rule,
    RecurrenceCalendarAdapter adapter,
  ) sync* {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        yield* _dailyCandidates(rule, adapter);
        return;
      case RecurrenceFrequency.weekly:
        yield* _weeklyCandidates(rule, adapter);
        return;
      case RecurrenceFrequency.monthly:
        yield* _monthlyCandidates(rule, adapter);
        return;
      case RecurrenceFrequency.yearly:
        yield* _yearlyCandidates(rule, adapter);
        return;
    }
  }

  Iterable<_CandidatePeriod> _dailyCandidates(
    RecurrenceRule rule,
    RecurrenceCalendarAdapter adapter,
  ) sync* {
    var index = 0;
    while (true) {
      final candidate = adapter.addDays(
        rule.anchorLocalDateTime,
        index * rule.interval,
      );
      yield _CandidatePeriod(
        cursorLocal: candidate,
        candidates: <RecurrenceLocalDateTime>[candidate],
      );
      index += 1;
    }
  }

  Iterable<_CandidatePeriod> _weeklyCandidates(
    RecurrenceRule rule,
    RecurrenceCalendarAdapter adapter,
  ) sync* {
    final anchor = rule.anchorLocalDateTime;
    final anchorWeekday = adapter.weekday(anchor);
    final weekStart = adapter.addDays(anchor, -(anchorWeekday - 1));
    final weekdays = rule.weeklyDays.toList()
      ..sort((left, right) => left.isoNumber.compareTo(right.isoNumber));

    var period = 0;
    while (true) {
      final activeWeekStart = adapter.addDays(
        weekStart,
        period * rule.interval * 7,
      );
      final candidates = <RecurrenceLocalDateTime>[];
      for (final weekday in weekdays) {
        final candidate = adapter.addDays(
          activeWeekStart,
          weekday.isoNumber - 1,
        );
        if (candidate.compareTo(anchor) >= 0) {
          candidates.add(candidate);
        }
      }
      candidates.sort();
      yield _CandidatePeriod(
        cursorLocal: activeWeekStart,
        candidates: candidates,
      );
      period += 1;
    }
  }

  Iterable<_CandidatePeriod> _monthlyCandidates(
    RecurrenceRule rule,
    RecurrenceCalendarAdapter adapter,
  ) sync* {
    final anchor = rule.anchorLocalDateTime;
    var period = 0;

    while (true) {
      final yearMonth = adapter.shiftMonth(
        year: anchor.year,
        month: anchor.month,
        delta: period * rule.interval,
      );
      final cursorLocal = RecurrenceLocalDateTime(
        year: yearMonth.year,
        month: yearMonth.month,
        day: 1,
        hour: anchor.hour,
        minute: anchor.minute,
      );
      final daysInMonth = adapter.daysInMonth(
        year: yearMonth.year,
        month: yearMonth.month,
      );
      final candidates = <RecurrenceLocalDateTime>[];
      final seen = <String>{};

      for (final selector in rule.monthlySelectors) {
        final requestedDay =
            selector.kind == RecurrenceMonthSelectorKind.lastDay
            ? daysInMonth
            : selector.day!;
        final day = _resolveDay(
          requestedDay: requestedDay,
          daysInMonth: daysInMonth,
          policy: rule.invalidDatePolicy,
        );
        if (day == null) {
          continue;
        }
        final candidate = RecurrenceLocalDateTime(
          year: yearMonth.year,
          month: yearMonth.month,
          day: day,
          hour: anchor.hour,
          minute: anchor.minute,
        );
        if (candidate.compareTo(anchor) >= 0 &&
            seen.add(candidate.storageKey)) {
          candidates.add(candidate);
        }
      }

      candidates.sort();
      yield _CandidatePeriod(cursorLocal: cursorLocal, candidates: candidates);
      period += 1;
    }
  }

  Iterable<_CandidatePeriod> _yearlyCandidates(
    RecurrenceRule rule,
    RecurrenceCalendarAdapter adapter,
  ) sync* {
    final anchor = rule.anchorLocalDateTime;
    var period = 0;

    while (true) {
      final year = anchor.year + (period * rule.interval);
      final cursorLocal = RecurrenceLocalDateTime(
        year: year,
        month: 1,
        day: 1,
        hour: anchor.hour,
        minute: anchor.minute,
      );
      final candidates = <RecurrenceLocalDateTime>[];
      final seen = <String>{};

      for (final annualDate in rule.annualDates) {
        final daysInMonth = adapter.daysInMonth(
          year: year,
          month: annualDate.month,
        );
        final day = _resolveDay(
          requestedDay: annualDate.day,
          daysInMonth: daysInMonth,
          policy: rule.invalidDatePolicy,
        );
        if (day == null) {
          continue;
        }
        final candidate = RecurrenceLocalDateTime(
          year: year,
          month: annualDate.month,
          day: day,
          hour: anchor.hour,
          minute: anchor.minute,
        );
        if (candidate.compareTo(anchor) >= 0 &&
            seen.add(candidate.storageKey)) {
          candidates.add(candidate);
        }
      }

      candidates.sort();
      yield _CandidatePeriod(cursorLocal: cursorLocal, candidates: candidates);
      period += 1;
    }
  }

  int? _resolveDay({
    required int requestedDay,
    required int daysInMonth,
    required RecurrenceInvalidDatePolicy policy,
  }) {
    if (requestedDay <= daysInMonth) {
      return requestedDay;
    }
    return switch (policy) {
      RecurrenceInvalidDatePolicy.skipPeriod => null,
      RecurrenceInvalidDatePolicy.clampToLastDay => daysInMonth,
    };
  }
}

final class _CandidatePeriod {
  _CandidatePeriod({
    required this.cursorLocal,
    required List<RecurrenceLocalDateTime> candidates,
  }) : candidates = List<RecurrenceLocalDateTime>.unmodifiable(candidates);

  final RecurrenceLocalDateTime cursorLocal;
  final List<RecurrenceLocalDateTime> candidates;
}

final class _ResolvedOccurrence {
  const _ResolvedOccurrence({
    required this.effectiveLocal,
    required this.instantUtc,
  });

  final RecurrenceLocalDateTime effectiveLocal;
  final DateTime instantUtc;
}
