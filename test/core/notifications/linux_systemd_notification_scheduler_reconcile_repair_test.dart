import 'dart:convert';

import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_bounded_output.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_cancellation_token.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_process_request.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_process_result.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_process_runner.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_notification_scheduler_exception.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_notification_unit.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_schedule_registry_store.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_timer_name.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_user_driver.dart';
import 'package:dashboard_shakhsi/core/notifications/native_notification_gateway.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_owner.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2, 8);
  final fingerprint = LinuxNotificationRequestFingerprint();

  group('repair classification', () {
    test('matching fingerprint and healthy status is preserved', () async {
      final request = _request(
        'task-repair-healthy',
        now.add(const Duration(hours: 2)),
      );
      final digest = await fingerprint.compute(request);
      final harness = _Harness(
        now: now,
        registry: _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[_entry(request, digest)],
        ),
        discovery: _discovery(completeIds: <String>[request.scheduleId]),
        healthyIds: <String>{request.scheduleId},
      )..track(request.scheduleId);

      await harness.scheduler.reconcile(<NotificationRequest>[request]);

      expect(harness.unitStore.installOrder, isEmpty);
      expect(harness.runner.reloadCount, 0);
      expect(harness.runner.enableOrder, isEmpty);
      expect(harness.registryStore.replacements, isEmpty);
    });

    test('matching fingerprint with unhealthy status is repaired', () async {
      final request = _request(
        'task-repair-unhealthy',
        now.add(const Duration(hours: 2)),
      );
      final digest = await fingerprint.compute(request);
      final harness = _Harness(
        now: now,
        registry: _registry(
          generation: 4,
          entries: <LinuxSystemdScheduleRegistryEntry>[_entry(request, digest)],
        ),
        discovery: _discovery(completeIds: <String>[request.scheduleId]),
      )..track(request.scheduleId);

      await harness.scheduler.reconcile(<NotificationRequest>[request]);

      expect(harness.unitStore.installOrder, <String>[request.scheduleId]);
      expect(harness.runner.reloadCount, 1);
      expect(harness.runner.enableOrder, <String>[request.scheduleId]);
      expect(
        harness.unitStore.transaction(request.scheduleId).finalizeCalls,
        1,
      );
      expect(harness.registryStore.current.generation, 5);
      expect(
        harness.registryStore.current
            .entryForScheduleId(request.scheduleId)!
            .requestFingerprint,
        digest,
      );
    });

    test('changed fingerprint replaces the existing schedule', () async {
      final oldRequest = _request(
        'task-repair-changed',
        now.add(const Duration(hours: 2)),
        title: 'Old title',
      );
      final desired = _request(
        oldRequest.scheduleId,
        now.add(const Duration(hours: 3)),
        title: 'New title',
      );
      final oldDigest = await fingerprint.compute(oldRequest);
      final newDigest = await fingerprint.compute(desired);
      final harness = _Harness(
        now: now,
        registry: _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[
            _entry(oldRequest, oldDigest),
          ],
        ),
        discovery: _discovery(completeIds: <String>[desired.scheduleId]),
        healthyIds: <String>{desired.scheduleId},
      )..track(desired.scheduleId);

      await harness.scheduler.reconcile(<NotificationRequest>[desired]);

      expect(harness.unitStore.installOrder, <String>[desired.scheduleId]);
      expect(harness.runner.directStatusCount, 0);
      expect(
        harness.registryStore.current
            .entryForScheduleId(desired.scheduleId)!
            .requestFingerprint,
        newDigest,
      );
      expect(
        harness.registryStore.current
            .entryForScheduleId(desired.scheduleId)!
            .scheduledAtUtc,
        desired.scheduledAtUtc,
      );
    });

    test(
      'missing registry and unit pair creates the desired schedule',
      () async {
        final request = _request(
          'task-repair-missing',
          now.add(const Duration(hours: 2)),
        );
        final harness = _Harness(
          now: now,
          registry: LinuxSystemdScheduleRegistry.empty(),
          discovery: _discovery(),
        )..track(request.scheduleId);

        await harness.scheduler.reconcile(<NotificationRequest>[request]);

        expect(harness.unitStore.installOrder, <String>[request.scheduleId]);
        expect(harness.runner.reloadCount, 1);
        expect(harness.runner.enableOrder, <String>[request.scheduleId]);
        expect(
          harness.registryStore.current.entryForScheduleId(request.scheduleId),
          isNotNull,
        );
      },
    );
  });

  group('coherent install batch', () {
    test(
      'repairs in schedule ID order with exactly one initial reload',
      () async {
        final alpha = _request(
          'task-repair-alpha',
          now.add(const Duration(hours: 2)),
        );
        final zeta = _request(
          'task-repair-zeta',
          now.add(const Duration(hours: 2)),
        );
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(),
              )
              ..track(alpha.scheduleId)
              ..track(zeta.scheduleId);

        await harness.scheduler.reconcile(<NotificationRequest>[zeta, alpha]);

        expect(
          harness.unitStore.installOrder,
          orderedEquals(<String>[alpha.scheduleId, zeta.scheduleId]),
        );
        expect(
          harness.unitStore.applyOrder,
          orderedEquals(<String>[alpha.scheduleId, zeta.scheduleId]),
        );
        expect(
          harness.runner.enableOrder,
          orderedEquals(<String>[alpha.scheduleId, zeta.scheduleId]),
        );
        expect(harness.runner.reloadCount, 1);
        expect(harness.registryStore.replacements, hasLength(1));
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[alpha.scheduleId, zeta.scheduleId]),
        );
      },
    );
  });

  group('partial reconciliation reporting', () {
    test(
      'factory failure rolls back staged installs and reports no completion',
      () async {
        final alpha = _request(
          'task-repair-factory-alpha',
          now.add(const Duration(hours: 2)),
        );
        final beta = _request(
          'task-repair-factory-beta',
          now.add(const Duration(hours: 2)),
        );
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(),
                failFactoryId: beta.scheduleId,
              )
              ..track(alpha.scheduleId)
              ..track(beta.scheduleId);

        final error = await _expectPartial(
          () => harness.scheduler.reconcile(<NotificationRequest>[beta, alpha]),
        );

        expect(error.scheduleId, beta.scheduleId);
        expect(error.completedScheduleIds, isEmpty);
        expect(
          harness.unitStore.transaction(alpha.scheduleId).rollbackCalls,
          1,
        );
        expect(harness.runner.enableOrder, isEmpty);
        expect(harness.registryStore.current.entries, isEmpty);
      },
    );

    test(
      'enable failure preserves prior confirmed success and stops batch',
      () async {
        final alpha = _request(
          'task-repair-enable-alpha',
          now.add(const Duration(hours: 2)),
        );
        final beta = _request(
          'task-repair-enable-beta',
          now.add(const Duration(hours: 2)),
        );
        final gamma = _request(
          'task-repair-enable-gamma',
          now.add(const Duration(hours: 2)),
        );
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(),
                failEnableId: beta.scheduleId,
              )
              ..track(alpha.scheduleId)
              ..track(beta.scheduleId)
              ..track(gamma.scheduleId);

        final error = await _expectPartial(
          () => harness.scheduler.reconcile(<NotificationRequest>[
            gamma,
            beta,
            alpha,
          ]),
        );

        expect(error.scheduleId, beta.scheduleId);
        expect(
          error.completedScheduleIds,
          orderedEquals(<String>[alpha.scheduleId]),
        );
        expect(
          () => error.completedScheduleIds.add('task-repair-illegal'),
          throwsUnsupportedError,
        );
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[alpha.scheduleId]),
        );
        expect(
          harness.unitStore.transaction(alpha.scheduleId).finalizeCalls,
          1,
        );
        expect(harness.unitStore.transaction(beta.scheduleId).rollbackCalls, 1);
        expect(
          harness.unitStore.transaction(gamma.scheduleId).rollbackCalls,
          1,
        );
        expect(harness.runner.enableOrder, <String>[
          alpha.scheduleId,
          beta.scheduleId,
        ]);
        expect(harness.runner.reloadCount, 2);
      },
    );

    test(
      'finalize failure rolls back the failing and later installs',
      () async {
        final alpha = _request(
          'task-repair-finalize-alpha',
          now.add(const Duration(hours: 2)),
        );
        final beta = _request(
          'task-repair-finalize-beta',
          now.add(const Duration(hours: 2)),
        );
        final gamma = _request(
          'task-repair-finalize-gamma',
          now.add(const Duration(hours: 2)),
        );
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(),
                failFinalizeId: beta.scheduleId,
              )
              ..track(alpha.scheduleId)
              ..track(beta.scheduleId)
              ..track(gamma.scheduleId);

        final error = await _expectPartial(
          () => harness.scheduler.reconcile(<NotificationRequest>[
            gamma,
            beta,
            alpha,
          ]),
        );

        expect(error.scheduleId, beta.scheduleId);
        expect(
          error.completedScheduleIds,
          orderedEquals(<String>[alpha.scheduleId]),
        );
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[alpha.scheduleId]),
        );
        expect(harness.unitStore.transaction(beta.scheduleId).rollbackCalls, 1);
        expect(
          harness.unitStore.transaction(gamma.scheduleId).rollbackCalls,
          1,
        );
      },
    );

    test(
      'registry failure reports confirmed completed IDs and repairs inventory',
      () async {
        final alpha = _request(
          'task-repair-registry-alpha',
          now.add(const Duration(hours: 2)),
        );
        final beta = _request(
          'task-repair-registry-beta',
          now.add(const Duration(hours: 2)),
        );
        final harness =
            _Harness(
                now: now,
                registry: LinuxSystemdScheduleRegistry.empty(),
                discovery: _discovery(),
                failReplaceCall: 1,
              )
              ..track(alpha.scheduleId)
              ..track(beta.scheduleId);

        final error = await _expectPartial(
          () => harness.scheduler.reconcile(<NotificationRequest>[beta, alpha]),
        );

        expect(
          error.completedScheduleIds,
          orderedEquals(<String>[alpha.scheduleId, beta.scheduleId]),
        );
        expect(
          harness.registryStore.current.entries.map(
            (entry) => entry.scheduleId,
          ),
          orderedEquals(<String>[alpha.scheduleId, beta.scheduleId]),
        );
        expect(harness.registryStore.replaceCalls, 2);
        expect(error.rollbackFailures, isEmpty);
      },
    );
  });
}

