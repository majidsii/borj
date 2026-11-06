import 'dart:async';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/drift_notification_schedule_repository.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = openTestDatabase();
    final now = DateTime.utc(2026, 7, 27, 8);
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: now, localValue: now),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('notification repository provider uses Drift persistence', () {
    expect(
      container.read(notificationScheduleRepositoryProvider),
      isA<DriftNotificationScheduleRepository>(),
    );
  });

  test('notificationSchedulesProvider emits persisted requests', () async {
    final expectedData = _waitForData<List<NotificationRequest>>(
      container,
      notificationSchedulesProvider,
      (items) =>
          items.length == 1 &&
          items.single.scheduleId == 'provider-notification',
    );

    await container
        .read(notificationScheduleRepositoryProvider)
        .upsert(
          NotificationRequest(
            scheduleId: 'provider-notification',
            owner: NotificationOwner(
              type: NotificationOwnerType.task,
              id: 'provider-task',
            ),
            title: 'یادآور تست',
            body: 'متن',
            scheduledAtUtc: DateTime.utc(2026, 7, 27, 12),
          ),
        );

    final items = await expectedData;
    expect(items.single.title, 'یادآور تست');
  });
}

Future<T> _waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
  bool Function(T value) predicate,
) {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;

  subscription = container.listen<AsyncValue<T>>(provider, (previous, next) {
    next.whenData((value) {
      if (!completer.isCompleted && predicate(value)) {
        completer.complete(value);
      }
    });
  }, fireImmediately: true);

  return completer.future
      .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          subscription.close();
          throw TimeoutException('Provider did not emit the expected value.');
        },
      )
      .whenComplete(subscription.close);
}
