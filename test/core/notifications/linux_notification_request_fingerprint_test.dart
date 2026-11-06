import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxNotificationRequestFingerprint', () {
    test('matches the fixed canonical SHA-256 vector', () async {
      final fingerprint = LinuxNotificationRequestFingerprint();

      expect(
        await fingerprint.compute(_request()),
        'f6ae7b7f35da4a7dfe74fc9144e726232ece9c67f130357d1ed39cef9ed51174',
      );
    });

    test('is independent of payload insertion order', () async {
      final fingerprint = LinuxNotificationRequestFingerprint();
      final first = _request(
        payload: const <String, String>{'z': '9', 'a': '1', 'middle': '5'},
      );
      final second = _request(
        payload: const <String, String>{'middle': '5', 'a': '1', 'z': '9'},
      );

      expect(
        await fingerprint.compute(first),
        await fingerprint.compute(second),
      );
    });

    test('is deterministic across repeated computations', () async {
      final fingerprint = LinuxNotificationRequestFingerprint();
      final request = _request();

      final first = await fingerprint.compute(request);
      final second = await fingerprint.compute(request);
      final third = await fingerprint.compute(request);

      expect(first, second);
      expect(second, third);
    });

    test('returns exactly 64 lowercase hexadecimal characters', () async {
      final digest = await LinuxNotificationRequestFingerprint().compute(
        _request(),
      );

      expect(digest, hasLength(64));
      expect(digest, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('never returns title, body, owner, or payload text', () async {
      const title = 'TOP_SECRET_TITLE';
      const body = 'TOP_SECRET_BODY';
      const ownerId = 'TOP_SECRET_OWNER';
      const payloadKey = 'TOP_SECRET_KEY';
      const payloadValue = 'TOP_SECRET_VALUE';
      final request = _request(
        ownerId: ownerId,
        title: title,
        body: body,
        payload: const <String, String>{payloadKey: payloadValue},
      );

      final digest = await LinuxNotificationRequestFingerprint().compute(
        request,
      );

      for (final secret in <String>[
        title,
        body,
        ownerId,
        payloadKey,
        payloadValue,
      ]) {
        expect(digest, isNot(contains(secret)));
      }
    });

    test('supports an empty payload canonically', () async {
      final fingerprint = LinuxNotificationRequestFingerprint();
      final request = _request(payload: const <String, String>{});

      final first = await fingerprint.compute(request);
      final second = await fingerprint.compute(request);

      expect(first, second);
      expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('supports Unicode content deterministically', () async {
      final fingerprint = LinuxNotificationRequestFingerprint();
      final request = _request(
        title: 'پرداخت اجاره',
        body: 'امروز سررسید می‌شود 😀',
        payload: const <String, String>{'کلید': 'مقدار'},
      );

      expect(
        await fingerprint.compute(request),
        await fingerprint.compute(request),
      );
    });

    test('changes when schedule id changes', () async {
      await _expectChanged(
        _request(),
        _request(scheduleId: 'task-43-reminder'),
      );
    });

    test('changes when owner type changes', () async {
      await _expectChanged(
        _request(),
        _request(ownerType: NotificationOwnerType.habit),
      );
    });

    test('changes when owner id changes', () async {
      await _expectChanged(_request(), _request(ownerId: 'task-43'));
    });

    test('changes when title changes', () async {
      await _expectChanged(_request(), _request(title: 'Pay electricity'));
    });

    test('changes when body changes', () async {
      await _expectChanged(_request(), _request(body: 'Due tomorrow'));
    });

    test('changes when scheduled UTC time changes', () async {
      await _expectChanged(
        _request(),
        _request(scheduledAtUtc: DateTime.parse('2026-07-30T05:31:00.000Z')),
      );
    });

    test('changes when privacy mode changes', () async {
      await _expectChanged(
        _request(),
        _request(privacyMode: NotificationPrivacyMode.private),
      );
    });

    test('changes when a payload key changes', () async {
      await _expectChanged(
        _request(),
        _request(payload: const <String, String>{'b': '1', 'z': '9'}),
      );
    });

    test('changes when a payload value changes', () async {
      await _expectChanged(
        _request(),
        _request(payload: const <String, String>{'a': '2', 'z': '9'}),
      );
    });

    test('changes when delivery command schema version changes', () async {
      final request = _request();
      final first = LinuxNotificationRequestFingerprint(
        deliveryCommandSchemaVersion: 1,
      );
      final second = LinuxNotificationRequestFingerprint(
        deliveryCommandSchemaVersion: 2,
      );

      expect(
        await first.compute(request),
        isNot(await second.compute(request)),
      );
    });

    for (final version in <int>[0, -1, -99]) {
      test('rejects invalid delivery command schema version $version', () {
        expect(
          () => LinuxNotificationRequestFingerprint(
            deliveryCommandSchemaVersion: version,
          ),
          throwsArgumentError,
        );
      });
    }
  });
}

NotificationRequest _request({
  String scheduleId = 'task-42-reminder',
  NotificationOwnerType ownerType = NotificationOwnerType.task,
  String ownerId = 'task-42',
  String title = 'Pay rent',
  String body = 'Due today',
  DateTime? scheduledAtUtc,
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
  Map<String, String> payload = const <String, String>{'z': '9', 'a': '1'},
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(type: ownerType, id: ownerId),
    title: title,
    body: body,
    scheduledAtUtc:
        scheduledAtUtc ?? DateTime.parse('2026-07-30T05:30:00.000Z'),
    privacyMode: privacyMode,
    payload: payload,
  );
}

Future<void> _expectChanged(
  NotificationRequest first,
  NotificationRequest second,
) async {
  final fingerprint = LinuxNotificationRequestFingerprint();

  expect(
    await fingerprint.compute(first),
    isNot(await fingerprint.compute(second)),
  );
}
