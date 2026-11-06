import 'package:borj/core/notifications/notification_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nullable plugin values map safely', () {
    expect(
      notificationPermissionStatusFromNullableBool(true),
      NotificationPermissionStatus.granted,
    );
    expect(
      notificationPermissionStatusFromNullableBool(false),
      NotificationPermissionStatus.denied,
    );
    expect(
      notificationPermissionStatusFromNullableBool(null),
      NotificationPermissionStatus.unavailable,
    );
  });

  test('only granted and notRequired allow delivery', () {
    expect(NotificationPermissionStatus.granted.allowsDelivery, isTrue);
    expect(NotificationPermissionStatus.notRequired.allowsDelivery, isTrue);
    expect(NotificationPermissionStatus.denied.allowsDelivery, isFalse);
    expect(NotificationPermissionStatus.unavailable.allowsDelivery, isFalse);
  });
}
