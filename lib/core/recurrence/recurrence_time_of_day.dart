import 'package:borj/core/errors/app_failure.dart';

final class RecurrenceTimeOfDay {
  const RecurrenceTimeOfDay._({required this.hour, required this.minute});

  factory RecurrenceTimeOfDay({required int hour, required int minute}) {
    if (hour < 0 || hour > 23) {
      throw const ValidationFailure('ساعت تکرار باید بین ۰ تا ۲۳ باشد.');
    }
    if (minute < 0 || minute > 59) {
      throw const ValidationFailure('دقیقه تکرار باید بین ۰ تا ۵۹ باشد.');
    }
    return RecurrenceTimeOfDay._(hour: hour, minute: minute);
  }

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) {
    return other is RecurrenceTimeOfDay &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
