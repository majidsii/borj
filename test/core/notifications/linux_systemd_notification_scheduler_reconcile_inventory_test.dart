import 'dart:convert';

import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler_exception.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_store.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2, 8);

  group('desired-state normalization', () {
    test('last value wins before due filtering', () async {
      final scheduleId = 'task-reconcile-duplicate';
      final future = _request(
        scheduleId,
        scheduledAtUtc: now.add(const Duration(hours: 2)),
      );
      final futureFingerprint = await LinuxNotificationRequestFingerprint()
          .compute(future);
      final entry = _entryForRequest(future, futureFingerprint);
      final discovery = _discovery(
        complete: <LinuxSystemdUnitNames>[
          LinuxSystemdUnitNames.forScheduleKey(scheduleId),
        ],
      );

      final keepHarness = _Harness(
        now: now,
        registry: _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[entry],
        ),
        discovery: discovery,
      );
      await keepHarness.scheduler.reconcile(<NotificationRequest>[
        _request(scheduleId, scheduledAtUtc: now),
        future,
      ]);

      expect(keepHarness.unitStore.beginOrder, isEmpty);
      expect(keepHarness.unitStore.installCalls, 0);
      expect(keepHarness.registryStore.replacements, isEmpty);
      expect(keepHarness.gateway.showNowCalls, 0);

      final removeHarness = _Harness(
        now: now,
        registry: _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[entry],
        ),
        discovery: discovery,
      );
      await removeHarness.scheduler.reconcile(<NotificationRequest>[
        future,
        _request(scheduleId, scheduledAtUtc: now),
      ]);

      expect(removeHarness.unitStore.beginOrder, <String>[scheduleId]);
      expect(removeHarness.registryStore.current.entries, isEmpty);
      expect(removeHarness.gateway.showNowCalls, 0);
    });

    test('stale cleanup is processed in schedule ID order', () async {
      final alpha = _entry('task-reconcile-alpha');
      final zeta = _entry('task-reconcile-zeta');
      final harness = _Harness(
        now: now,
        registry: _registry(
          generation: 7,
          entries: <LinuxSystemdScheduleRegistryEntry>[zeta, alpha],
        ),
        discovery: _discovery(
          complete: <LinuxSystemdUnitNames>[
            _names(zeta.scheduleId),
            _names(alpha.scheduleId),
          ],
        ),
      );

      await harness.scheduler.reconcile(const <NotificationRequest>[]);

      expect(
        harness.unitStore.beginOrder,
        orderedEquals(<String>[alpha.scheduleId, zeta.scheduleId]),
      );
      expect(harness.runner.reloadCount, 1);
      expect(harness.registryStore.current.entries, isEmpty);
      expect(harness.registryStore.current.generation, 8);
    });

    test('due request cleans stale state without immediate delivery', () async {
      final scheduleId = 'task-reconcile-due';
      final harness = _Harness(
        now: now,
        registry: _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[_entry(scheduleId)],
        ),
        discovery: _discovery(
          complete: <LinuxSystemdUnitNames>[_names(scheduleId)],
        ),
      );

      await harness.scheduler.reconcile(<NotificationRequest>[
        _request(scheduleId, scheduledAtUtc: now),
      ]);

      expect(harness.unitStore.beginOrder, <String>[scheduleId]);
      expect(harness.gateway.showNowCalls, 0);
      expect(harness.gateway.scheduleCalls, 0);
      expect(harness.registryStore.current.entries, isEmpty);
    });
  });

  group('inventory cleanup', () {
    test(
      'removes stale registry entry while preserving desired future entry',
      () async {
        final keepRequest = _request(
          'task-reconcile-keep',
          scheduledAtUtc: now.add(const Duration(hours: 1)),
        );
        final keepFingerprint = await LinuxNotificationRequestFingerprint()
            .compute(keepRequest);
        final keep = _entryForRequest(keepRequest, keepFingerprint);
        final stale = _entry('task-reconcile-stale');
        final harness = _Harness(
          now: now,
          registry: _registry(
            generation: 3,
            entries: <LinuxSystemdScheduleRegistryEntry>[stale, keep],
          ),
          discovery: _discovery(
            complete: <LinuxSystemdUnitNames>[
              _names(keep.scheduleId),
              _names(stale.scheduleId),
            ],
          ),
        );

        await harness.scheduler.reconcile(<NotificationRequest>[keepRequest]);

        expect(harness.unitStore.beginOrder, <String>[stale.scheduleId]);
        expect(harness.unitStore.installCalls, 0);
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[keep.scheduleId]),
        );
        expect(harness.registryStore.current.generation, 4);
        expect(harness.runner.reloadCount, 1);
      },
    );

    test(
      'removes orphan complete pair absent from registry and desired state',
      () async {
        final orphanId = 'task-reconcile-orphan';
        final harness = _Harness(
          now: now,
          registry: LinuxSystemdScheduleRegistry.empty(),
          discovery: _discovery(
            complete: <LinuxSystemdUnitNames>[_names(orphanId)],
          ),
        );

        await harness.scheduler.reconcile(const <NotificationRequest>[]);

        expect(harness.unitStore.beginOrder, <String>[
          _names(orphanId).baseName,
        ]);
        expect(harness.registryStore.replacements, isEmpty);
        expect(harness.runner.reloadCount, 1);
      },
    );

    test(
      'repairs orphan complete pair when desired future lacks registry evidence',
      () async {
        final desiredId = 'task-reconcile-desired-orphan';
        final harness = _Harness(
          now: now,
          registry: LinuxSystemdScheduleRegistry.empty(),
          discovery: _discovery(
            complete: <LinuxSystemdUnitNames>[_names(desiredId)],
          ),
        );

        await harness.scheduler.reconcile(<NotificationRequest>[
          _request(
            desiredId,
            scheduledAtUtc: now.add(const Duration(hours: 1)),
          ),
        ]);

        expect(harness.unitStore.beginOrder, isEmpty);
        expect(harness.unitStore.installCalls, 1);
        expect(harness.registryStore.replacements, hasLength(1));
        expect(harness.runner.reloadCount, 1);
        expect(
          harness.registryStore.current.entryForScheduleId(desiredId),
          isNotNull,
        );
      },
    );

    test('removes service-only and timer-only partial pairs', () async {
      final serviceOnly = _names('task-reconcile-service-only');
      final timerOnly = _names('task-reconcile-timer-only');
      final harness =
          _Harness(
              now: now,
              registry: LinuxSystemdScheduleRegistry.empty(),
              discovery: _discovery(
                partial: <LinuxSystemdPartialUnitPair>[
                  LinuxSystemdPartialUnitPair(
                    baseName: serviceOnly.baseName,
                    hasService: true,
                    hasTimer: false,
                  ),
                  LinuxSystemdPartialUnitPair(
                    baseName: timerOnly.baseName,
                    hasService: false,
                    hasTimer: true,
                  ),
                ],
              ),
            )
            ..unitStore.track('task-reconcile-service-only')
            ..unitStore.track('task-reconcile-timer-only');

      await harness.scheduler.reconcile(const <NotificationRequest>[]);

      expect(harness.unitStore.beginOrder.toSet(), <String>{
        'task-reconcile-service-only',
        'task-reconcile-timer-only',
      });
      expect(harness.runner.reloadCount, 1);
    });
  });

  group('corrupt registry recovery', () {
    test(
      'quarantines corruption, discovers once, and repairs desired state',
      () async {
        final desiredId = 'task-reconcile-corrupt-desired';
        final orphanId = 'task-reconcile-corrupt-orphan';
        final partialId = 'task-reconcile-corrupt-partial';
        final partialNames = _names(partialId);
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(
                  complete: <LinuxSystemdUnitNames>[
                    _names(desiredId),
                    _names(orphanId),
                  ],
                  partial: <LinuxSystemdPartialUnitPair>[
                    LinuxSystemdPartialUnitPair(
                      baseName: partialNames.baseName,
                      hasService: true,
                      hasTimer: false,
                    ),
                  ],
                ),
                loadError: _corruption(
                  LinuxSystemdScheduleRegistryFailure.malformedJson,
                ),
              )
              ..unitStore.track(desiredId)
              ..unitStore.track(orphanId)
              ..unitStore.track(partialId);

        await harness.scheduler.reconcile(<NotificationRequest>[
          _request(
            desiredId,
            scheduledAtUtc: now.add(const Duration(hours: 1)),
          ),
        ]);

        expect(harness.registryStore.quarantineCount, 1);
        expect(harness.registryStore.discoveryCount, 1);
        expect(harness.unitStore.beginOrder.toSet(), <String>{
          desiredId,
          orphanId,
          partialId,
        });
        expect(harness.runner.reloadCount, 2);
        expect(harness.unitStore.installCalls, 1);
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[desiredId]),
        );
        expect(harness.registryStore.current.generation, 2);
        expect(harness.gateway.showNowCalls, 0);
      },
    );

    test(
      'mismatched-name corruption is quarantined and cleaned by discovery',
      () async {
        final exactId = 'task-reconcile-invalid-identity';
        final harness = _Harness(
          now: now,
          registry: LinuxSystemdScheduleRegistry.empty(),
          discovery: _discovery(
            complete: <LinuxSystemdUnitNames>[_names(exactId)],
          ),
          loadError: _corruption(
            LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
          ),
        )..unitStore.track(exactId);

        await harness.scheduler.reconcile(const <NotificationRequest>[]);

        expect(harness.registryStore.quarantineCount, 1);
        expect(harness.registryStore.discoveryCount, 1);
        expect(harness.unitStore.beginOrder, <String>[exactId]);
        expect(harness.runner.reloadCount, 1);
      },
    );
  });

  test('repair failure does not roll back finalized cleanup', () async {
    final staleId = 'task-reconcile-boundary-stale';
    final desiredId = 'task-reconcile-boundary-desired';
    final harness = _Harness(
      now: now,
      registry: _registry(
        generation: 8,
        entries: <LinuxSystemdScheduleRegistryEntry>[_entry(staleId)],
      ),
      discovery: _discovery(complete: <LinuxSystemdUnitNames>[_names(staleId)]),
      failFactoryId: desiredId,
    )..unitStore.track(staleId);

    LinuxSystemdNotificationSchedulerException? actual;
    try {
      await harness.scheduler.reconcile(<NotificationRequest>[
        _request(desiredId, scheduledAtUtc: now.add(const Duration(hours: 1))),
      ]);
      fail('Expected partial reconciliation.');
    } on LinuxSystemdNotificationSchedulerException catch (error) {
      actual = error;
    }

    final exception = actual;
    expect(
      exception.failure,
      LinuxSystemdNotificationSchedulerFailure.partialReconciliation,
    );
    expect(exception.scheduleId, desiredId);
    expect(harness.unitStore.beginOrder, <String>[staleId]);
    expect(harness.registryStore.current.entries, isEmpty);
    expect(harness.registryStore.current.generation, 9);
  });

  test(
    'empty inventory is a true no-op after one load and discovery',
    () async {
      final harness = _Harness(
        now: now,
        registry: LinuxSystemdScheduleRegistry.empty(),
        discovery: _discovery(),
      );

      await harness.scheduler.reconcile(const <NotificationRequest>[]);

      expect(harness.registryStore.loadCount, 1);
      expect(harness.registryStore.discoveryCount, 1);
      expect(harness.registryStore.quarantineCount, 0);
      expect(harness.registryStore.replacements, isEmpty);
      expect(harness.unitStore.beginOrder, isEmpty);
      expect(harness.runner.reloadCount, 0);
      expect(harness.gateway.showNowCalls, 0);
    },
  );
}

