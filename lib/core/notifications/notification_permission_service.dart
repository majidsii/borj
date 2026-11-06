import 'native_notification_gateway.dart';
import 'notification_owner.dart';
import 'notification_payload_codec.dart';
import 'notification_permission.dart';
import 'notification_request.dart';
import 'stable_notification_id.dart';

enum NotificationTestResult { sent, blockedByPermission, unavailable }

final class NotificationPermissionService {
  factory NotificationPermissionService({
    required NotificationPermissionGateway permissionGateway,
    required NativeNotificationGateway notificationGateway,
  }) {
    return NotificationPermissionService._(
      permissionGateway,
      notificationGateway,
    );
  }

  const NotificationPermissionService._(
    this._permissionGateway,
    this._notificationGateway,
  );

  static const String testScheduleId = 'system-test-notification';

  final NotificationPermissionGateway _permissionGateway;
  final NativeNotificationGateway _notificationGateway;

  Future<NotificationPermissionHealth> health() async {
    return NotificationPermissionHealth(
      status: await _permissionGateway.status(),
    );
  }

  Future<NotificationPermissionHealth> requestPermission() async {
    return NotificationPermissionHealth(
      status: await _permissionGateway.request(),
    );
  }

  Future<NotificationTestResult> sendTestNotification() async {
    final permission = await _permissionGateway.status();

    if (permission == NotificationPermissionStatus.unavailable) {
      return NotificationTestResult.unavailable;
    }
    if (!permission.allowsDelivery) {
      return NotificationTestResult.blockedByPermission;
    }

    final request = NotificationRequest(
      scheduleId: testScheduleId,
      owner: NotificationOwner(
        type: NotificationOwnerType.dailySummary,
        id: 'notification-health',
      ),
      title: 'اعلان آزمایشی',
      body: 'اعلان‌های برج فعال هستند.',
      scheduledAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      payload: const <String, String>{
        'source': 'notification-settings',
        'kind': 'test',
      },
    );

    await _notificationGateway.showNow(
      id: StableNotificationId.fromScheduleId(testScheduleId),
      title: request.title,
      body: request.body,
      payload: NotificationPayloadCodec.encode(request),
    );

    return NotificationTestResult.sent;
  }
}
