import 'package:borj/core/notifications/notification_coordinator.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_scheduler.dart';
import '../../support/memory_notification_schedule_repository.dart';

void main() {
  late MemoryNotificationScheduleRepository repository;

  setUp(() {
    repository = MemoryNotificationScheduleRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  test(
    'schedule stores desired state and schedules the platform request',
    () async {
      final scheduler = FakeNotificationScheduler();
      final coordinator = NotificationCoordinator(
        repository: repository,
        scheduler: scheduler,
      );
      final request = _request(
        scheduleId: 'task-1-reminder',
        owner: _taskOwner,
        hour: 9,
      );

      await coordinator.schedule(request);

      expect(repository.items, hasLength(1));
      expect(repository.items.single.scheduleId, request.scheduleId);
      expect(scheduler.scheduledRequests, hasLength(1));
      expect(scheduler.scheduledRequests.single.scheduleId, request.scheduleId);
    },
  );

  test('schedule keeps desired state when platform scheduling fails', () async {
    final coordinator = NotificationCoordinator(
      repository: repository,
      scheduler: const _FailingScheduleScheduler(),
    );
    final request = _request(
      scheduleId: 'task-1-reminder',
      owner: _taskOwner,
      hour: 9,
    );

    await expectLater(
      coordinator.schedule(request),
      throwsA(isA<StateError>()),
    );

    expect(repository.items, hasLength(1));
    expect(repository.items.single.scheduleId, request.scheduleId);
  });

  test('cancel removes desired state and platform schedule', () async {
    final scheduler = FakeNotificationScheduler();
    final coordinator = NotificationCoordinator(
      repository: repository,
      scheduler: scheduler,
    );
    final request = _request(
      scheduleId: 'task-1-reminder',
      owner: _taskOwner,
      hour: 9,
    );

    await coordinator.schedule(request);
    await coordinator.cancel(request.scheduleId);

    expect(repository.items, isEmpty);
    expect(scheduler.scheduledRequests, isEmpty);
  });

  test('cancelByOwner leaves schedules belonging to another owner', () async {
    final scheduler = FakeNotificationScheduler();
    final coordinator = NotificationCoordinator(
      repository: repository,
      scheduler: scheduler,
    );

    await coordinator.schedule(
      _request(scheduleId: 'task-a', owner: _taskOwner, hour: 9),
    );
    await coordinator.schedule(
      _request(scheduleId: 'task-b', owner: _taskOwner, hour: 10),
    );
    await coordinator.schedule(
      _request(scheduleId: 'habit-a', owner: _habitOwner, hour: 11),
    );

    await coordinator.cancelByOwner(_taskOwner);

    expect(
      repository.items.map((request) => request.scheduleId),
      const <String>['habit-a'],
    );
    expect(
      scheduler.scheduledRequests.map((request) => request.scheduleId),
      const <String>['habit-a'],
    );
  });

  test(
    'replaceAll persists and reconciles one deduplicated desired set',
    () async {
      final scheduler = FakeNotificationScheduler();
      final coordinator = NotificationCoordinator(
        repository: repository,
        scheduler: scheduler,
      );

      await coordinator.schedule(
        _request(scheduleId: 'stale', owner: _taskOwner, hour: 7),
      );

      await coordinator.replaceAll(<NotificationRequest>[
        _request(
          scheduleId: 'same-id',
          owner: _taskOwner,
          title: 'قدیمی',
          hour: 8,
        ),
        _request(
          scheduleId: 'same-id',
          owner: _taskOwner,
          title: 'نسخه نهایی',
          hour: 9,
        ),
        _request(scheduleId: 'habit-a', owner: _habitOwner, hour: 10),
      ]);

      expect(
        repository.items.map((request) => request.scheduleId),
        const <String>['same-id', 'habit-a'],
      );
      expect(repository.items.first.title, 'نسخه نهایی');
      expect(
        scheduler.scheduledRequests.map((request) => request.scheduleId),
        const <String>['same-id', 'habit-a'],
      );
      expect(scheduler.scheduledRequests.first.title, 'نسخه نهایی');
    },
  );

  test('reconcileFromPersistence repairs stale platform state', () async {
    final scheduler = FakeNotificationScheduler();
    final coordinator = NotificationCoordinator(
      repository: repository,
      scheduler: scheduler,
    );

    await repository.upsert(
      _request(scheduleId: 'persisted-task', owner: _taskOwner, hour: 9),
    );
    await repository.upsert(
      _request(scheduleId: 'persisted-habit', owner: _habitOwner, hour: 10),
    );
    await scheduler.schedule(
      _request(scheduleId: 'stale-platform-item', owner: _taskOwner, hour: 8),
    );

    await coordinator.reconcileFromPersistence();

    expect(
      scheduler.scheduledRequests.map((request) => request.scheduleId),
      const <String>['persisted-task', 'persisted-habit'],
    );
  });

  test(
    'replaceByOwner preserves unrelated owners and rejects mixed input',
    () async {
      final scheduler = FakeNotificationScheduler();
      final coordinator = NotificationCoordinator(
        repository: repository,
        scheduler: scheduler,
      );

      await coordinator.replaceAll(<NotificationRequest>[
        _request(scheduleId: 'task-old', owner: _taskOwner, hour: 8),
        _request(scheduleId: 'habit-a', owner: _habitOwner, hour: 9),
      ]);

      await coordinator.replaceByOwner(_taskOwner, <NotificationRequest>[
        _request(scheduleId: 'task-new', owner: _taskOwner, hour: 10),
      ]);

      expect(
        repository.items.map((request) => request.scheduleId),
        const <String>['habit-a', 'task-new'],
      );
      expect(
        scheduler.scheduledRequests.map((request) => request.scheduleId),
        const <String>['habit-a', 'task-new'],
      );

      await expectLater(
        coordinator.replaceByOwner(_taskOwner, <NotificationRequest>[
          _request(scheduleId: 'wrong-owner', owner: _habitOwner, hour: 11),
        ]),
        throwsArgumentError,
      );
    },
  );
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
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: owner,
    title: title,
    body: 'متن یادآور',
    scheduledAtUtc: DateTime.utc(2026, 7, 27, hour),
  );
}

final class _FailingScheduleScheduler implements NotificationScheduler {
  const _FailingScheduleScheduler();

  @override
  Future<void> schedule(NotificationRequest request) {
    throw StateError('platform scheduling failed');
  }

  @override
  Future<void> cancel(String scheduleId) async {}

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {}

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {}
}