final class _Harness {
  _Harness({
    required DateTime now,
    required LinuxSystemdScheduleRegistry registry,
    required LinuxSystemdUnitDiscovery discovery,
    Object? loadError,
    String? failFactoryId,
  }) {
    registryStore = _RegistryStore(
      initial: registry,
      discovery: discovery,
      loadError: loadError,
    );
    unitStore = _UnitStore();
    for (final entry in registry.entries) {
      unitStore.track(entry.scheduleId);
    }
    runner = _AutomaticRunner();
    gateway = _RecordingGateway();
    scheduler = LinuxSystemdNotificationScheduler(
      clock: FixedAppClock(utcValue: now, localValue: now),
      gateway: gateway,
      commandFactory: _RepairFactory(failId: failFactoryId),
      renderer: const LinuxSystemdUnitRenderer(),
      unitStore: unitStore,
      driver: LinuxSystemdUserDriver(processRunner: runner),
      registryStore: registryStore,
      fingerprint: LinuxNotificationRequestFingerprint(),
    );
  }

  late final _RegistryStore registryStore;
  late final _UnitStore unitStore;
  late final _AutomaticRunner runner;
  late final _RecordingGateway gateway;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _RegistryStore implements LinuxSystemdScheduleRegistryStore {
  _RegistryStore({
    required LinuxSystemdScheduleRegistry initial,
    required this.discovery,
    this.loadError,
  }) : current = initial;

  LinuxSystemdScheduleRegistry current;
  final LinuxSystemdUnitDiscovery discovery;
  final Object? loadError;
  final List<LinuxSystemdScheduleRegistry> replacements =
      <LinuxSystemdScheduleRegistry>[];

  int loadCount = 0;
  int quarantineCount = 0;
  int discoveryCount = 0;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    loadCount += 1;
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return current;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    replacements.add(next);
    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() async {
    quarantineCount += 1;
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() async {
    discoveryCount += 1;
    return discovery;
  }
}

final class _UnitStore implements LinuxSystemdUnitStore {
  final Map<String, String> _idsByBaseName = <String, String>{};
  final List<String> beginOrder = <String>[];
  int installCalls = 0;

  void track(String scheduleId) {
    _idsByBaseName[_names(scheduleId).baseName] = scheduleId;
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    final scheduleId = _idsByBaseName[names.baseName] ?? names.baseName;
    beginOrder.add(scheduleId);
    return _RemoveTransaction(names);
  }

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    installCalls += 1;
    final serviceSuffix = '.service';
    final baseName = units.serviceFileName.substring(
      0,
      units.serviceFileName.length - serviceSuffix.length,
    );
    return _InstallTransaction(LinuxSystemdUnitNames.parseBaseName(baseName));
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) async {
    final transaction = await beginInstall(units);
    await transaction.apply();
    await transaction.finalize();
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    final transaction = await beginRemove(names);
    await transaction.apply();
    await transaction.finalize();
  }
}

final class _InstallTransaction implements LinuxSystemdUnitInstallTransaction {
  _InstallTransaction(this.names);

