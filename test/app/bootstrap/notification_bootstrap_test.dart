import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/core/notifications/notification_startup_service.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap helper initializes notifications through Riverpod', () async {
    final startup = _FakeNotificationStartup();
    final container = ProviderContainer(
      overrides: <Override>[
        notificationStartupProvider.overrideWithValue(startup),
      ],
    );
    addTearDown(container.dispose);

    await initializeNotificationsForApp(container);

    expect(startup.callCount, 1);
  });
}

final class _FakeNotificationStartup implements NotificationStartup {
  int callCount = 0;

  @override
  Future<void> initialize() async {
    callCount += 1;
  }
}
