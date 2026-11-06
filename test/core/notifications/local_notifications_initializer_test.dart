import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/local_notifications_driver.dart';
import 'package:borj/core/notifications/local_notifications_initializer.dart';
import 'package:borj/core/notifications/notification_time_zone_initializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initializes timezone before the notification plugin and only once',
    () async {
      final events = <String>[];
      final initializer = LocalNotificationsInitializer(
        timeZoneInitializer: NotificationTimeZoneInitializer(
          source: _Source(events),
          runtime: _Runtime(events),
        ),
        driver: _Driver(events),
      );

      await Future.wait(<Future<void>>[
        initializer.initialize(),
        initializer.initialize(),
        initializer.initialize(),
      ]);

      expect(events, const <String>[
        'timezone-database',
        'timezone-source',
        'timezone-select:Asia/Tehran',
        'plugin',
      ]);
    },
  );

  test('plugin initialization failure can be retried', () async {
    final driver = _RetryingDriver();
    final initializer = LocalNotificationsInitializer(
      timeZoneInitializer: NotificationTimeZoneInitializer(
        source: _Source(<String>[]),
        runtime: _Runtime(<String>[]),
      ),
      driver: driver,
    );

    await expectLater(initializer.initialize(), throwsStateError);
    await initializer.initialize();

    expect(driver.callCount, 2);
  });
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

final class _RetryingDriver implements LocalNotificationsDriver {
  int callCount = 0;

  @override
  Future<void> initialize() async {
    callCount += 1;
    if (callCount == 1) {
      throw StateError('plugin initialization failed');
    }
  }
}