  @override
  final LinuxSystemdUnitNames names;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _RemoveTransaction implements LinuxSystemdUnitRemoveTransaction {
  _RemoveTransaction(this.names);

  @override
  final LinuxSystemdUnitNames names;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _AutomaticRunner implements LinuxProcessRunner {
  final Set<String> _disabledBaseNames = <String>{};
  final Set<String> _enabledBaseNames = <String>{};

  int reloadCount = 0;

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    final isReload = request.arguments.contains('daemon-reload');
    final isStatus = request.arguments.contains('show');
    final isEnable = request.arguments.contains('enable');
    final isDisable = request.arguments.contains('disable');

    if (isReload) {
      reloadCount += 1;
    }

    final timerName = request.arguments.firstWhere(
      (argument) => argument.endsWith('.timer'),
      orElse: () => 'borj-notification-0000000000000000.timer',
    );
    final timerSuffix = '.timer';
    final baseName = timerName.substring(
      0,
      timerName.length - timerSuffix.length,
    );

    if (isDisable) {
      _disabledBaseNames.add(baseName);
      _enabledBaseNames.remove(baseName);
    }
    if (isEnable) {
      _enabledBaseNames.add(baseName);
      _disabledBaseNames.remove(baseName);
    }

    final healthy =
        _enabledBaseNames.contains(baseName) ||
        !_disabledBaseNames.contains(baseName);
    final stdout = isStatus
        ? <String>[
            'Id=$timerName',
            'LoadState=loaded',
            'ActiveState=${healthy ? 'active' : 'inactive'}',
            'SubState=${healthy ? 'waiting' : 'dead'}',
            'UnitFileState=${healthy ? 'enabled' : 'disabled'}',
            'Result=success',
            '',
          ].join('\n')
        : '';

    return LinuxProcessResult(
      executable: request.executable,
      arguments: request.arguments,
      pid: 1059,
      exitCode: 0,
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

final class _RecordingGateway implements NativeNotificationGateway {
  int showNowCalls = 0;
  int scheduleCalls = 0;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<NativePendingNotification>> pending() async {
    return const <NativePendingNotification>[];
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  }) async {
    scheduleCalls += 1;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    showNowCalls += 1;
  }
}

final class _RepairFactory implements LinuxNotificationDeliveryCommandFactory {
  const _RepairFactory({this.failId});

  final String? failId;

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    if (request.scheduleId == failId) {
      throw StateError('repair factory failure for ${request.scheduleId}');
    }
    return LinuxSystemdNotificationUnit(
      scheduleKey: request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: '/opt/borj',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
  }
}

NotificationRequest _request(
  String scheduleId, {
  required DateTime scheduledAtUtc,
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'owner-$scheduleId',
    ),
    title: 'Title',
    body: 'Body',
    scheduledAtUtc: scheduledAtUtc,
  );
}

LinuxSystemdScheduleRegistryEntry _entryForRequest(
  NotificationRequest request,
  String requestFingerprint,
) {
  final names = _names(request.scheduleId);
  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: request.scheduleId,
    owner: request.owner,
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: request.scheduledAtUtc,
    requestFingerprint: requestFingerprint,
  );
}

LinuxSystemdScheduleRegistryEntry _entry(String scheduleId) {
  final names = _names(scheduleId);
  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'owner-$scheduleId',
    ),
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 10),
    requestFingerprint: List<String>.filled(64, 'a').join(),
  );
}

LinuxSystemdScheduleRegistry _registry({
  int generation = 1,
  required Iterable<LinuxSystemdScheduleRegistryEntry> entries,
}) {
  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: generation,
    entries: entries,
  );
}

LinuxSystemdUnitDiscovery _discovery({
  Iterable<LinuxSystemdUnitNames> complete = const <LinuxSystemdUnitNames>[],
  Iterable<LinuxSystemdPartialUnitPair> partial =
      const <LinuxSystemdPartialUnitPair>[],
}) {
  return LinuxSystemdUnitDiscovery(
    completePairs: complete,
    partialPairs: partial,
  );
}

LinuxSystemdUnitNames _names(String scheduleId) {
  return LinuxSystemdUnitNames.forScheduleKey(scheduleId);
}

LinuxSystemdScheduleRegistryException _corruption(
  LinuxSystemdScheduleRegistryFailure failure,
) {
  return LinuxSystemdScheduleRegistryException(
    operation: LinuxSystemdScheduleRegistryOperation.load,
    failure: failure,
    path: '/config/systemd/user/registry.json',
  );
}
