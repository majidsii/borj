import 'package:borj/core/errors/app_failure.dart';

final class RecurrenceAnnualDate {
  factory RecurrenceAnnualDate({required int month, required int day}) {
    if (month < 1 || month > 12) {
      throw const ValidationFailure('ماه سالانه باید بین ۱ تا ۱۲ باشد.');
    }
    if (day < 1 || day > 31) {
      throw const ValidationFailure('روز سالانه باید بین ۱ تا ۳۱ باشد.');
    }
    return RecurrenceAnnualDate._(month: month, day: day);
  }

  const RecurrenceAnnualDate._({required this.month, required this.day});

  final int month;
  final int day;

  @override
  bool operator ==(Object other) {
    return other is RecurrenceAnnualDate &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(month, day);
}
