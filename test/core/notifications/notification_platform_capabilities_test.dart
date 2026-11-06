import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android, macOS and Windows support native scheduled delivery', () {
    for (final platform in <NotificationHostPlatform>[
      NotificationHostPlatform.android,
      NotificationHostPlatform.macos,
      NotificationHostPlatform.windows,
    ]) {
      final capabilities = NotificationPlatformCapabilities.forPlatform(
        platform,
      );

      expect(
        capabilities.supportsImmediateDelivery,
        isTrue,
        reason: platform.name,
      );
      expect(
        capabilities.supportsScheduledDelivery,
        isTrue,
        reason: platform.name,
      );
      expect(
        capabilities.supportsPendingRequests,
        isTrue,
        reason: platform.name,
      );
    }
  });

  test('Linux supports immediate notifications but not native scheduling', () {
    final capabilities = NotificationPlatformCapabilities.forPlatform(
      NotificationHostPlatform.linux,
    );

    expect(capabilities.supportsImmediateDelivery, isTrue);
    expect(capabilities.supportsScheduledDelivery, isFalse);
    expect(capabilities.supportsPendingRequests, isFalse);
  });

  test('unsupported platforms fail closed', () {
    final capabilities = NotificationPlatformCapabilities.forPlatform(
      NotificationHostPlatform.unsupported,
    );

    expect(capabilities.supportsImmediateDelivery, isFalse);
    expect(capabilities.supportsScheduledDelivery, isFalse);
    expect(capabilities.supportsPendingRequests, isFalse);
  });
}
