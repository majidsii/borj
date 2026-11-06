import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';

enum RecurrenceExceptionAction { skip, cancel, move }

final class RecurrenceException {
  factory RecurrenceException.skip({
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) {
    return RecurrenceException._(
      originalLocalDateTime: originalLocalDateTime,
      action: RecurrenceExceptionAction.skip,
      movedToLocalDateTime: null,
    );
  }

  factory RecurrenceException.cancel({
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) {
    return RecurrenceException._(
      originalLocalDateTime: originalLocalDateTime,
      action: RecurrenceExceptionAction.cancel,
      movedToLocalDateTime: null,
    );
  }

  factory RecurrenceException.move({
    required RecurrenceLocalDateTime originalLocalDateTime,
    required RecurrenceLocalDateTime movedToLocalDateTime,
  }) {
    if (movedToLocalDateTime == originalLocalDateTime) {
      throw const ValidationFailure(
        'زمان جدید رخداد باید با زمان اصلی متفاوت باشد.',
      );
    }
    return RecurrenceException._(
      originalLocalDateTime: originalLocalDateTime,
      action: RecurrenceExceptionAction.move,
      movedToLocalDateTime: movedToLocalDateTime,
    );
  }

  const RecurrenceException._({
    required this.originalLocalDateTime,
    required this.action,
    required this.movedToLocalDateTime,
  });

  final RecurrenceLocalDateTime originalLocalDateTime;
  final RecurrenceExceptionAction action;
  final RecurrenceLocalDateTime? movedToLocalDateTime;
}
