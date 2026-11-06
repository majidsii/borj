import 'package:borj/core/errors/app_failure.dart';

enum RecurrenceTimeZoneMode { fixed, floating }

final class RecurrenceTimeZone {
  const RecurrenceTimeZone.floating()
    : mode = RecurrenceTimeZoneMode.floating,
      fixedTimeZoneId = null;

  factory RecurrenceTimeZone.fixed(String timeZoneId) {
    final normalized = timeZoneId.trim();
    if (normalized.isEmpty) {
      throw const ValidationFailure('منطقه زمانی ثابت نمی‌تواند خالی باشد.');
    }
    return RecurrenceTimeZone._(
      mode: RecurrenceTimeZoneMode.fixed,
      fixedTimeZoneId: normalized,
    );
  }

  const RecurrenceTimeZone._({
    required this.mode,
    required this.fixedTimeZoneId,
  });

  final RecurrenceTimeZoneMode mode;
  final String? fixedTimeZoneId;

  String resolveTimeZoneId(String floatingTimeZoneId) {
    if (mode == RecurrenceTimeZoneMode.fixed) {
      return fixedTimeZoneId!;
    }

    final normalized = floatingTimeZoneId.trim();
    if (normalized.isEmpty) {
      throw const ValidationFailure(
        'منطقه زمانی شناور فعلی نمی‌تواند خالی باشد.',
      );
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    return other is RecurrenceTimeZone &&
        other.mode == mode &&
        other.fixedTimeZoneId == fixedTimeZoneId;
  }

  @override
  int get hashCode => Object.hash(mode, fixedTimeZoneId);
}
