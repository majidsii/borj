import 'package:borj/core/errors/app_failure.dart';

enum RecurrenceMonthSelectorKind { dayOfMonth, lastDay }

final class RecurrenceMonthSelector {
  const RecurrenceMonthSelector.lastDay()
    : kind = RecurrenceMonthSelectorKind.lastDay,
      day = null;

  factory RecurrenceMonthSelector.dayOfMonth(int day) {
    if (day < 1 || day > 31) {
      throw const ValidationFailure('روز ماه باید بین ۱ تا ۳۱ باشد.');
    }
    return RecurrenceMonthSelector._(
      kind: RecurrenceMonthSelectorKind.dayOfMonth,
      day: day,
    );
  }

  const RecurrenceMonthSelector._({required this.kind, required this.day});

  final RecurrenceMonthSelectorKind kind;
  final int? day;

  @override
  bool operator ==(Object other) {
    return other is RecurrenceMonthSelector &&
        other.kind == kind &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(kind, day);
}
