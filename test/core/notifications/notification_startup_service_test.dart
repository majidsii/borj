import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/local_notifications_driver.dart';
import 'package:borj/core/notifications/local_notifications_initializer.dart';
import 'package:borj/core/notifications/notification_coordinator.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:borj/core/notifications/notification_startup_service.dart';
import 'package:borj/core/notifications/notification_time_zone_initializer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_notification_schedule_repository.dart';

void main() {
  late MemoryNotificationScheduleRepository repository;

  setUp(() {
    repository = MemoryNotificationScheduleRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  test('initializes plugin before reconcile and runs only once', () async {
    final events = <String>[];
    final service = _service(
      repository: repository,
      events: events,
      scheduler: _RecordingScheduler(events),
    );

    await Future.wait(<Future<void>>[
      service.initialize(),
      service.initialize(),
      service.initialize(),
    ]);

    expect(events, const <String>[
      'timezone-database',
      'timezone-source',
      'timezone-select:Asia/Tehran',
      'plugin',
      'reconcile',
    ]);
  });

  test(
    'failed reconcile can be retried without reinitializing plugin',
    () async {
      final events = <String>[];
      final scheduler = _RetryingReconcileScheduler(events);
      final service = _service(
        repository: repository,
        events: events,
        scheduler: scheduler,
      );

      await expectLater(service.initialize(), throwsStateError);
      await service.initialize();

      expect(events, const <String>[
        'timezone-database',
        'timezone-source',
        'timezone-select:Asia/Tehran',
        'plugin',
        'reconcile-1',
        'reconcile-2',
      ]);
    },
  );

  test('disabled startup does not initialize plugin or reconcile', () async {
    final events = <String>[];
    final service = _service(
      repository: repository,
      events: events,
      scheduler: _RecordingScheduler(events),
      enabled: false,
    );

    await service.initialize();

    expect(events, isEmpty);
  });
}

NotificationStartupService _service({
  required MemoryNotificationScheduleRepository repository,
  required List<String> events,
  required NotificationScheduler scheduler,
  bool enabled = true,
}) {
  final initializer = LocalNotificationsInitializer(
    timeZoneInitializer: NotificationTimeZoneInitializer(
      source: _Source(events),
      runtime: _Runtime(events),
    ),
    driver: _Driver(events),
  );
  final coordinator = NotificationCoordinator(
    repository: repository,
    scheduler: scheduler,
  );

  return NotificationStartupService(
    enabled: enabled,
    initializer: initializer,
    coordinator: coordinator,
  );
}

final class _Source implements DeviceTimeZoneSource {
  _Source(this.events);

  final List<String> events;

  @override
  Future<String> localTimeZoneName() async {
    events.add('timezone-source');
    return 'Asia/Tehran';
  }
}

final class _Runtime implements NotificationTimeZoneRuntime {
  _Runtime(this.events);

  final List<String> events;

  @override
  void initializeDatabase() {
    events.add('timezone-database');
  }

  @override
  bool selectLocation(String name) {
    events.add('timezone-select:$name');
    return true;
  }
}

final class _Driver implements LocalNotificationsDriver {
  _Driver(this.events);

  final List<String> events;

  @override
  Future<void> initialize() async {
    events.add('plugin');
  }
}

class _RecordingScheduler implements NotificationScheduler {
  _RecordingScheduler(this.events);

  final List<String> events;

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {
    events.add('reconcile');
  }

  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<void> cancel(String scheduleId) async {}

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {}
}

final class _RetryingReconcileScheduler extends _RecordingScheduler {
  _RetryingReconcileScheduler(super.events);

  int _attempt = 0;

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {
    _attempt += 1;
    events.add('reconcile-$_attempt');
    if (_attempt == 1) {
      throw StateError('reconcile failed');
    }
  }
}
