import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_payload_codec.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and decodes notification routing metadata', () {
    final request = NotificationRequest(
      scheduleId: 'task-1-reminder-0',
      owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-1'),
      title: 'ارسال گزارش',
      body: 'زمان انجام تسک رسیده است.',
      scheduledAtUtc: DateTime.utc(2026, 7, 27, 14, 30),
      payload: const <String, String>{
        'route': '/tasks/task-1',
        'source': 'task',
      },
    );

    final encoded = NotificationPayloadCodec.encode(request);
    final decoded = NotificationPayloadCodec.decode(encoded);

    expect(decoded.scheduleId, request.scheduleId);
    expect(decoded.owner, request.owner);
    expect(decoded.values, const <String, String>{
      'route': '/tasks/task-1',
      'source': 'task',
    });
  });

  test(
    'codec output is deterministic regardless of payload insertion order',
    () {
      final first = _request(
        payload: const <String, String>{
          'source': 'task',
          'route': '/tasks/task-1',
        },
      );
      final second = _request(
        payload: const <String, String>{
          'route': '/tasks/task-1',
          'source': 'task',
        },
      );

      expect(
        NotificationPayloadCodec.encode(first),
        NotificationPayloadCodec.encode(second),
      );
    },
  );

  test('decode rejects malformed or incomplete payloads', () {
    expect(
      () => NotificationPayloadCodec.decode('not-json'),
      throwsFormatException,
    );
    expect(
      () => NotificationPayloadCodec.decode('{"version":1,"scheduleId":"x"}'),
      throwsFormatException,
    );
  });
}

NotificationRequest _request({required Map<String, String> payload}) {
  return NotificationRequest(
    scheduleId: 'task-1-reminder-0',
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-1'),
    title: 'عنوان',
    body: 'متن',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, 14, 30),
    payload: payload,
  );
}
