import 'package:borj/core/notifications/notification_permission.dart';
import 'package:borj/core/notifications/notification_permission_service.dart';
import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native_notification_gateway.dart';
import '../../support/fake_notification_permission_gateway.dart';

void main() {
  test('health exposes whether permission allows delivery', () async {
    final service = NotificationPermissionService(
      permissionGateway: FakeNotificationPermissionGateway(
        status: NotificationPermissionStatus.granted,
      ),
      notificationGateway: FakeNativeNotificationGateway(),
    );

    final health = await service.health();

    expect(health.status, NotificationPermissionStatus.granted);
    expect(health.canDeliver, isTrue);
  });

  test('request returns refreshed permission health', () async {
    final permissionGateway = FakeNotificationPermissionGateway(
      status: NotificationPermissionStatus.denied,
      requestResult: NotificationPermissionStatus.granted,
    );
    final service = NotificationPermissionService(
      permissionGateway: permissionGateway,
      notificationGateway: FakeNativeNotificationGateway(),
    );

    final health = await service.requestPermission();

    expect(health.status, NotificationPermissionStatus.granted);
    expect(health.canDeliver, isTrue);
    expect(permissionGateway.requestCallCount, 1);
  });

  test('test notification is blocked while permission is denied', () async {
    final nativeGateway = FakeNativeNotificationGateway();
    final service = NotificationPermissionService(
      permissionGateway: FakeNotificationPermissionGateway(
        status: NotificationPermissionStatus.denied,
      ),
      notificationGateway: nativeGateway,
    );

    final result = await service.sendTestNotification();

    expect(result, NotificationTestResult.blockedByPermission);
    expect(nativeGateway.calls, isEmpty);
  });

  test('test notification is sent for granted permission', () async {
    final nativeGateway = FakeNativeNotificationGateway();
    final service = NotificationPermissionService(
      permissionGateway: FakeNotificationPermissionGateway(
        status: NotificationPermissionStatus.granted,
      ),
      notificationGateway: nativeGateway,
    );

    final result = await service.sendTestNotification();

    expect(result, NotificationTestResult.sent);
    expect(nativeGateway.calls, hasLength(1));

    final call = nativeGateway.calls.single;
    expect(call.kind, 'show');
    expect(
      call.id,
      StableNotificationId.fromScheduleId(
        NotificationPermissionService.testScheduleId,
      ),
    );
    expect(call.title, 'اعلان آزمایشی');
    expect(call.body, 'اعلان‌های برج فعال هستند.');
    expect(
      call.payload,
      contains(NotificationPermissionService.testScheduleId),
    );
  });

  test('notRequired permission can send a test notification', () async {
    final nativeGateway = FakeNativeNotificationGateway();
    final service = NotificationPermissionService(
      permissionGateway: FakeNotificationPermissionGateway(
        status: NotificationPermissionStatus.notRequired,
      ),
      notificationGateway: nativeGateway,
    );

    final result = await service.sendTestNotification();

    expect(result, NotificationTestResult.sent);
    expect(nativeGateway.calls, hasLength(1));
  });

  test('unavailable platform does not attempt native delivery', () async {
    final nativeGateway = FakeNativeNotificationGateway();
    final service = NotificationPermissionService(
      permissionGateway: FakeNotificationPermissionGateway(
        status: NotificationPermissionStatus.unavailable,
      ),
      notificationGateway: nativeGateway,
    );

    final result = await service.sendTestNotification();

    expect(result, NotificationTestResult.unavailable);
    expect(nativeGateway.calls, isEmpty);
  });
}
