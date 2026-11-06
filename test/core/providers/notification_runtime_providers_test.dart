import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/local_notifications_driver.dart';
import 'package:borj/core/notifications/noop_notification_scheduler.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_startup_service.dart';
import 'package:borj/core/notifications/notification_time_zone_initializer.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native_notification_gateway.dart';
import '../../support/memory_notification_schedule_repository.dart';

void main() {
  test('Linux provider graph uses systemd scheduler', () async {
    final repository = MemoryNotificationScheduleRepository();
    final driver = _Driver();
    final gateway = FakeNativeNotificationGateway();
    final now = DateTime.utc(2026, 7, 27, 8);
    final container = ProviderContainer(
      overrides: <Override>[
        notificationHostPlatformProvider.overrideWithValue(
          NotificationHostPlatform.linux,
        ),
        notificationScheduleRepositoryProvider.overrideWithValue(repository),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: now, localValue: now),
        ),
        deviceTimeZoneSourceProvider.overrideWithValue(const _Source()),
        notificationTimeZoneRuntimeProvider.overrideWithValue(_Runtime()),
        localNotificationsDriverProvider.overrideWithValue(driver),
        nativeNotificationGatewayProvider.overrideWithValue(gateway),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    expect(
      container.read(notificationPlatformCapabilitiesProvider),
      NotificationPlatformCapabilities.forPlatform(
        NotificationHostPlatform.linux,
      ),
    );
    expect(
      container.read(notificationSchedulerProvider),
      isA<LinuxSystemdNotificationScheduler>(),
    );
    expect(
      container.read(notificationStartupProvider),
      isA<NotificationStartupService>(),
    );

    await container.read(notificationStartupProvider).initialize();

    expect(driver.callCount, 1);
    expect(gateway.calls, isEmpty);
  });

  test('unsupported platform uses noop scheduler and skips startup', () async {
    final repository = MemoryNotificationScheduleRepository();
    final driver = _Driver();
    final container = ProviderContainer(
      overrides: <Override>[
        notificationHostPlatformProvider.overrideWithValue(
          NotificationHostPlatform.unsupported,
        ),
        notificationScheduleRepositoryProvider.overrideWithValue(repository),
        localNotificationsDriverProvider.overrideWithValue(driver),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    expect(
      container.read(notificationSchedulerProvider),
      isA<NoopNotificationScheduler>(),
    );

    await container.read(notificationStartupProvider).initialize();

    expect(driver.callCount, 0);
  });
}

final class _Driver implements LocalNotificationsDriver {
  int callCount = 0;

  @override
  Future<void> initialize() async {
    callCount += 1;
  }
}

final class _Source implements DeviceTimeZoneSource {
  const _Source();

  @override
  Future<String> localTimeZoneName() async => 'Asia/Tehran';
}

final class _Runtime implements NotificationTimeZoneRuntime {
  @override
  void initializeDatabase() {}

  @override
  bool selectLocation(String name) => true;
}
