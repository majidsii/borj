import 'dart:convert';

import 'package:borj/app/bootstrap/application_entrypoint.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/device_time_zone_source.dart';
import 'package:borj/core/notifications/drift_notification_schedule_repository.dart';
import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_executable_path_source.dart';
import 'package:borj/core/notifications/linux_notification_delivery_invocation.dart';
import 'package:borj/core/notifications/linux_notification_delivery_service.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_file_store.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/local_notifications_driver.dart';
import 'package:borj/core/notifications/local_notifications_initializer.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/noop_notification_scheduler.dart';
import 'package:borj/core/notifications/notification_coordinator.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_payload_codec.dart';
import 'package:borj/core/notifications/notification_platform_capabilities.dart';
import 'package:borj/core/notifications/notification_platform_providers.dart'
    as notification_platform;
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';
import 'package:borj/core/notifications/notification_startup_service.dart';
import 'package:borj/core/notifications/notification_time_zone_initializer.dart';
import 'package:borj/core/notifications/resolved_linux_notification_delivery_command_factory.dart';
import 'package:borj/core/notifications/stable_notification_id.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';
import '../../support/recording_native_notification_gateway.dart';

void main() {
  final nowUtc = DateTime.utc(2026, 8, 2, 10);

  test('persisted Linux schedule renders a minimal command and hidden delivery '
      'displays the exact stored request without normal startup', () async {
    final database = _openDatabase();
    addTearDown(database.close);

    final repository = DriftNotificationScheduleRepository(
      database,
      clock: FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
    );
    final recordingRepository = _RecordingRepository(repository);
    final gateway = RecordingNativeNotificationGateway();
    final fileSystem = FakeLinuxSystemdFileSystem();
    final processRunner = _ControlledSystemctlRunner();
    final scheduler = _buildScheduler(
      nowUtc: nowUtc,
      gateway: gateway,
      fileSystem: fileSystem,
      processRunner: processRunner,
    );
    final request = _privateRequest(
      scheduleId: 'pipeline-private-reminder',
      scheduledAtUtc: nowUtc.add(const Duration(hours: 2)),
    );

    await repository.upsert(request);
    await scheduler.schedule(request);

    final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
    final servicePath = '/integration/systemd/user/${names.serviceFileName}';
    final serviceContents = fileSystem.textOf(servicePath);
    final execStart = serviceContents
        .split('\n')
        .singleWhere((line) => line.startsWith('ExecStart='));

    expect(
      execStart,
      'ExecStart="/opt/borj/bin/borj" '
      '"$linuxNotificationDeliveryFlag" "${request.scheduleId}"',
    );
    expect(execStart, isNot(contains(request.title)));
    expect(execStart, isNot(contains(request.body)));
    expect(execStart, isNot(contains('/tasks/private')));
    expect(
      processRunner.requests.every((call) => call.executable == 'systemctl'),
      isTrue,
    );

    final normalRunner = _NormalApplicationSentinel();
    final exitCodes = _ExitCodeSink();
    final resources = _SharedResources(
      repository: recordingRepository,
      gateway: gateway,
    );
    final entrypoint = ApplicationEntrypoint(
      invocationParser: LinuxNotificationDeliveryInvocation.parse,
      deliveryService: LinuxNotificationDeliveryService(
        resourcesFactory: _SharedResourcesFactory(resources),
      ),
      normalApplicationRunner: normalRunner,
      exitCodeSink: exitCodes,
    );

    await entrypoint.run(<String>[
      linuxNotificationDeliveryFlag,
      request.scheduleId,
    ]);

    expect(recordingRepository.lookups, <String>[request.scheduleId]);
    expect(exitCodes.values, <int>[0]);
    expect(resources.closeCalls, 1);
    expect(normalRunner.runCalls, 0);
    expect(normalRunner.dashboardBuilds, 0);
    expect(normalRunner.routerStarts, 0);
    expect(normalRunner.startupReconciliations, 0);

    final displayCalls = gateway.calls
        .where((call) => call.kind == 'showNow')
        .toList(growable: false);
    expect(displayCalls, hasLength(1));

    final display = displayCalls.single;
    expect(display.id, StableNotificationId.fromScheduleId(request.scheduleId));
    expect(display.title, 'برج');
    expect(display.body, 'یک یادآور جدید دارید.');

    final payload = NotificationPayloadCodec.decode(display.payload!);
    expect(payload.scheduleId, request.scheduleId);
    expect(payload.owner, request.owner);
    expect(payload.values, request.payload);

    final persisted = await repository.getById(request.scheduleId);
    expect(persisted, isNotNull);
    expect(persisted!.scheduleId, request.scheduleId);
    expect(persisted.owner, request.owner);
    expect(persisted.title, request.title);
    expect(persisted.body, request.body);
    expect(persisted.scheduledAtUtc, request.scheduledAtUtc);
    expect(persisted.payload, request.payload);
    expect(persisted.privacyMode, NotificationPrivacyMode.private);
  });

  test(
    'missing hidden request exits zero without display or normal startup',
    () async {
      final database = _openDatabase();
      addTearDown(database.close);

      final repository = _RecordingRepository(
        DriftNotificationScheduleRepository(
          database,
          clock: FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
        ),
      );
      final gateway = RecordingNativeNotificationGateway();
      final resources = _SharedResources(
        repository: repository,
        gateway: gateway,
      );
      final normalRunner = _NormalApplicationSentinel();
      final exitCodes = _ExitCodeSink();
      final entrypoint = ApplicationEntrypoint(
        invocationParser: LinuxNotificationDeliveryInvocation.parse,
        deliveryService: LinuxNotificationDeliveryService(
          resourcesFactory: _SharedResourcesFactory(resources),
        ),
        normalApplicationRunner: normalRunner,
        exitCodeSink: exitCodes,
      );

      await entrypoint.run(const <String>[
        linuxNotificationDeliveryFlag,
        'missing-persisted-schedule',
      ]);

      expect(repository.lookups, <String>['missing-persisted-schedule']);
      expect(exitCodes.values, <int>[0]);
      expect(gateway.calls, isEmpty);
      expect(resources.closeCalls, 1);
      expect(normalRunner.runCalls, 0);
    },
  );

  test(
    'unsupported provider selection never constructs Linux dependencies',
    () {
      var linuxConstructionCount = 0;
      final container = ProviderContainer(
        overrides: <Override>[
          notification_platform.notificationHostPlatformProvider
              .overrideWithValue(NotificationHostPlatform.unsupported),
          notification_platform.linuxSystemdNotificationSchedulerProvider
              .overrideWith((ref) {
                linuxConstructionCount += 1;
                throw StateError(
                  'Linux dependencies must stay lazy off Linux.',
                );
              }),
        ],
      );
      addTearDown(container.dispose);

      final scheduler = container.read(
        notification_platform.notificationSchedulerProvider,
      );

      expect(scheduler, isA<NoopNotificationScheduler>());
      expect(linuxConstructionCount, 0);
    },
  );

  test('startup reconciliation reads the same persisted request once and '
      'shares one provider-scope future', () async {
    final database = _openDatabase();
    addTearDown(database.close);

    final repository = DriftNotificationScheduleRepository(
      database,
      clock: FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
    );
    final request = _privateRequest(
      scheduleId: 'pipeline-startup-reminder',
      scheduledAtUtc: nowUtc.add(const Duration(hours: 4)),
    );
    await repository.upsert(request);

    final scheduler = _RecordingScheduler();
    final driver = _RecordingLocalNotificationsDriver();
    final startup = NotificationStartupService(
      enabled: true,
      initializer: LocalNotificationsInitializer(
        timeZoneInitializer: NotificationTimeZoneInitializer(
          source: const _UtcTimeZoneSource(),
          runtime: _UtcTimeZoneRuntime(),
        ),
        driver: driver,
      ),
      coordinator: NotificationCoordinator(
        repository: repository,
        scheduler: scheduler,
      ),
    );
    final startupProvider = Provider<NotificationStartup>((ref) => startup);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.read(
      notification_platform.notificationStartupProvider(startupProvider).future,
    );
    final second = container.read(
      notification_platform.notificationStartupProvider(startupProvider).future,
    );

    expect(identical(first, second), isTrue);

    await Future.wait<void>(<Future<void>>[first, second]);

    expect(driver.initializeCalls, 1);
    expect(scheduler.reconcileCalls, 1);
    expect(scheduler.reconciled, hasLength(1));

    final reconciled = scheduler.reconciled.single;
    expect(reconciled.scheduleId, request.scheduleId);
    expect(reconciled.owner, request.owner);
    expect(reconciled.title, request.title);
    expect(reconciled.body, request.body);
    expect(reconciled.scheduledAtUtc, request.scheduledAtUtc);
    expect(reconciled.payload, request.payload);
    expect(reconciled.privacyMode, request.privacyMode);
  });
}