final class _Harness {
  _Harness({
    required DateTime now,
    required LinuxSystemdScheduleRegistry registry,
    required LinuxSystemdUnitDiscovery discovery,
    Set<String> healthyIds = const <String>{},
    String? failFactoryId,
    String? failEnableId,
    String? failApplyId,
    String? failFinalizeId,
    int? failReplaceCall,
  }) {
    registryStore = _RegistryStore(
      current: registry,
      discovery: discovery,
      failReplaceCall: failReplaceCall,
    );
    unitStore = _InstallUnitStore(
      failApplyId: failApplyId,
      failFinalizeId: failFinalizeId,
    );
    runner = _RepairRunner(
      initiallyHealthyIds: healthyIds,
      failEnableId: failEnableId,
    );
    factory = _Factory(failId: failFactoryId);
    scheduler = LinuxSystemdNotificationScheduler(
      clock: FixedAppClock(utcValue: now, localValue: now),
      gateway: const _NoopGateway(),
      commandFactory: factory,
      renderer: const LinuxSystemdUnitRenderer(),
      unitStore: unitStore,
      driver: LinuxSystemdUserDriver(processRunner: runner),
      registryStore: registryStore,
      fingerprint: LinuxNotificationRequestFingerprint(),
    );
  }

  late final _RegistryStore registryStore;
  late final _InstallUnitStore unitStore;
  late final _RepairRunner runner;
  late final _Factory factory;
  late final LinuxSystemdNotificationScheduler scheduler;

