import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_scheduler.dart';

void main() {
  final taskOwner = NotificationOwner(
    type: NotificationOwnerType.task,
    id: 'task-1',
  );
  final habitOwner = NotificationOwner(
    type: NotificationOwnerType.habit,
    id: 'habit-1',
  );

  test(
    'schedule replaces an existing request with the same schedule id',
    () async {
      final scheduler = FakeNotificationScheduler();

      await scheduler.schedule(
        _request(
          scheduleId: 'same-id',
          owner: taskOwner,
          title: 'قدیمی',
          hour: 8,
        ),
      );
      await scheduler.schedule(
        _request(
          scheduleId: 'same-id',
          owner: taskOwner,
          title: 'جدید',
          hour: 9,
        ),
      );

      expect(scheduler.scheduledRequests, hasLength(1));
      expect(scheduler.scheduledRequests.single.title, 'جدید');
      expect(scheduler.scheduledRequests.single.scheduledAtUtc.hour, 9);
    },
  );

  test('cancel removes only the matching schedule id', () async {
    final scheduler = FakeNotificationScheduler();
    await scheduler.schedule(
      _request(scheduleId: 'task-a', owner: taskOwner, hour: 8),
    );
    await scheduler.schedule(
      _request(scheduleId: 'task-b', owner: taskOwner, hour: 9),
    );

    await scheduler.cancel('task-a');

    expect(
      scheduler.scheduledRequests.map((item) => item.scheduleId),
      const <String>['task-b'],
    );
  });

  test('cancelByOwner removes only requests belonging to that owner', () async {
    final scheduler = FakeNotificationScheduler();
    await scheduler.schedule(
      _request(scheduleId: 'task-a', owner: taskOwner, hour: 8),
    );
    await scheduler.schedule(
      _request(scheduleId: 'task-b', owner: taskOwner, hour: 9),
    );
    await scheduler.schedule(
      _request(scheduleId: 'habit-a', owner: habitOwner, hour: 10),
    );

    await scheduler.cancelByOwner(taskOwner);

    expect(
      scheduler.scheduledRequests.map((item) => item.scheduleId),
      const <String>['habit-a'],
    );
  });

  test('reconcile removes stale requests and is idempotent', () async {
    final scheduler = FakeNotificationScheduler();
    await scheduler.schedule(
      _request(scheduleId: 'stale', owner: taskOwner, hour: 7),
    );
    await scheduler.schedule(
      _request(scheduleId: 'kept', owner: taskOwner, title: 'قدیمی', hour: 8),
    );

    final expected = <NotificationRequest>[
      _request(
        scheduleId: 'kept',
        owner: taskOwner,
        title: 'به‌روزشده',
        hour: 9,
      ),
      _request(scheduleId: 'new', owner: habitOwner, hour: 10),
    ];

    await scheduler.reconcile(expected);
    final firstSnapshot = scheduler.scheduledRequests;
    await scheduler.reconcile(expected);

    expect(
      scheduler.scheduledRequests.map((item) => item.scheduleId),
      const <String>['kept', 'new'],
    );
    expect(scheduler.scheduledRequests.first.title, 'به‌روزشده');
    expect(scheduler.scheduledRequests, firstSnapshot);
  });
}

NotificationRequest _request({
  required String scheduleId,
  required NotificationOwner owner,
  String title = 'یادآور',
  required int hour,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: owner,
    title: title,
    body: 'متن یادآور',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, hour),
  );
}
