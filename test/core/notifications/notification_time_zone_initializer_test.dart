import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/notification_time_zone_initializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initializes the database and selects the device IANA location once',
    () async {
      final source = _FakeDeviceTimeZoneSource('Asia/Tehran');
      final runtime = _FakeNotificationTimeZoneRuntime(
        availableLocations: const <String>{'Asia/Tehran', 'Etc/UTC'},
      );
      final initializer = NotificationTimeZoneInitializer(
        source: source,
        runtime: runtime,
      );

      final first = await initializer.initialize();
      final second = await initializer.initialize();

      expect(first, 'Asia/Tehran');
      expect(second, 'Asia/Tehran');
      expect(source.callCount, 1);
      expect(runtime.initializeCallCount, 1);
      expect(runtime.selectedLocation, 'Asia/Tehran');
    },
  );

  test(
    'falls back to Etc/UTC when the device location is unavailable',
    () async {
      final runtime = _FakeNotificationTimeZoneRuntime(
        availableLocations: const <String>{'Etc/UTC'},
      );
      final initializer = NotificationTimeZoneInitializer(
        source: _FakeDeviceTimeZoneSource('Unknown/Zone'),
        runtime: runtime,
      );

      final selected = await initializer.initialize();

      expect(selected, 'Etc/UTC');
      expect(runtime.selectedLocation, 'Etc/UTC');
    },
  );

  test('a failed initialization can be retried', () async {
    final source = _RetryingDeviceTimeZoneSource();
    final runtime = _FakeNotificationTimeZoneRuntime(
      availableLocations: const <String>{'Europe/Warsaw', 'Etc/UTC'},
    );
    final initializer = NotificationTimeZoneInitializer(
      source: source,
      runtime: runtime,
    );

    await expectLater(initializer.initialize(), throwsStateError);
    final selected = await initializer.initialize();

    expect(selected, 'Europe/Warsaw');
    expect(source.callCount, 2);
    expect(runtime.initializeCallCount, 2);
  });
}

final class _FakeDeviceTimeZoneSource implements DeviceTimeZoneSource {
  _FakeDeviceTimeZoneSource(this.value);

  final String value;
  int callCount = 0;

  @override
  Future<String> localTimeZoneName() async {
    callCount += 1;
    return value;
  }
}

final class _RetryingDeviceTimeZoneSource implements DeviceTimeZoneSource {
  int callCount = 0;

  @override
  Future<String> localTimeZoneName() async {
    callCount += 1;
    if (callCount == 1) {
      throw StateError('timezone plugin failed');
    }
    return 'Europe/Warsaw';
  }
}

final class _FakeNotificationTimeZoneRuntime
    implements NotificationTimeZoneRuntime {
  _FakeNotificationTimeZoneRuntime({required this.availableLocations});

  final Set<String> availableLocations;
  int initializeCallCount = 0;
  String? selectedLocation;

  @override
  void initializeDatabase() {
    initializeCallCount += 1;
  }

  @override
  bool selectLocation(String name) {
    if (!availableLocations.contains(name)) {
      return false;
    }
    selectedLocation = name;
    return true;
  }
}
