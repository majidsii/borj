import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_payload_codec.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/platform_notification_scheduler.dart';
import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native_notification_gateway.dart';

void main() {
  final now = DateTime.utc(2026, 7, 27, 8);

  test('future request uses native scheduling with private content', () async {
    final gateway = FakeNativeNotificationGateway();
    final scheduler = PlatformNotificationScheduler(
      gateway: gateway,
      capabilities: _nativeCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );
    final request = _request(
      scheduleId: 'task-private',
      hour: 10,
      privacyMode: NotificationPrivacyMode.private,
    );

    await scheduler.schedule(request);

    expect(gateway.calls, hasLength(1));
    final call = gateway.calls.single;
    expect(call.kind, 'schedule');
    expect(call.id, StableNotificationId.fromScheduleId(request.scheduleId));
    expect(call.title, 'برج');
    expect(call.body, 'یک یادآور جدید دارید.');
    expect(call.scheduledAtUtc, DateTime.utc(2026, 7, 27, 10));

    final payload = NotificationPayloadCodec.decode(call.payload!);
    expect(payload.scheduleId, request.scheduleId);
    expect(payload.owner, request.owner);
  });

  test('due request is shown immediately when supported', () async {
    final gateway = FakeNativeNotificationGateway();
    final scheduler = PlatformNotificationScheduler(
      gateway: gateway,
      capabilities: _linuxCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    await scheduler.schedule(_request(scheduleId: 'due-now', hour: 8));

    expect(gateway.calls.single.kind, 'show');
  });

  test('future Linux request remains deferred without a native call', () async {
    final gateway = FakeNativeNotificationGateway();
    final scheduler = PlatformNotificationScheduler(
      gateway: gateway,
      capabilities: _linuxCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    await scheduler.schedule(_request(scheduleId: 'linux-future', hour: 10));

    expect(gateway.calls, isEmpty);
  });

  test('unsupported platform fails closed', () async {
    final scheduler = PlatformNotificationScheduler(
      gateway: FakeNativeNotificationGateway(),
      capabilities: _unsupportedCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    await expectLater(
      scheduler.schedule(_request(scheduleId: 'unsupported', hour: 10)),
      throwsUnsupportedError,
    );
  });

  test('cancel maps the schedule id to the stable native id', () async {
    final gateway = FakeNativeNotificationGateway();
    final scheduler = PlatformNotificationScheduler(
      gateway: gateway,
      capabilities: _nativeCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    await scheduler.cancel('task-cancel');

    expect(gateway.calls.single.kind, 'cancel');
    expect(
      gateway.calls.single.id,
      StableNotificationId.fromScheduleId('task-cancel'),
    );
  });

  test('cancelByOwner cancels only matching decodable pending items', () async {
    final gateway = FakeNativeNotificationGateway();
    final scheduler = PlatformNotificationScheduler(
      gateway: gateway,
      capabilities: _nativeCapabilities,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );
    final task = _request(scheduleId: 'task-a', hour: 10);
    final habit = _request(scheduleId: 'habit-a', hour: 11, owner: _habitOwner);

    gateway.pendingItems.addAll(<NativePendingNotification>[
      NativePendingNotification(
        id: StableNotificationId.fromScheduleId(task.scheduleId),
        payload: NotificationPayloadCodec.encode(task),
      ),
      NativePendingNotification(
        id: StableNotificationId.fromScheduleId(habit.scheduleId),
        payload: NotificationPayloadCodec.encode(habit),
      ),
      const NativePendingNotification(id: 999, payload: 'broken'),
    ]);

    await scheduler.cancelByOwner(_taskOwner);

    expect(
      gateway.calls
          .where((call) => call.kind == 'cancel')
          .map((call) => call.id),
      <int>[StableNotificationId.fromScheduleId(task.scheduleId)],
    );
  });

  test(
    'reconcile removes stale pending and schedules future desired items',
    () async {
      final gateway = FakeNativeNotificationGateway();
      final scheduler = PlatformNotificationScheduler(
        gateway: gateway,
        capabilities: _nativeCapabilities,
        clock: FixedAppClock(utcValue: now, localValue: now),
      );
      final kept = _request(scheduleId: 'kept', hour: 10);
      final stale = _request(scheduleId: 'stale', hour: 11);

      gateway.pendingItems.addAll(<NativePendingNotification>[
        NativePendingNotification(
          id: StableNotificationId.fromScheduleId(kept.scheduleId),
          payload: NotificationPayloadCodec.encode(kept),
        ),
        NativePendingNotification(
          id: StableNotificationId.fromScheduleId(stale.scheduleId),
          payload: NotificationPayloadCodec.encode(stale),
        ),
      ]);

      await scheduler.reconcile(<NotificationRequest>[
        kept,
        _request(scheduleId: 'new', hour: 12),
        _request(scheduleId: 'already-due', hour: 7),
      ]);

      final cancelled = gateway.calls
          .where((call) => call.kind == 'cancel')
          .map((call) => call.id);
      expect(cancelled, <int>[
        StableNotificationId.fromScheduleId(stale.scheduleId),
      ]);

      final scheduled = gateway.calls
          .where((call) => call.kind == 'schedule')
          .map((call) => call.id);
      expect(scheduled, <int>[
        StableNotificationId.fromScheduleId('kept'),
        StableNotificationId.fromScheduleId('new'),
      ]);
      expect(gateway.calls.where((call) => call.kind == 'show'), isEmpty);
    },
  );

  test(
    'Linux reconcile does not replay due notifications on startup',
    () async {
      final gateway = FakeNativeNotificationGateway();
      final scheduler = PlatformNotificationScheduler(
        gateway: gateway,
        capabilities: _linuxCapabilities,
        clock: FixedAppClock(utcValue: now, localValue: now),
      );

      await scheduler.reconcile(<NotificationRequest>[
        _request(scheduleId: 'due', hour: 7),
        _request(scheduleId: 'future', hour: 10),
      ]);

      expect(gateway.calls, isEmpty);
    },
  );
}

const _nativeCapabilities = NotificationPlatformCapabilities(
  supportsImmediateDelivery: true,
  supportsScheduledDelivery: true,
  supportsPendingRequests: true,
);

const _linuxCapabilities = NotificationPlatformCapabilities(
  supportsImmediateDelivery: true,
  supportsScheduledDelivery: false,
  supportsPendingRequests: false,
);

const _unsupportedCapabilities = NotificationPlatformCapabilities(
  supportsImmediateDelivery: false,
  supportsScheduledDelivery: false,
  supportsPendingRequests: false,
);

final _taskOwner = NotificationOwner(
  type: NotificationOwnerType.task,
  id: 'task-1',
);

final _habitOwner = NotificationOwner(
  type: NotificationOwnerType.habit,
  id: 'habit-1',
);

NotificationRequest _request({
  required String scheduleId,
  required int hour,
  NotificationOwner? owner,
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: owner ?? _taskOwner,
    title: 'ارسال گزارش',
    body: 'زمان انجام تسک رسیده است.',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, hour),
    payload: const <String, String>{'route': '/tasks/task-1'},
    privacyMode: privacyMode,
  );
}
