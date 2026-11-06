// ignore_for_file: prefer_initializing_formals

import 'package:borj/app/bootstrap/application_entrypoint.dart';
import 'package:borj/core/notifications/linux_notification_delivery_invocation.dart';
import 'package:borj/core/notifications/linux_notification_delivery_service.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplicationEntrypoint', () {
    test(
      'normal arguments run the existing application exactly once',
      () async {
        final harness = _Harness(request: _request());

        await harness.entrypoint.run(const <String>['--route', '/dashboard']);

        expect(harness.normalRunner.runCalls, 1);
        expect(harness.resourcesOpenCalls, 0);
        expect(harness.exitCodeSink.values, isEmpty);
      },
    );

    test('valid hidden command never starts the normal application', () async {
      final harness = _Harness(request: _request());

      await harness.entrypoint.run(const <String>[
        '--deliver-notification',
        'task-exact',
      ]);

      expect(harness.normalRunner.runCalls, 0);
      expect(harness.resourcesOpenCalls, 1);
      expect(harness.gateway.showCalls, 1);
      expect(harness.exitCodeSink.values, <int>[0]);
    });

    test(
      'invalid hidden command never starts UI and sets non-zero exit',
      () async {
        final harness = _Harness(request: _request());

        await harness.entrypoint.run(const <String>['--deliver-notification']);

        expect(harness.normalRunner.runCalls, 0);
        expect(harness.resourcesOpenCalls, 0);
        expect(harness.exitCodeSink.values, hasLength(1));
        expect(harness.exitCodeSink.values.single, isNot(0));
      },
    );

    test(
      'missing persisted request remains a successful hidden exit',
      () async {
        final harness = _Harness(request: null);

        await harness.entrypoint.run(const <String>[
          '--deliver-notification',
          'stale-timer',
        ]);

        expect(harness.normalRunner.runCalls, 0);
        expect(harness.gateway.showCalls, 0);
        expect(harness.exitCodeSink.values, <int>[0]);
        expect(harness.resources.closeCalls, 1);
      },
    );

    test('typed delivery failure does not escape the entrypoint', () async {
      final harness = _Harness(
        request: _request(),
        displayError: StateError('PRIVATE_DISPLAY_FAILURE'),
      );

      await expectLater(
        harness.entrypoint.run(const <String>[
          '--deliver-notification',
          'task-exact',
        ]),
        completes,
      );

      expect(harness.normalRunner.runCalls, 0);
      expect(harness.exitCodeSink.values.single, isNot(0));
      expect(harness.resources.closeCalls, 1);
    });

    test(
      'unexpected delivery exception is converted to non-zero exit',
      () async {
        final harness = _Harness(
          request: _request(),
          resourcesFactory: _ThrowingResourcesFactory(
            StateError('PRIVATE_UNEXPECTED_FAILURE'),
          ),
        );

        await expectLater(
          harness.entrypoint.run(const <String>[
            '--deliver-notification',
            'task-exact',
          ]),
          completes,
        );

        expect(harness.normalRunner.runCalls, 0);
        expect(harness.exitCodeSink.values.single, isNot(0));
      },
    );

    test(
      'hidden mode never invokes dashboard, router, or startup sentinels',
      () async {
        final harness = _Harness(request: _request());

        await harness.entrypoint.run(const <String>[
          '--deliver-notification',
          'task-exact',
        ]);

        expect(harness.normalRunner.dashboardBuilds, 0);
        expect(harness.normalRunner.routerStarts, 0);
        expect(harness.normalRunner.startupReconciliations, 0);
      },
    );

    test(
      'normal runner failure is not mislabeled as hidden delivery',
      () async {
        final cause = StateError('normal startup failure');
        final harness = _Harness(request: _request(), normalError: cause);

        await expectLater(
          harness.entrypoint.run(const <String>[]),
          throwsA(same(cause)),
        );

        expect(harness.exitCodeSink.values, isEmpty);
        expect(harness.resourcesOpenCalls, 0);
      },
    );
  });
}

NotificationRequest _request() {
  return NotificationRequest(
    scheduleId: 'task-exact',
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'task-owner',
    ),
    title: 'Task title',
    body: 'Task body',
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 12),
    payload: const <String, String>{'route': '/tasks/task-exact'},
  );
}