AppDatabase _openDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

LinuxSystemdNotificationScheduler _buildScheduler({
  required DateTime nowUtc,
  required NativeNotificationGateway gateway,
  required FakeLinuxSystemdFileSystem fileSystem,
  required LinuxProcessRunner processRunner,
}) {
  final pathResolver = LinuxSystemdUserUnitPathResolver(
    const _MapEnvironment(<String, String>{'XDG_CONFIG_HOME': '/integration'}),
  );
  var transactionSequence = 0;

  String nextTransactionId() {
    transactionSequence += 1;
    return 'integration-$transactionSequence';
  }

  return LinuxSystemdNotificationScheduler(
    clock: FixedAppClock(utcValue: nowUtc, localValue: nowUtc),
    gateway: gateway,
    commandFactory: ResolvedLinuxNotificationDeliveryCommandFactory(
      executablePathSource: const _FixedExecutablePathSource(
        '/opt/borj/bin/borj',
      ),
    ),
    renderer: const LinuxSystemdUnitRenderer(),
    unitStore: LinuxSystemdUserUnitStore(
      pathResolver: pathResolver,
      fileSystem: fileSystem,
      transactionIdFactory: nextTransactionId,
    ),
    driver: LinuxSystemdUserDriver(processRunner: processRunner),
    registryStore: LinuxSystemdScheduleRegistryFileStore(
      pathResolver: pathResolver,
      fileSystem: fileSystem,
      codec: const LinuxSystemdScheduleRegistryCodec(),
      transactionIdFactory: nextTransactionId,
    ),
    fingerprint: LinuxNotificationRequestFingerprint(),
  );
}

