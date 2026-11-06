import 'package:borj/core/date_time/app_clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart_io_linux_executable_path_source.dart';
import 'dart_io_linux_process_runner.dart';
import 'dart_io_linux_systemd_file_system.dart';
import 'flutter_local_notifications_driver.dart';
import 'linux_executable_path_source.dart';
import 'linux_notification_delivery_command_factory.dart';
import 'linux_notification_request_fingerprint.dart';
import 'linux_process_runner.dart';
import 'linux_systemd_environment.dart';
import 'linux_systemd_file_system.dart';
import 'linux_systemd_notification_scheduler.dart';
import 'linux_systemd_schedule_registry_codec.dart';
import 'linux_systemd_schedule_registry_file_store.dart';
import 'linux_systemd_schedule_registry_store.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_unit_transaction.dart';
import 'linux_systemd_user_driver.dart';
import 'linux_systemd_user_unit_path_resolver.dart';
import 'linux_systemd_user_unit_store.dart';
import 'local_notification_plugin_config.dart';
import 'native_notification_gateway.dart';
import 'noop_notification_scheduler.dart';
import 'notification_host_platform.dart';
import 'notification_platform_capabilities.dart';
import 'notification_scheduler.dart';
import 'notification_startup_service.dart';
import 'platform_notification_scheduler.dart';
import 'resolved_linux_notification_delivery_command_factory.dart';

final notificationHostPlatformProvider = Provider<NotificationHostPlatform>((
  ref,
) {
  return detectNotificationHostPlatform(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );
});

final notificationClockProvider = Provider<AppClock>((ref) {
  return const SystemAppClock();
});

final notificationPlatformCapabilitiesProvider =
    Provider<NotificationPlatformCapabilities>((ref) {
      return NotificationPlatformCapabilities.forPlatform(
        ref.watch(notificationHostPlatformProvider),
      );
    });

final flutterLocalNotificationsDriverProvider =
    Provider<FlutterLocalNotificationsDriver>((ref) {
      return FlutterLocalNotificationsDriver(
        config: const LocalNotificationPluginConfig.defaults(),
        hostPlatform: ref.watch(notificationHostPlatformProvider),
      );
    });

final nativeNotificationGatewayProvider = Provider<NativeNotificationGateway>((
  ref,
) {
  return ref.watch(flutterLocalNotificationsDriverProvider);
});

final platformNotificationSchedulerProvider =
    Provider<PlatformNotificationScheduler>((ref) {
      return PlatformNotificationScheduler(
        gateway: ref.watch(nativeNotificationGatewayProvider),
        capabilities: ref.watch(notificationPlatformCapabilitiesProvider),
        clock: ref.watch(notificationClockProvider),
      );
    });

final noopNotificationSchedulerProvider = Provider<NoopNotificationScheduler>((
  ref,
) {
  return const NoopNotificationScheduler();
});

final linuxExecutablePathSourceProvider = Provider<LinuxExecutablePathSource>((
  ref,
) {
  return const ValidatedLinuxExecutablePathSource(
    source: DartIoLinuxExecutablePathSource(),
    verifier: DartIoLinuxExecutableFileVerifier(),
  );
});

final linuxNotificationDeliveryCommandFactoryProvider =
    Provider<LinuxNotificationDeliveryCommandFactory>((ref) {
      return ResolvedLinuxNotificationDeliveryCommandFactory(
        executablePathSource: ref.watch(linuxExecutablePathSourceProvider),
      );
    });

final linuxSystemdEnvironmentProvider = Provider<LinuxSystemdEnvironment>((
  ref,
) {
  return const PlatformLinuxSystemdEnvironment();
});

final linuxSystemdUserUnitPathResolverProvider =
    Provider<LinuxSystemdUserUnitPathResolver>((ref) {
      return LinuxSystemdUserUnitPathResolver(
        ref.watch(linuxSystemdEnvironmentProvider),
      );
    });

final linuxSystemdFileSystemProvider = Provider<LinuxSystemdFileSystem>((ref) {
  return const DartIoLinuxSystemdFileSystem();
});

final linuxSystemdScheduleRegistryCodecProvider =
    Provider<LinuxSystemdScheduleRegistryCodec>((ref) {
      return const LinuxSystemdScheduleRegistryCodec();
    });

final linuxSystemdTransactionIdFactoryProvider = Provider<String Function()>((
  ref,
) {
  var sequence = 0;

  return () {
    sequence += 1;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'tx_${micros}_$sequence';
  };
});

final linuxSystemdRegistryStoreProvider =
    Provider<LinuxSystemdScheduleRegistryStore>((ref) {
      return LinuxSystemdScheduleRegistryFileStore(
        pathResolver: ref.watch(linuxSystemdUserUnitPathResolverProvider),
        fileSystem: ref.watch(linuxSystemdFileSystemProvider),
        codec: ref.watch(linuxSystemdScheduleRegistryCodecProvider),
        transactionIdFactory: ref.watch(
          linuxSystemdTransactionIdFactoryProvider,
        ),
      );
    });

final linuxSystemdUnitRendererProvider = Provider<LinuxSystemdUnitRenderer>((
  ref,
) {
  return const LinuxSystemdUnitRenderer();
});

final linuxProcessRunnerProvider = Provider<LinuxProcessRunner>((ref) {
  return DartIoLinuxProcessRunner();
});

final linuxSystemdUserDriverProvider = Provider<LinuxSystemdUserDriver>((ref) {
  return LinuxSystemdUserDriver(
    processRunner: ref.watch(linuxProcessRunnerProvider),
  );
});

final linuxSystemdUnitStoreProvider = Provider<LinuxSystemdUnitStore>((ref) {
  return LinuxSystemdUserUnitStore(
    pathResolver: ref.watch(linuxSystemdUserUnitPathResolverProvider),
    fileSystem: ref.watch(linuxSystemdFileSystemProvider),
    transactionIdFactory: ref.watch(linuxSystemdTransactionIdFactoryProvider),
  );
});

final linuxNotificationRequestFingerprintProvider =
    Provider<LinuxNotificationRequestFingerprint>((ref) {
      return LinuxNotificationRequestFingerprint();
    });

final linuxSystemdNotificationSchedulerProvider =
    Provider<LinuxSystemdNotificationScheduler>((ref) {
      return LinuxSystemdNotificationScheduler(
        clock: ref.watch(notificationClockProvider),
        gateway: ref.watch(nativeNotificationGatewayProvider),
        commandFactory: ref.watch(
          linuxNotificationDeliveryCommandFactoryProvider,
        ),
        renderer: ref.watch(linuxSystemdUnitRendererProvider),
        unitStore: ref.watch(linuxSystemdUnitStoreProvider),
        driver: ref.watch(linuxSystemdUserDriverProvider),
        registryStore: ref.watch(linuxSystemdRegistryStoreProvider),
        fingerprint: ref.watch(linuxNotificationRequestFingerprintProvider),
      );
    });

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return switch (ref.watch(notificationHostPlatformProvider)) {
    NotificationHostPlatform.linux => ref.watch(
      linuxSystemdNotificationSchedulerProvider,
    ),
    NotificationHostPlatform.android ||
    NotificationHostPlatform.macos ||
    NotificationHostPlatform.windows => ref.watch(
      platformNotificationSchedulerProvider,
    ),
    NotificationHostPlatform.unsupported => ref.watch(
      noopNotificationSchedulerProvider,
    ),
  };
});

final notificationStartupProvider =
    FutureProvider.family<void, ProviderListenable<NotificationStartup>>((
      ref,
      startupProvider,
    ) async {
      await ref.watch(startupProvider).initialize();
    });