final class _Harness {
  _Harness({
    required NotificationRequest? request,
    Object? displayError,
    Object? normalError,
    LinuxNotificationDeliveryResourcesFactory? resourcesFactory,
  }) {
    repository = _Repository(request);
    gateway = _Gateway(displayError);
    resources = _Resources(repository, gateway);
    this.resourcesFactory = resourcesFactory ?? _ResourcesFactory(resources);
    normalRunner = _NormalRunner(normalError);
    exitCodeSink = _ExitCodeSink();
    entrypoint = ApplicationEntrypoint(
      invocationParser: LinuxNotificationDeliveryInvocation.parse,
      deliveryService: LinuxNotificationDeliveryService(
        resourcesFactory: this.resourcesFactory,
      ),
      normalApplicationRunner: normalRunner,
      exitCodeSink: exitCodeSink,
    );
  }

  late final _Repository repository;
  late final _Gateway gateway;
  late final _Resources resources;
  late final LinuxNotificationDeliveryResourcesFactory resourcesFactory;
  late final _NormalRunner normalRunner;
  late final _ExitCodeSink exitCodeSink;
  late final ApplicationEntrypoint entrypoint;
  int get resourcesOpenCalls {
    final factory = resourcesFactory;
    return switch (factory) {
      _ResourcesFactory(:final openCalls) => openCalls,
      _ThrowingResourcesFactory(:final openCalls) => openCalls,
      _ => 0,
    };
  }
}

final class _NormalRunner implements NormalApplicationRunner {
  _NormalRunner(this.error);

  final Object? error;
  int runCalls = 0;
  int dashboardBuilds = 0;
  int routerStarts = 0;
  int startupReconciliations = 0;

  @override
  Future<void> run() async {
    runCalls += 1;
    final configuredError = error;
    if (configuredError != null) {
      throw configuredError;
    }
    dashboardBuilds += 1;
    routerStarts += 1;
    startupReconciliations += 1;
  }
}

final class _ExitCodeSink implements ProcessExitCodeSink {
  final List<int> values = <int>[];

  @override
  void setExitCode(int value) {
    values.add(value);
  }
}

final class _ResourcesFactory
    implements LinuxNotificationDeliveryResourcesFactory {
  _ResourcesFactory(this.resources);

  final LinuxNotificationDeliveryResources resources;
  int openCalls = 0;

  @override
  Future<LinuxNotificationDeliveryResources> open() async {
    openCalls += 1;
    return resources;
  }
}

final class _ThrowingResourcesFactory
    implements LinuxNotificationDeliveryResourcesFactory {
  _ThrowingResourcesFactory(this.error);

  final Object error;
  int openCalls = 0;

  @override
  Future<LinuxNotificationDeliveryResources> open() async {
    openCalls += 1;
    throw error;
  }
}

final class _Resources implements LinuxNotificationDeliveryResources {
  _Resources(this.repository, this.gateway);

  @override
  final NotificationScheduleRepository repository;

  @override
  final NativeNotificationGateway gateway;

  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls += 1;
  }
}

final class _Repository implements NotificationScheduleRepository {
  _Repository(this.request);

  final NotificationRequest? request;

  @override
  Future<NotificationRequest?> getById(String scheduleId) async => request;

  @override
  Future<List<NotificationRequest>> getAll() async =>
      const <NotificationRequest>[];

  @override
  Stream<List<NotificationRequest>> watchAll() =>
      const Stream<List<NotificationRequest>>.empty();

  @override
  Future<void> upsert(NotificationRequest request) async {}

  @override
  Future<void> delete(String scheduleId) async {}

  @override
  Future<void> deleteByOwner(NotificationOwner owner) async {}

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) async {}
}

final class _Gateway implements NativeNotificationGateway {
  _Gateway(this.displayError);

  final Object? displayError;
  int showCalls = 0;

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    showCalls += 1;
    final configuredError = displayError;
    if (configuredError != null) {
      throw configuredError;
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<NativePendingNotification>> pending() async =>
      const <NativePendingNotification>[];
}