NotificationRequest _privateRequest({
  required String scheduleId,
  required DateTime scheduledAtUtc,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'private-task-42',
    ),
    title: 'PRIVATE_ACCOUNT_BALANCE',
    body: 'PRIVATE_BODY_WITH_SENSITIVE_CONTEXT',
    scheduledAtUtc: scheduledAtUtc,
    payload: const <String, String>{
      'route': '/tasks/private',
      'source': 'integration',
      'token': 'PRIVATE_PAYLOAD_TOKEN',
    },
    privacyMode: NotificationPrivacyMode.private,
  );
}

final class _FixedExecutablePathSource implements LinuxExecutablePathSource {
  const _FixedExecutablePathSource(this.path);

  final String path;

  @override
  Future<String> resolve() async => path;
}

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}

final class _ControlledSystemctlRunner implements LinuxProcessRunner {
  final Set<String> _enabledBaseNames = <String>{};
  final List<LinuxProcessRequest> requests = <LinuxProcessRequest>[];

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    requests.add(request);
    final arguments = request.arguments;

    if (arguments.contains('daemon-reload')) {
      return _result(request);
    }

    final timerName = arguments.firstWhere(
      (argument) => argument.endsWith('.timer'),
      orElse: () => 'borj-notification-0000000000000000.timer',
    );
    final baseName = timerName.substring(0, timerName.length - '.timer'.length);