  void track(String scheduleId) {
    unitStore.track(scheduleId);
    runner.track(scheduleId);
  }
}

final class _Factory implements LinuxNotificationDeliveryCommandFactory {
  const _Factory({this.failId});

  final String? failId;

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    if (request.scheduleId == failId) {
      throw StateError('factory failure for ${request.scheduleId}');
    }
    return LinuxSystemdNotificationUnit(
      scheduleKey: request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: '/opt/dashboard-shakhsi',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
  }
}

final class _InstallUnitStore implements LinuxSystemdUnitStore {
  _InstallUnitStore({this.failApplyId, this.failFinalizeId});

  final String? failApplyId;
  final String? failFinalizeId;
  final Map<String, String> _idsByBaseName = <String, String>{};
  final Map<String, _InstallTransaction> _transactions =
      <String, _InstallTransaction>{};

  final List<String> installOrder = <String>[];
  final List<String> applyOrder = <String>[];

  void track(String scheduleId) {
    _idsByBaseName[_names(scheduleId).baseName] = scheduleId;
  }

  _InstallTransaction transaction(String scheduleId) {
    return _transactions[scheduleId]!;
  }

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    final baseName = units.serviceFileName.substring(
      0,
      units.serviceFileName.length - '.service'.length,
    );
    final scheduleId = _idsByBaseName[baseName] ?? baseName;
    final names = LinuxSystemdUnitNames.parseBaseName(baseName);
    installOrder.add(scheduleId);
    final transaction = _InstallTransaction(
      names: names,
      scheduleId: scheduleId,
      applyOrder: applyOrder,
      failApply: scheduleId == failApplyId,
      failFinalize: scheduleId == failFinalizeId,
    );
    _transactions[scheduleId] = transaction;
    return transaction;
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    return _RemoveTransaction(names);
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
  _InstallTransaction({
    required this.names,
    required this.scheduleId,
    required this.applyOrder,
    required this.failApply,
    required this.failFinalize,
  });

  @override
  final LinuxSystemdUnitNames names;
  final String scheduleId;
  final List<String> applyOrder;
  final bool failApply;
  final bool failFinalize;

