import 'package:borj/core/date_time/app_clock.dart';

import 'native_notification_gateway.dart';
import 'notification_delivery_policy.dart';
import 'notification_owner.dart';
import 'notification_payload_codec.dart';
import 'notification_platform_capabilities.dart';
import 'notification_request.dart';
import 'notification_scheduler.dart';
import 'stable_notification_id.dart';

final class PlatformNotificationScheduler implements NotificationScheduler {
  factory PlatformNotificationScheduler({
    required NativeNotificationGateway gateway,
    required NotificationPlatformCapabilities capabilities,
    AppClock clock = const SystemAppClock(),
  }) {
    return PlatformNotificationScheduler._(gateway, capabilities, clock);
  }

  const PlatformNotificationScheduler._(
    this._gateway,
    this._capabilities,
    this._clock,
  );

  final NativeNotificationGateway _gateway;
  final NotificationPlatformCapabilities _capabilities;
  final AppClock _clock;

  @override
  Future<void> schedule(NotificationRequest request) async {
    if (!_capabilities.supportsImmediateDelivery &&
        !_capabilities.supportsScheduledDelivery) {
      throw UnsupportedError(
        'Local notifications are unavailable on this platform.',
      );
    }

    final nowUtc = _clock.nowUtc().toUtc();
    if (!request.scheduledAtUtc.isAfter(nowUtc)) {
      if (_capabilities.supportsImmediateDelivery) {
        await _showNow(request);
      }
      return;
    }

    if (_capabilities.supportsScheduledDelivery) {
      await _scheduleNative(request);
    }
  }

  @override
  Future<void> cancel(String scheduleId) async {
    if (!_capabilities.supportsImmediateDelivery &&
        !_capabilities.supportsScheduledDelivery) {
      return;
    }

    await _gateway.cancel(StableNotificationId.fromScheduleId(scheduleId));
  }

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {
    if (!_capabilities.supportsPendingRequests) {
      return;
    }

    final pending = await _gateway.pending();
    for (final item in pending) {
      final payload = item.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }

      try {
        final decoded = NotificationPayloadCodec.decode(payload);
        if (decoded.owner == owner) {
          await _gateway.cancel(item.id);
        }
      } on FormatException {
        continue;
      }
    }
  }

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {
    if (!_capabilities.supportsScheduledDelivery) {
      return;
    }

    final nowUtc = _clock.nowUtc().toUtc();
    final futureByNativeId = <int, NotificationRequest>{
      for (final request in expected)
        if (request.scheduledAtUtc.isAfter(nowUtc))
          StableNotificationId.fromScheduleId(request.scheduleId): request,
    };

    if (_capabilities.supportsPendingRequests) {
      final pending = await _gateway.pending();
      for (final item in pending) {
        if (!futureByNativeId.containsKey(item.id)) {
          await _gateway.cancel(item.id);
        }
      }
    }

    for (final request in futureByNativeId.values) {
      await _scheduleNative(request);
    }
  }

  Future<void> _showNow(NotificationRequest request) {
    final content = NotificationDeliveryPolicy.contentFor(request);
    return _gateway.showNow(
      id: StableNotificationId.fromScheduleId(request.scheduleId),
      title: content.title,
      body: content.body,
      payload: NotificationPayloadCodec.encode(request),
    );
  }

  Future<void> _scheduleNative(NotificationRequest request) {
    final content = NotificationDeliveryPolicy.contentFor(request);
    return _gateway.schedule(
      id: StableNotificationId.fromScheduleId(request.scheduleId),
      title: content.title,
      body: content.body,
      scheduledAtUtc: request.scheduledAtUtc,
      payload: NotificationPayloadCodec.encode(request),
    );
  }
}
