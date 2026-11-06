import 'package:borj/core/notifications/linux_systemd_notification_scheduler_exception.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_timer_status.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_notification_delivery_command_factory.dart';

void main() {
  group('LinuxNotificationDeliveryCommandFactory', () {
    test(
      'fake records the exact request and returns the configured unit',
      () async {
        final request = _request();
        final unit = _unit(request);
        final factory = FakeLinuxNotificationDeliveryCommandFactory(
          result: unit,
        );

        final actual = await factory.create(request);

        expect(actual, same(unit));
        expect(factory.requests, hasLength(1));
        expect(factory.requests.single, same(request));
      },
    );

    test('fake preserves the configured failure and stack trace', () async {
      final error = StateError('TOP_SECRET_FACTORY_FAILURE');
      final stackTrace = StackTrace.fromString('factory-stack-marker');
      final factory = FakeLinuxNotificationDeliveryCommandFactory(
        result: _unit(_request()),
        error: error,
        errorStackTrace: stackTrace,
      );

      Object? actualError;
      StackTrace? actualStackTrace;

      try {
        await factory.create(_request());
        fail('Expected factory failure.');
      } catch (caught, caughtStackTrace) {
        actualError = caught;
        actualStackTrace = caughtStackTrace;
      }

      expect(actualError, same(error));
      expect(actualStackTrace.toString(), contains('factory-stack-marker'));
      expect(factory.requests, hasLength(1));
    });
  });

  group('LinuxSystemdNotificationSchedulerOperation', () {
    test('exposes the exact public scheduler operations', () {
      expect(
        LinuxSystemdNotificationSchedulerOperation.values.map(
          (value) => value.name,
        ),
        orderedEquals(<String>[
          'schedule',
          'cancel',
          'cancelByOwner',
          'reconcile',
        ]),
      );
    });
  });

  group('LinuxSystemdNotificationSchedulerFailure', () {
    test('exposes the exact typed scheduler failures', () {
      expect(
        LinuxSystemdNotificationSchedulerFailure.values.map(
          (value) => value.name,
        ),
        orderedEquals(<String>[
          'commandFactoryFailed',
          'renderFailed',
          'unitTransactionFailed',
          'daemonReloadFailed',
          'mutationFailed',
          'registryFailed',
          'rollbackFailed',
          'partialOwnerCancellation',
          'partialReconciliation',
        ]),
      );
    });
  });

  group('LinuxSystemdSchedulerRollbackFailure', () {
    test('retains exact structured rollback evidence', () {
      final error = StateError('TOP_SECRET_ROLLBACK');
      final stackTrace = StackTrace.current;
      final failure = LinuxSystemdSchedulerRollbackFailure(
        step: 'restore-registry',
        error: error,
        stackTrace: stackTrace,
      );

      expect(failure.step, 'restore-registry');
      expect(failure.error, same(error));
      expect(failure.stackTrace, same(stackTrace));
    });
  });

  group('LinuxSystemdNotificationSchedulerException', () {
    test('retains exact metadata without depending on owner equality', () {
      final owner = NotificationOwner(
        type: NotificationOwnerType.task,
        id: 'owner-42',
      );
      final names = LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
      final status = _healthyStatus(names);
      final cause = StateError('TOP_SECRET_CAUSE');
      final causeStackTrace = StackTrace.current;

      final error = LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.schedule,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        scheduleId: 'task-42-reminder',
        owner: owner,
        names: names,
        cause: cause,
        causeStackTrace: causeStackTrace,
        confirmedStatus: status,
      );

      expect(
        error.operation,
        LinuxSystemdNotificationSchedulerOperation.schedule,
      );
      expect(
        error.failure,
        LinuxSystemdNotificationSchedulerFailure.registryFailed,
      );
      expect(error.scheduleId, 'task-42-reminder');
      expect(error.owner, same(owner));
      expect(error.names, same(names));
      expect(error.cause, same(cause));
      expect(error.causeStackTrace, same(causeStackTrace));
      expect(error.confirmedStatus, same(status));
      expect(error.rollbackFailures, isEmpty);
      expect(error.completedScheduleIds, isEmpty);
    });

    test('copies rollback and completed lists into immutable storage', () {
      final rollbackFailures = <LinuxSystemdSchedulerRollbackFailure>[
        LinuxSystemdSchedulerRollbackFailure(
          step: 'restore-units',
          error: StateError('TOP_SECRET_ROLLBACK'),
          stackTrace: StackTrace.current,
        ),
      ];
      final completedScheduleIds = <String>[
        'task-1-reminder',
        'task-2-reminder',
      ];

      final error = LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.cancelByOwner,
        failure:
            LinuxSystemdNotificationSchedulerFailure.partialOwnerCancellation,
        rollbackFailures: rollbackFailures,
        completedScheduleIds: completedScheduleIds,
      );

      rollbackFailures.clear();
      completedScheduleIds.clear();

      expect(error.rollbackFailures, hasLength(1));
      expect(
        error.completedScheduleIds,
        orderedEquals(<String>['task-1-reminder', 'task-2-reminder']),
      );
      expect(
        () => error.rollbackFailures.add(
          LinuxSystemdSchedulerRollbackFailure(
            step: 'unexpected',
            error: StateError('unexpected'),
            stackTrace: StackTrace.current,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => error.completedScheduleIds.add('task-3-reminder'),
        throwsUnsupportedError,
      );
    });

    test('toString includes safe context and excludes nested error text', () {
      final owner = NotificationOwner(
        type: NotificationOwnerType.task,
        id: 'TOP_SECRET_OWNER_ID',
      );
      final names = LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
      final error = LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.schedule,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        scheduleId: 'task-42-reminder',
        owner: owner,
        names: names,
        cause: StateError('TOP_SECRET_CAUSE containing notification body'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: <LinuxSystemdSchedulerRollbackFailure>[
          LinuxSystemdSchedulerRollbackFailure(
            step: 'restore-registry',
            error: StateError(
              'TOP_SECRET_ROLLBACK containing notification body',
            ),
            stackTrace: StackTrace.current,
          ),
        ],
        confirmedStatus: _healthyStatus(names),
        completedScheduleIds: const <String>[
          'task-1-reminder',
          'task-2-reminder',
        ],
      );

      final text = error.toString();

      expect(text, contains('operation=schedule'));
      expect(text, contains('failure=registryFailed'));
      expect(text, contains('scheduleId=task-42-reminder'));
      expect(text, contains('ownerType=task'));
      expect(text, contains('unit=${names.baseName}'));
      expect(text, contains('rollbackFailures=1'));
      expect(text, contains('completedScheduleIds=2'));
      expect(text, contains('confirmedStatus=present'));
      expect(text, isNot(contains('TOP_SECRET_OWNER_ID')));
      expect(text, isNot(contains('TOP_SECRET_CAUSE')));
      expect(text, isNot(contains('TOP_SECRET_ROLLBACK')));
      expect(text, isNot(contains('notification body')));
      expect(text, isNot(contains('cause=')));
    });

    test('toString handles optional metadata without null text', () {
      final error = LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.reconcile,
        failure: LinuxSystemdNotificationSchedulerFailure.partialReconciliation,
      );

      final text = error.toString();

      expect(text, contains('operation=reconcile'));
      expect(text, contains('failure=partialReconciliation'));
      expect(text, contains('rollbackFailures=0'));
      expect(text, contains('completedScheduleIds=0'));
      expect(text, contains('confirmedStatus=none'));
      expect(text, isNot(contains('scheduleId=null')));
      expect(text, isNot(contains('ownerType=null')));
      expect(text, isNot(contains('unit=null')));
    });
  });
}

NotificationRequest _request() {
  return NotificationRequest(
    scheduleId: 'task-42-reminder',
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    title: 'Reminder title',
    body: 'notification body',
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 9),
    payload: const <String, String>{'route': '/tasks/42'},
  );
}

LinuxSystemdNotificationUnit _unit(NotificationRequest request) {
  return LinuxSystemdNotificationUnit(
    scheduleKey: request.scheduleId,
    scheduledAtUtc: request.scheduledAtUtc,
    executablePath: '/opt/borj/borj',
    arguments: <String>['--deliver-notification', request.scheduleId],
  );
}

LinuxSystemdTimerStatus _healthyStatus(LinuxSystemdUnitNames names) {
  return LinuxSystemdTimerStatus(
    name: LinuxSystemdTimerName.parse(names.timerFileName),
    loadState: LinuxSystemdLoadState.loaded,
    activeState: LinuxSystemdActiveState.active,
    subState: LinuxSystemdTimerSubState.waiting,
    unitFileState: LinuxSystemdUnitFileState.enabled,
    result: LinuxSystemdUnitResult.success,
  );
}
