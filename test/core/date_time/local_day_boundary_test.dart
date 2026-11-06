import 'package:borj/core/date_time/local_date.dart';
import 'package:borj/core/date_time/local_day_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDayBoundary', () {
    final boundary = LocalDayBoundary(startHour: 4, startMinute: 30);

    test('maps an instant before the boundary to the previous date', () {
      expect(
        boundary.dateFor(DateTime(2026, 7, 27, 4, 29)),
        LocalDate(year: 2026, month: 7, day: 26),
      );
    });

    test('maps an instant on the boundary to the current date', () {
      expect(
        boundary.dateFor(DateTime(2026, 7, 27, 4, 30)),
        LocalDate(year: 2026, month: 7, day: 27),
      );
    });

    test('returns the next boundary strictly after the instant', () {
      expect(
        boundary.nextBoundaryAfter(DateTime(2026, 7, 27, 4, 29)),
        DateTime(2026, 7, 27, 4, 30),
      );
      expect(
        boundary.nextBoundaryAfter(DateTime(2026, 7, 27, 4, 30)),
        DateTime(2026, 7, 28, 4, 30),
      );
    });

    test('rejects an invalid local start time', () {
      expect(() => LocalDayBoundary(startHour: 24), throwsArgumentError);
      expect(
        () => LocalDayBoundary(startHour: 4, startMinute: 60),
        throwsArgumentError,
      );
    });
  });
}
