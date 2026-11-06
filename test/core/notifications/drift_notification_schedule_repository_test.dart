import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/drift_notification_schedule_repository.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  test('upsert round-trips a request and preserves created time', () async {
    final database = openTestDatabase();
    final firstTime = DateTime.utc(2026, 7, 27, 8);
    final secondTime = DateTime.utc(2026, 7, 27, 9);

    try {
      final firstRepository = DriftNotificationScheduleRepository(
        database,
        clock: FixedAppClock(utcValue: firstTime, localValue: firstTime),
      );

      await firstRepository.upsert(
        _request(
          scheduleId: 'task-1-reminder',
          owner: _taskOwner,
          title: 'عنوان اولیه',
          hour: 10,
          payload: const <String, String>{
            'route': '/tasks/task-1',
            'source': 'task',
          },
          privacyMode: NotificationPrivacyMode.private,
        ),
      );

      final secondRepository = DriftNotificationScheduleRepository(
        database,
        clock: FixedAppClock(utcValue: secondTime, localValue: secondTime),
      );

      await secondRepository.upsert(
        _request(
          scheduleId: 'task-1-reminder',
          owner: _taskOwner,
          title: 'عنوان جدید',
          hour: 11,
          payload: const <String, String>{'route': '/tasks/task-1'},
          privacyMode: NotificationPrivacyMode.private,
        ),
      );

      final requests = await secondRepository.getAll();
      expect(requests, hasLength(1));
      expect(requests.single.scheduleId, 'task-1-reminder');
      expect(requests.single.title, 'عنوان جدید');
      expect(requests.single.scheduledAtUtc, DateTime.utc(2026, 7, 27, 11));
      expect(requests.single.owner, _taskOwner);
      expect(requests.single.payload, const <String, String>{
        'route': '/tasks/task-1',
      });
      expect(requests.single.privacyMode, NotificationPrivacyMode.private);

      final storedRow = await database
          .select(database.notificationScheduleRows)
          .getSingle();
      expect(storedRow.createdAtUtc.toUtc(), firstTime);
      expect(storedRow.updatedAtUtc.toUtc(), secondTime);
    } finally {
      await database.close();
    }
  });

  test('getById uses exact ID and maps the complete request', () async {
    final database = openTestDatabase();
    final now = DateTime.utc(2026, 8, 2, 8);
    final repository = DriftNotificationScheduleRepository(
      database,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );
    final request = _request(
      scheduleId: 'task-exact',
      owner: _habitOwner,
      title: 'عنوان دقیق',
      hour: 14,
      payload: const <String, String>{
        'route': '/habits/habit-1',
        'source': 'hidden-delivery',
      },
      privacyMode: NotificationPrivacyMode.private,
    );

    try {
      await repository.upsert(request);

      final actual = await repository.getById('task-exact');

      expect(actual, isNotNull);
      expect(actual!.scheduleId, request.scheduleId);
      expect(actual.owner, request.owner);
      expect(actual.title, request.title);
      expect(actual.body, request.body);
      expect(actual.scheduledAtUtc, request.scheduledAtUtc);
      expect(actual.payload, request.payload);
      expect(actual.privacyMode, request.privacyMode);

      expect(await repository.getById('TASK-EXACT'), isNull);
      expect(await repository.getById('task-exact '), isNull);
      expect(await repository.getById('missing'), isNull);
    } finally {
      await database.close();
    }
  });

  test('deleteByOwner does not remove another owner schedules', () async {
    final database = openTestDatabase();
    final now = DateTime.utc(2026, 7, 27, 8);
    final repository = DriftNotificationScheduleRepository(
      database,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    try {
      await repository.upsert(
        _request(scheduleId: 'task-a', owner: _taskOwner, hour: 9),
      );
      await repository.upsert(
        _request(scheduleId: 'task-b', owner: _taskOwner, hour: 10),
      );
      await repository.upsert(
        _request(scheduleId: 'habit-a', owner: _habitOwner, hour: 11),
      );

      await repository.deleteByOwner(_taskOwner);

      final remaining = await repository.getAll();
      expect(remaining.map((request) => request.scheduleId), const <String>[
        'habit-a',
      ]);
    } finally {
      await database.close();
    }
  });

  test('replaceAll removes stale rows and is idempotent', () async {
    final database = openTestDatabase();
    final now = DateTime.utc(2026, 7, 27, 8);
    final repository = DriftNotificationScheduleRepository(
      database,
      clock: FixedAppClock(utcValue: now, localValue: now),
    );

    try {
      await repository.upsert(
        _request(scheduleId: 'stale', owner: _taskOwner, hour: 8),
      );
      await repository.upsert(
        _request(
          scheduleId: 'kept',
          owner: _taskOwner,
          title: 'قدیمی',
          hour: 9,
        ),
      );

      final expected = <NotificationRequest>[
        _request(
          scheduleId: 'kept',
          owner: _taskOwner,
          title: 'به‌روزشده',
          hour: 10,
        ),
        _request(scheduleId: 'new', owner: _habitOwner, hour: 11),
      ];

      await repository.replaceAll(expected);
      await repository.replaceAll(expected);

      final stored = await repository.getAll();
      expect(stored.map((request) => request.scheduleId), const <String>[
        'kept',
        'new',
      ]);
      expect(stored.first.title, 'به‌روزشده');
    } finally {
      await database.close();
    }
  });
}

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
  required NotificationOwner owner,
  String title = 'یادآور',
  required int hour,
  Map<String, String> payload = const <String, String>{},
  NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: owner,
    title: title,
    body: 'متن یادآور',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, hour),
    payload: payload,
    privacyMode: privacyMode,
  );
}
