import 'package:borj/core/errors/app_failure.dart';

enum RecurrenceEndKind { never, until, afterCount }

final class RecurrenceEnd {
  const RecurrenceEnd.never()
    : kind = RecurrenceEndKind.never,
      untilUtc = null,
      count = null;

  factory RecurrenceEnd.until(DateTime untilUtc) {
    if (!untilUtc.isUtc) {
      throw const ValidationFailure('زمان پایان تکرار باید به‌صورت UTC باشد.');
    }
    return RecurrenceEnd._(
      kind: RecurrenceEndKind.until,
      untilUtc: untilUtc,
      count: null,
    );
  }

  factory RecurrenceEnd.afterCount(int count) {
    if (count < 1) {
      throw const ValidationFailure('تعداد رخدادهای تکرار باید حداقل یک باشد.');
    }
    return RecurrenceEnd._(
      kind: RecurrenceEndKind.afterCount,
      untilUtc: null,
      count: count,
    );
  }

  const RecurrenceEnd._({
    required this.kind,
    required this.untilUtc,
    required this.count,
  });

  final RecurrenceEndKind kind;
  final DateTime? untilUtc;
  final int? count;

  @override
  bool operator ==(Object other) {
    return other is RecurrenceEnd &&
        other.kind == kind &&
        other.untilUtc == untilUtc &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(kind, untilUtc, count);
}
