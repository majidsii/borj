import 'package:borj/core/notifications/notification_host_platform.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web always maps to unsupported', () {
    expect(
      detectNotificationHostPlatform(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      NotificationHostPlatform.unsupported,
    );
  });

  test('native Flutter platforms map to notification host platforms', () {
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      NotificationHostPlatform.android,
    );
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      NotificationHostPlatform.linux,
    );
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.macOS,
      ),
      NotificationHostPlatform.macos,
    );
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      NotificationHostPlatform.windows,
    );
  });

  test('iOS and Fuchsia fail closed because iOS is out of scope', () {
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.iOS,
      ),
      NotificationHostPlatform.unsupported,
    );
    expect(
      detectNotificationHostPlatform(
        isWeb: false,
        platform: TargetPlatform.fuchsia,
      ),
      NotificationHostPlatform.unsupported,
    );
  });
}
