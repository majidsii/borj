// ignore_for_file: prefer_initializing_formals

import 'package:borj/app/bootstrap/linux_notification_delivery_bootstrap.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallbackLinuxNotificationDeliveryBootstrap', () {
    test('opens only binding, repository, and gateway in order', () async {
      final harness = _BootstrapHarness();

      final resources = await harness.bootstrap.open();

      expect(harness.operations, <String>[
        'binding.ensureInitialized',
        'repository.open',
        'gateway.open',
      ]);
      expect(resources.repository, same(harness.repository));
      expect(resources.gateway, same(harness.gateway));
      expect(harness.dashboardBuilds, 0);
      expect(harness.routerStarts, 0);
      expect(harness.startupReconciliations, 0);
    });

    test('resources close gateway and database exactly once', () async {
      final harness = _BootstrapHarness();
      final resources = await harness.bootstrap.open();

      await resources.close();
      await resources.close();

      expect(harness.gatewayCloseCalls, 1);
      expect(harness.repositoryCloseCalls, 1);
      expect(harness.operations, <String>[
        'binding.ensureInitialized',
        'repository.open',
        'gateway.open',
        'gateway.close',
        'repository.close',
      ]);
    });

    test('gateway initialization failure closes opened repository', () async {
      final cause = StateError('PRIVATE_GATEWAY_FAILURE');
      final harness = _BootstrapHarness(gatewayOpenError: cause);

      await expectLater(harness.bootstrap.open(), throwsA(same(cause)));

      expect(harness.repositoryCloseCalls, 1);
      expect(harness.gatewayCloseCalls, 0);
      expect(harness.operations, <String>[
        'binding.ensureInitialized',
        'repository.open',
        'gateway.open',
        'repository.close',
      ]);
    });

    test('repository initialization failure does not create gateway', () async {
      final cause = StateError('PRIVATE_DATABASE_FAILURE');
      final harness = _BootstrapHarness(repositoryOpenError: cause);

      await expectLater(harness.bootstrap.open(), throwsA(same(cause)));

      expect(harness.gatewayOpenCalls, 0);
      expect(harness.repositoryCloseCalls, 0);
    });

    test('close attempts repository after gateway close failure', () async {
      final gatewayCause = StateError('PRIVATE_GATEWAY_CLOSE_FAILURE');
      final harness = _BootstrapHarness(gatewayCloseError: gatewayCause);
      final resources = await harness.bootstrap.open();

      await expectLater(resources.close(), throwsA(same(gatewayCause)));

      expect(harness.gatewayCloseCalls, 1);
      expect(harness.repositoryCloseCalls, 1);
    });
  });
}

final class _BootstrapHarness {
  _BootstrapHarness({
    this.repositoryOpenError,
    this.gatewayOpenError,
    this.gatewayCloseError,
  }) {
    bootstrap = CallbackLinuxNotificationDeliveryBootstrap(
      ensureBindingInitialized: () async {
        operations.add('binding.ensureInitialized');
      },
      openRepository: () async {
        operations.add('repository.open');
        final error = repositoryOpenError;
        if (error != null) {
          throw error;
        }
        return LinuxNotificationDeliveryRepositoryResource(
          repository: repository,
          close: () async {
            repositoryCloseCalls += 1;
            operations.add('repository.close');
          },
        );
      },
      openGateway: () async {
        gatewayOpenCalls += 1;
        operations.add('gateway.open');
        final error = gatewayOpenError;
        if (error != null) {
          throw error;
        }
        return LinuxNotificationDeliveryGatewayResource(
          gateway: gateway,
          close: () async {
            gatewayCloseCalls += 1;
            operations.add('gateway.close');
            final closeError = gatewayCloseError;
            if (closeError != null) {
              throw closeError;
            }
          },
        );
      },
    );
  }

  final Object? repositoryOpenError;
  final Object? gatewayOpenError;
  final Object? gatewayCloseError;
  final List<String> operations = <String>[];
  final _Repository repository = _Repository();
  final _Gateway gateway = _Gateway();

  int repositoryCloseCalls = 0;
  int gatewayOpenCalls = 0;
  int gatewayCloseCalls = 0;
  int dashboardBuilds = 0;
  int routerStarts = 0;
  int startupReconciliations = 0;

  late final CallbackLinuxNotificationDeliveryBootstrap bootstrap;
}

final class _Repository implements NotificationScheduleRepository {
  @override
  Future<NotificationRequest?> getById(String scheduleId) async => null;

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
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {}

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
