import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_time_zone_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  const resolver = TimezoneRecurrenceResolver();

  test('resolves ordinary IANA local time to UTC', () {
    final result = resolver.resolve(
      gregorianLocalDateTime: RecurrenceLocalDateTime(
        year: 2026,
        month: 8,
        day: 5,
        hour: 9,
      ),
      timeZoneId: 'Asia/Tehran',
    );

    expect(result.instantUtc, DateTime.utc(2026, 8, 5, 5, 30));
    expect(
      result.effectiveGregorianLocalDateTime.storageKey,
      '2026-08-05T09:00',
    );
  });

  test('DST gap advances to the first valid local minute', () {
    final result = resolver.resolve(
      gregorianLocalDateTime: RecurrenceLocalDateTime(
        year: 2026,
        month: 3,
        day: 8,
        hour: 2,
        minute: 30,
      ),
      timeZoneId: 'America/New_York',
    );

    expect(
      result.effectiveGregorianLocalDateTime.storageKey,
      '2026-03-08T03:00',
    );
    expect(result.instantUtc, DateTime.utc(2026, 3, 8, 7));
  });

  test('DST overlap chooses the first matching instant', () {
    final result = resolver.resolve(
      gregorianLocalDateTime: RecurrenceLocalDateTime(
        year: 2026,
        month: 11,
        day: 1,
        hour: 1,
        minute: 30,
      ),
      timeZoneId: 'America/New_York',
    );

    expect(result.instantUtc, DateTime.utc(2026, 11, 1, 5, 30));
  });

  test('unknown timezone fails explicitly', () {
    expect(
      () => resolver.resolve(
        gregorianLocalDateTime: RecurrenceLocalDateTime(
          year: 2026,
          month: 8,
          day: 5,
          hour: 9,
        ),
        timeZoneId: 'Not/A_Zone',
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
