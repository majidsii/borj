import 'package:borj/core/errors/app_failure.dart';

final class RecurrenceLocalDateTime
    implements Comparable<RecurrenceLocalDateTime> {
  const RecurrenceLocalDateTime._({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
  });

  factory RecurrenceLocalDateTime({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
  }) {
    if (year < 1) {
      throw const ValidationFailure('سال محلی تکرار باید عددی مثبت باشد.');
    }
    if (month < 1 || month > 12) {
      throw const ValidationFailure('ماه محلی تکرار باید بین ۱ تا ۱۲ باشد.');
    }
    if (day < 1 || day > 31) {
      throw const ValidationFailure('روز محلی تکرار باید بین ۱ تا ۳۱ باشد.');
    }
    if (hour < 0 || hour > 23) {
      throw const ValidationFailure('ساعت محلی تکرار باید بین ۰ تا ۲۳ باشد.');
    }
    if (minute < 0 || minute > 59) {
      throw const ValidationFailure('دقیقه محلی تکرار باید بین ۰ تا ۵۹ باشد.');
    }

    return RecurrenceLocalDateTime._(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
    );
  }

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  RecurrenceLocalDateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
  }) {
    return RecurrenceLocalDateTime(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  String get storageKey {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}T'
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  int compareTo(RecurrenceLocalDateTime other) {
    final values = <(int, int)>[
      (year, other.year),
      (month, other.month),
      (day, other.day),
      (hour, other.hour),
      (minute, other.minute),
    ];
    for (final (left, right) in values) {
      final comparison = left.compareTo(right);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    return other is RecurrenceLocalDateTime &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(year, month, day, hour, minute);

  @override
  String toString() => storageKey;
}
