import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StableNotificationId', () {
    test('returns the same positive 31-bit id across repeated calls', () {
      final first = StableNotificationId.fromScheduleId('task-1-reminder-0');
      final second = StableNotificationId.fromScheduleId('task-1-reminder-0');

      expect(second, first);
      expect(first, inInclusiveRange(1, 0x7fffffff));
    });

    test('known different schedule ids do not share an id', () {
      final values = <int>{
        StableNotificationId.fromScheduleId('task-1-reminder-0'),
        StableNotificationId.fromScheduleId('task-1-reminder-1'),
        StableNotificationId.fromScheduleId('habit-1-reminder-0'),
        StableNotificationId.fromScheduleId('daily-summary'),
      };

      expect(values, hasLength(4));
    });

    test('rejects a blank schedule id', () {
      expect(
        () => StableNotificationId.fromScheduleId('   '),
        throwsArgumentError,
      );
    });
  });
}
