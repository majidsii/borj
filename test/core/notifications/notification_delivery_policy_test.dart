import 'package:borj/core/notifications/notification_delivery_policy.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full privacy mode preserves notification title and body', () {
    final content = NotificationDeliveryPolicy.contentFor(
      _request(privacyMode: NotificationPrivacyMode.full),
    );

    expect(content.title, 'ارسال گزارش');
    expect(content.body, 'زمان انجام تسک رسیده است.');
  });

  test('private mode hides sensitive title and body', () {
    final content = NotificationDeliveryPolicy.contentFor(
      _request(privacyMode: NotificationPrivacyMode.private),
    );

    expect(content.title, 'برج');
    expect(content.body, 'یک یادآور جدید دارید.');
    expect(content.title, isNot(contains('گزارش')));
    expect(content.body, isNot(contains('تسک')));
  });
}

NotificationRequest _request({required NotificationPrivacyMode privacyMode}) {
  return NotificationRequest(
    scheduleId: 'task-1-reminder-0',
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-1'),
    title: 'ارسال گزارش',
    body: 'زمان انجام تسک رسیده است.',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, 14, 30),
    privacyMode: privacyMode,
  );
}
