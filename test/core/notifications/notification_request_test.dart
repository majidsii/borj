import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification request keeps an immutable UTC schedule', () {
    final sourcePayload = <String, String>{'route': '/tasks/task-1'};
    final request = NotificationRequest(
      scheduleId: 'task-1-reminder-0',
      owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-1'),
      title: 'ارسال گزارش',
      body: 'زمان انجام تسک رسیده است.',
      scheduledAtUtc: DateTime.utc(2026, 7, 27, 14, 30),
      payload: sourcePayload,
    );

    sourcePayload['route'] = '/changed';

    expect(request.scheduleId, 'task-1-reminder-0');
    expect(request.owner.id, 'task-1');
    expect(request.scheduledAtUtc.isUtc, isTrue);
    expect(request.payload, const <String, String>{'route': '/tasks/task-1'});
    expect(() => request.payload['new'] = 'value', throwsUnsupportedError);
  });

  test('notification request rejects a non-UTC instant', () {
    expect(
      () => NotificationRequest(
        scheduleId: 'task-1-reminder-0',
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'task-1',
        ),
        title: 'عنوان',
        body: 'متن',
        scheduledAtUtc: DateTime(2026, 7, 27, 14, 30),
      ),
      throwsArgumentError,
    );
  });

  test('notification identifiers and title cannot be blank', () {
    expect(
      () => NotificationRequest(
        scheduleId: '   ',
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'task-1',
        ),
        title: 'عنوان',
        body: 'متن',
        scheduledAtUtc: DateTime.utc(2026, 7, 27),
      ),
      throwsArgumentError,
    );

    expect(
      () => NotificationOwner(type: NotificationOwnerType.habit, id: '   '),
      throwsArgumentError,
    );

    expect(
      () => NotificationRequest(
        scheduleId: 'task-1-reminder-0',
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'task-1',
        ),
        title: '   ',
        body: 'متن',
        scheduledAtUtc: DateTime.utc(2026, 7, 27),
      ),
      throwsArgumentError,
    );
  });
}
