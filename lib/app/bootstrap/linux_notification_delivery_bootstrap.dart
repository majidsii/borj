// ignore_for_file: prefer_initializing_formals

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/notifications/drift_notification_schedule_repository.dart';
import 'package:borj/core/notifications/flutter_local_notifications_driver.dart';
import 'package:borj/core/notifications/linux_notification_delivery_service.dart';
import 'package:borj/core/notifications/local_notification_plugin_config.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:flutter/widgets.dart';

typedef LinuxNotificationBindingInitializer = Future<void> Function();
typedef LinuxNotificationRepositoryOpener =
    Future<LinuxNotificationDeliveryRepositoryResource> Function();
typedef LinuxNotificationGatewayOpener =
    Future<LinuxNotificationDeliveryGatewayResource> Function();

abstract interface class LinuxNotificationDeliveryBootstrap
    implements LinuxNotificationDeliveryResourcesFactory {}

final class LinuxNotificationDeliveryRepositoryResource {
  const LinuxNotificationDeliveryRepositoryResource({
    required this.repository,
    required this.close,
  });

  final NotificationScheduleRepository repository;
  final Future<void> Function() close;
}

final class LinuxNotificationDeliveryGatewayResource {
  const LinuxNotificationDeliveryGatewayResource({
    required this.gateway,
    required this.close,
  });

  final NativeNotificationGateway gateway;
  final Future<void> Function() close;
}

final class CallbackLinuxNotificationDeliveryBootstrap
    implements LinuxNotificationDeliveryBootstrap {
  const CallbackLinuxNotificationDeliveryBootstrap({
    required LinuxNotificationBindingInitializer ensureBindingInitialized,
    required LinuxNotificationRepositoryOpener openRepository,
    required LinuxNotificationGatewayOpener openGateway,
  }) : _ensureBindingInitialized = ensureBindingInitialized,
       _openRepository = openRepository,
       _openGateway = openGateway;

  final LinuxNotificationBindingInitializer _ensureBindingInitialized;
  final LinuxNotificationRepositoryOpener _openRepository;
  final LinuxNotificationGatewayOpener _openGateway;

  @override
  Future<LinuxNotificationDeliveryResources> open() async {
    await _ensureBindingInitialized();
    final repositoryResource = await _openRepository();

    final LinuxNotificationDeliveryGatewayResource gatewayResource;
    try {
      gatewayResource = await _openGateway();
    } catch (error, stackTrace) {
      try {
        await repositoryResource.close();
      } catch (_) {
        // Initialization failure remains primary.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _OpenedLinuxNotificationDeliveryResources(
      repositoryResource: repositoryResource,
      gatewayResource: gatewayResource,
    );
  }
}

final class ProductionLinuxNotificationDeliveryBootstrap
    implements LinuxNotificationDeliveryBootstrap {
  ProductionLinuxNotificationDeliveryBootstrap()
    : _delegate = CallbackLinuxNotificationDeliveryBootstrap(
        ensureBindingInitialized: () async {
          WidgetsFlutterBinding.ensureInitialized();
        },
        openRepository: () async {
          final database = AppDatabase();
          return LinuxNotificationDeliveryRepositoryResource(
            repository: DriftNotificationScheduleRepository(database),
            close: database.close,
          );
        },
        openGateway: () async {
          final driver = FlutterLocalNotificationsDriver(
            config: const LocalNotificationPluginConfig.defaults(),
            hostPlatform: NotificationHostPlatform.linux,
          );
          await driver.initialize();

          return LinuxNotificationDeliveryGatewayResource(
            gateway: driver,
            close: _noOpClose,
          );
        },
      );

  final CallbackLinuxNotificationDeliveryBootstrap _delegate;

  @override
  Future<LinuxNotificationDeliveryResources> open() => _delegate.open();

  static Future<void> _noOpClose() async {}
}

final class _OpenedLinuxNotificationDeliveryResources
    implements LinuxNotificationDeliveryResources {
  _OpenedLinuxNotificationDeliveryResources({
    required LinuxNotificationDeliveryRepositoryResource repositoryResource,
    required LinuxNotificationDeliveryGatewayResource gatewayResource,
  }) : repository = repositoryResource.repository,
       gateway = gatewayResource.gateway,
       _repositoryClose = repositoryResource.close,
       _gatewayClose = gatewayResource.close;

  @override
  final NotificationScheduleRepository repository;

  @override
  final NativeNotificationGateway gateway;

  final Future<void> Function() _repositoryClose;
  final Future<void> Function() _gatewayClose;

  Future<void>? _closeFuture;

  @override
  Future<void> close() {
    return _closeFuture ??= _close();
  }

  Future<void> _close() async {
    Object? primaryError;
    StackTrace? primaryStackTrace;

    try {
      await _gatewayClose();
    } catch (error, stackTrace) {
      primaryError = error;
      primaryStackTrace = stackTrace;
    }

    try {
      await _repositoryClose();
    } catch (error, stackTrace) {
      primaryError ??= error;
      primaryStackTrace ??= stackTrace;
    }

    final error = primaryError;
    if (error != null) {
      Error.throwWithStackTrace(error, primaryStackTrace ?? StackTrace.current);
    }
  }
}