    if (arguments.contains('enable')) {
      _enabledBaseNames.add(baseName);
      return _result(request);
    }

    if (arguments.contains('disable')) {
      _enabledBaseNames.remove(baseName);
      return _result(request);
    }

    if (arguments.contains('show')) {
      final healthy = _enabledBaseNames.contains(baseName);
      return _result(
        request,
        stdout: <String>[
          'Id=$timerName',
          'LoadState=loaded',
          'ActiveState=${healthy ? 'active' : 'inactive'}',
          'SubState=${healthy ? 'waiting' : 'dead'}',
          'UnitFileState=${healthy ? 'enabled' : 'disabled'}',
          'Result=success',
          '',
        ].join('\n'),
      );
    }

    return _result(request);
  }

  LinuxProcessResult _result(
    LinuxProcessRequest request, {
    int exitCode = 0,
    String stdout = '',
  }) {
    return LinuxProcessResult(
      executable: request.executable,
      arguments: request.arguments,
      pid: 1068,
      exitCode: exitCode,
      duration: const Duration(milliseconds: 1),
      stdout: _output(stdout),
      stderr: _output(''),
    );
  }

  LinuxBoundedOutput _output(String text) {
    final bytes = utf8.encode(text);
    return LinuxBoundedOutput(
      text: text,
      totalBytes: bytes.length,
      retainedBytes: bytes.length,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    );
  }
}

final class _RecordingRepository implements NotificationScheduleRepository {
  _RecordingRepository(this.delegate);

  final NotificationScheduleRepository delegate;
  final List<String> lookups = <String>[];

  @override
  Future<NotificationRequest?> getById(String scheduleId) {
    lookups.add(scheduleId);
    return delegate.getById(scheduleId);
  }

  @override
  Future<List<NotificationRequest>> getAll() => delegate.getAll();

  @override
  Stream<List<NotificationRequest>> watchAll() => delegate.watchAll();

  @override
  Future<void> upsert(NotificationRequest request) {
    return delegate.upsert(request);
  }

  @override
  Future<void> delete(String scheduleId) {
    return delegate.delete(scheduleId);
  }

  @override
  Future<void> deleteByOwner(NotificationOwner owner) {
    return delegate.deleteByOwner(owner);
  }

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) {
    return delegate.replaceAll(expected);
  }
}

final class _SharedResourcesFactory
    implements LinuxNotificationDeliveryResourcesFactory {
  const _SharedResourcesFactory(this.resources);

  final LinuxNotificationDeliveryResources resources;

  @override
  Future<LinuxNotificationDeliveryResources> open() async => resources;
}

final class _SharedResources implements LinuxNotificationDeliveryResources {
  _SharedResources({required this.repository, required this.gateway});

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

final class _NormalApplicationSentinel implements NormalApplicationRunner {
  int runCalls = 0;
  int dashboardBuilds = 0;
  int routerStarts = 0;
  int startupReconciliations = 0;

  @override
  Future<void> run() async {
    runCalls += 1;
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

final class _RecordingScheduler implements NotificationScheduler {
  int reconcileCalls = 0;
  List<NotificationRequest> reconciled = const <NotificationRequest>[];

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {
    reconcileCalls += 1;
    reconciled = List<NotificationRequest>.unmodifiable(expected);
  }

  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<void> cancel(String scheduleId) async {}

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {}
}

final class _RecordingLocalNotificationsDriver
    implements LocalNotificationsDriver {
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }
}

final class _UtcTimeZoneSource implements DeviceTimeZoneSource {
  const _UtcTimeZoneSource();

  @override
  Future<String> localTimeZoneName() async => 'Etc/UTC';
}

final class _UtcTimeZoneRuntime implements NotificationTimeZoneRuntime {
  bool initialized = false;

  @override
  void initializeDatabase() {
    initialized = true;
  }

  @override
  bool selectLocation(String name) {
    return initialized && name == 'Etc/UTC';
  }
}
