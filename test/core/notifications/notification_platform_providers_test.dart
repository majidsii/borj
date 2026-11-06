import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/noop_notification_scheduler.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_platform_providers.dart';
import 'package:borj/core/notifications/platform_notification_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationSchedulerProvider', () {
    test('selects the Linux systemd scheduler on Linux', () {
      final container = ProviderContainer(
        overrides: <Override>[
          notificationHostPlatformProvider.overrideWithValue(
            NotificationHostPlatform.linux,
          ),
        ],
      );
      addTearDown(container.dispose);

      final scheduler = container.read(notificationSchedulerProvider);

      expect(scheduler, isA<LinuxSystemdNotificationScheduler>());
      expect(
        identical(
          scheduler,
          container.read(linuxSystemdNotificationSchedulerProvider),
        ),
        isTrue,
      );
    });

    for (final platform in <NotificationHostPlatform>[
      NotificationHostPlatform.android,
      NotificationHostPlatform.macos,
      NotificationHostPlatform.windows,
    ]) {
      test('selects the native platform scheduler on ${platform.name}', () {
        final container = ProviderContainer(
          overrides: <Override>[
            notificationHostPlatformProvider.overrideWithValue(platform),
          ],
        );
        addTearDown(container.dispose);

        final scheduler = container.read(notificationSchedulerProvider);

        expect(scheduler, isA<PlatformNotificationScheduler>());
        expect(
          identical(
            scheduler,
            container.read(platformNotificationSchedulerProvider),
          ),
          isTrue,
        );
      });
    }

    test('selects the noop scheduler on unsupported hosts', () {
      final container = ProviderContainer(
        overrides: <Override>[
          notificationHostPlatformProvider.overrideWithValue(
            NotificationHostPlatform.unsupported,
          ),
        ],
      );
      addTearDown(container.dispose);

      final scheduler = container.read(notificationSchedulerProvider);

      expect(scheduler, isA<NoopNotificationScheduler>());
      expect(
        identical(scheduler, container.read(noopNotificationSchedulerProvider)),
        isTrue,
      );
    });

    for (final platform in <NotificationHostPlatform>[
      NotificationHostPlatform.android,
      NotificationHostPlatform.macos,
      NotificationHostPlatform.windows,
      NotificationHostPlatform.unsupported,
    ]) {
      test('does not construct Linux dependencies on ${platform.name}', () {
        var linuxConstructionCount = 0;
        final container = ProviderContainer(
          overrides: <Override>[
            notificationHostPlatformProvider.overrideWithValue(platform),
            linuxSystemdNotificationSchedulerProvider.overrideWith((ref) {
              linuxConstructionCount += 1;
              throw StateError('Linux dependencies must stay lazy.');
            }),
          ],
        );
        addTearDown(container.dispose);

        container.read(notificationSchedulerProvider);

        expect(linuxConstructionCount, 0);
      });
    }

    test('Linux branch does not construct platform or noop schedulers', () {
      var platformConstructionCount = 0;
      var noopConstructionCount = 0;
      final container = ProviderContainer(
        overrides: <Override>[
          notificationHostPlatformProvider.overrideWithValue(
            NotificationHostPlatform.linux,
          ),
          platformNotificationSchedulerProvider.overrideWith((ref) {
            platformConstructionCount += 1;
            throw StateError('Platform scheduler must stay lazy.');
          }),
          noopNotificationSchedulerProvider.overrideWith((ref) {
            noopConstructionCount += 1;
            throw StateError('Noop scheduler must stay lazy.');
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(notificationSchedulerProvider),
        isA<LinuxSystemdNotificationScheduler>(),
      );
      expect(platformConstructionCount, 0);
      expect(noopConstructionCount, 0);
    });

    test(
      'unsupported branch constructs neither native nor Linux scheduler',
      () {
        var platformConstructionCount = 0;
        var linuxConstructionCount = 0;
        final container = ProviderContainer(
          overrides: <Override>[
            notificationHostPlatformProvider.overrideWithValue(
              NotificationHostPlatform.unsupported,
            ),
            platformNotificationSchedulerProvider.overrideWith((ref) {
              platformConstructionCount += 1;
              throw StateError('Native scheduler must stay lazy.');
            }),
            linuxSystemdNotificationSchedulerProvider.overrideWith((ref) {
              linuxConstructionCount += 1;
              throw StateError('Linux scheduler must stay lazy.');
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(notificationSchedulerProvider),
          isA<NoopNotificationScheduler>(),
        );
        expect(platformConstructionCount, 0);
        expect(linuxConstructionCount, 0);
      },
    );

    test('selected scheduler identity is cached by the provider container', () {
      final container = ProviderContainer(
        overrides: <Override>[
          notificationHostPlatformProvider.overrideWithValue(
            NotificationHostPlatform.linux,
          ),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(notificationSchedulerProvider);
      final second = container.read(notificationSchedulerProvider);

      expect(identical(first, second), isTrue);
    });

    test('host platform is injectable without dart:io platform checks', () {
      final container = ProviderContainer(
        overrides: <Override>[
          notificationHostPlatformProvider.overrideWithValue(
            NotificationHostPlatform.windows,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(notificationHostPlatformProvider),
        NotificationHostPlatform.windows,
      );
      expect(
        container.read(notificationSchedulerProvider),
        isA<PlatformNotificationScheduler>(),
      );
    });
  });
}
