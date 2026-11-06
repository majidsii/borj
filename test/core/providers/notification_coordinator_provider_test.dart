import 'package:borj/core/notifications/noop_notification_scheduler.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_scheduler.dart';
import '../../support/memory_notification_schedule_repository.dart';

void main() {
  test('unsupported platform uses the safe noop scheduler', () {
    final container = ProviderContainer(
      overrides: <Override>[
        notificationHostPlatformProvider.overrideWithValue(
          NotificationHostPlatform.unsupported,
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(notificationSchedulerProvider),
      isA<NoopNotificationScheduler>(),
    );
  });

  test(
    'coordinator provider uses repository and scheduler overrides',
    () async {
      final repository = MemoryNotificationScheduleRepository();
      final scheduler = FakeNotificationScheduler();
      final container = ProviderContainer(
        overrides: <Override>[
          notificationScheduleRepositoryProvider.overrideWithValue(repository),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      await container
          .read(notificationCoordinatorProvider)
          .schedule(
            NotificationRequest(
              scheduleId: 'provider-reminder',
              owner: NotificationOwner(
                type: NotificationOwnerType.task,
                id: 'provider-task',
              ),
              title: 'تست Provider',
              body: 'متن',
              scheduledAtUtc: DateTime.utc(2026, 7, 27, 12),
            ),
          );

      expect(repository.items.single.scheduleId, 'provider-reminder');
      expect(
        scheduler.scheduledRequests.single.scheduleId,
        'provider-reminder',
      );
    },
  );
}