  int applyCalls = 0;
  int finalizeCalls = 0;
  int rollbackCalls = 0;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    applyCalls += 1;
    applyOrder.add(scheduleId);
    if (failApply) {
      throw StateError('apply failure for $scheduleId');
    }
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    finalizeCalls += 1;
    if (failFinalize) {
      throw StateError('finalize failure for $scheduleId');
    }
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    rollbackCalls += 1;
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

final class _RegistryStore implements LinuxSystemdScheduleRegistryStore {
  _RegistryStore({
    required this.current,
    required this.discovery,
    this.failReplaceCall,
  });

  LinuxSystemdScheduleRegistry current;
  final LinuxSystemdUnitDiscovery discovery;
  final int? failReplaceCall;
  final List<LinuxSystemdScheduleRegistry> replacements =
      <LinuxSystemdScheduleRegistry>[];
  int replaceCalls = 0;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async => current;

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    replaceCalls += 1;
    if (replaceCalls == failReplaceCall) {
      throw StateError('registry replace failure');
    }
    replacements.add(next);
    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() async {}

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() async {
    return discovery;
  }
}

final class _RepairRunner implements LinuxProcessRunner {
  _RepairRunner({required Set<String> initiallyHealthyIds, this.failEnableId})
    : _initiallyHealthyIds = <String>{...initiallyHealthyIds};

  final String? failEnableId;
  final Set<String> _initiallyHealthyIds;
  final Map<String, String> _idsByBaseName = <String, String>{};
  final Set<String> _enabledIds = <String>{};

  final List<String> enableOrder = <String>[];
  int reloadCount = 0;
  int directStatusCount = 0;

  void track(String scheduleId) {
    _idsByBaseName[_names(scheduleId).baseName] = scheduleId;
  }

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    if (request.arguments.contains('daemon-reload')) {
      reloadCount += 1;
      return _result(request);
    }

    final timerName = request.arguments.firstWhere(
      (argument) => argument.endsWith('.timer'),
      orElse: () => 'dashboard-shakhsi-notification-0000000000000000.timer',
    );
    final baseName = timerName.substring(0, timerName.length - '.timer'.length);
    final scheduleId = _idsByBaseName[baseName] ?? baseName;

    if (request.arguments.contains('enable')) {
      enableOrder.add(scheduleId);
      if (scheduleId == failEnableId) {
        return _result(request, exitCode: 1);
      }
      _enabledIds.add(scheduleId);
      return _result(request);
    }

    if (request.arguments.contains('disable')) {
      _enabledIds.remove(scheduleId);
      return _result(request);
    }

    if (request.arguments.contains('show')) {
      if (!_enabledIds.contains(scheduleId)) {
        directStatusCount += 1;
      }
      final healthy =
          _enabledIds.contains(scheduleId) ||
          _initiallyHealthyIds.contains(scheduleId);
      return _result(request, stdout: _status(timerName, healthy: healthy));
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
      pid: 1510,
      exitCode: exitCode,
      duration: const Duration(milliseconds: 1),
      stdout: _output(stdout),
      stderr: _output(''),
    );
  }

  String _status(String timerName, {required bool healthy}) {
    return <String>[
      'Id=$timerName',
      'LoadState=loaded',
      'ActiveState=${healthy ? 'active' : 'inactive'}',
      'SubState=${healthy ? 'waiting' : 'dead'}',
      'UnitFileState=${healthy ? 'enabled' : 'disabled'}',
      'Result=success',
      '',
    ].join('\n');
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

final class _NoopGateway implements NativeNotificationGateway {
  const _NoopGateway();

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
  }) async {}

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {}
}

NotificationRequest _request(
  String scheduleId,
  DateTime scheduledAtUtc, {
  String title = 'Title',
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'owner-$scheduleId',
    ),
    title: title,
    body: 'Body',
    scheduledAtUtc: scheduledAtUtc,
  );
}

LinuxSystemdScheduleRegistryEntry _entry(
  NotificationRequest request,
  String digest,
) {
  final names = _names(request.scheduleId);
  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: request.scheduleId,
    owner: request.owner,
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: request.scheduledAtUtc,
    requestFingerprint: digest,
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
  Iterable<String> completeIds = const <String>[],
}) {
  return LinuxSystemdUnitDiscovery(
    completePairs: completeIds.map(_names),
    partialPairs: const <LinuxSystemdPartialUnitPair>[],
  );
}

LinuxSystemdUnitNames _names(String scheduleId) {
  return LinuxSystemdUnitNames.forScheduleKey(scheduleId);
}

Future<LinuxSystemdNotificationSchedulerException> _expectPartial(
  Future<void> Function() action,
) async {
  try {
    await action();
    fail('Expected partial reconciliation failure.');
  } on LinuxSystemdNotificationSchedulerException catch (error) {
    expect(
      error.operation,
      LinuxSystemdNotificationSchedulerOperation.reconcile,
    );
    expect(
      error.failure,
      LinuxSystemdNotificationSchedulerFailure.partialReconciliation,
    );
    return error;
  }
}
