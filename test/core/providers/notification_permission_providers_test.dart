import 'package:borj/core/notifications/notification_permission.dart';
import 'package:borj/core/notifications/notification_permission_service.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native_notification_gateway.dart';
import '../../support/fake_notification_permission_gateway.dart';

void main() {
  test('permission providers expose health and test delivery', () async {
    final nativeGateway = FakeNativeNotificationGateway();
    final permissionGateway = FakeNotificationPermissionGateway(
      status: NotificationPermissionStatus.granted,
    );
    final container = ProviderContainer(
      overrides: <Override>[
        notificationPermissionGatewayProvider.overrideWithValue(
          permissionGateway,
        ),
        nativeNotificationGatewayProvider.overrideWithValue(nativeGateway),
      ],
    );
    addTearDown(container.dispose);

    final health = await container.read(
      notificationPermissionHealthProvider.future,
    );

    expect(health.status, NotificationPermissionStatus.granted);
    expect(
      container.read(notificationPermissionServiceProvider),
      isA<NotificationPermissionService>(),
    );

    final result = await container
        .read(notificationPermissionServiceProvider)
        .sendTestNotification();

    expect(result, NotificationTestResult.sent);
    expect(nativeGateway.calls, hasLength(1));
  });
}
