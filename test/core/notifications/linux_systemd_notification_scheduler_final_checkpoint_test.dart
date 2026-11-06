import 'dart:convert';

import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:borj/core/notifications/linux_systemd_environment.dart';
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
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';
import '../../support/recording_native_notification_gateway.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2, 8);

  group('Task 10.5 final scheduler checkpoint', () {
    test(
      'completes the full fake lifecycle and reports partial repair',
      () async {
        final harness = _LifecycleHarness(now: now);
        final ownerA = NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'checkpoint-owner-a',
        );
        final ownerB = NotificationOwner(
          type: NotificationOwnerType.habit,
          id: 'checkpoint-owner-b',
        );

        final original = _request(
          'checkpoint-main',
          ownerA,
          now.add(const Duration(hours: 2)),
          title: 'Original',
        );

        await harness.scheduler.schedule(original);

        expect(
          harness.registry.current.entryForScheduleId(original.scheduleId),
          isNotNull,
        );
        expect(harness.units.hasComplete(original.scheduleId), isTrue);
        expect(harness.runner.isEnabled(original.scheduleId), isTrue);
        expect(harness.units.installCount, 1);

        await harness.scheduler.schedule(original);

        expect(harness.units.installCount, 1);

        final changed = _request(
          original.scheduleId,
          ownerA,
          now.add(const Duration(hours: 3)),
          title: 'Changed',
        );
        final changedFingerprint = await LinuxNotificationRequestFingerprint()
            .compute(changed);

        await harness.scheduler.schedule(changed);

        expect(harness.units.installCount, 2);
        expect(
          harness.registry.current
              .entryForScheduleId(changed.scheduleId)!
              .requestFingerprint,
          changedFingerprint,
        );

        final due = _request(changed.scheduleId, ownerA, now, title: 'Due now');

        await harness.scheduler.schedule(due);

        expect(
          harness.registry.current.entryForScheduleId(due.scheduleId),
          isNull,
        );
        expect(harness.units.hasAny(due.scheduleId), isFalse);
        expect(harness.gateway.calls.last.kind, 'showNow');

        final cancelRequest = _request(
          'checkpoint-cancel',
          ownerA,
          now.add(const Duration(hours: 4)),
        );
        await harness.scheduler.schedule(cancelRequest);
        await harness.scheduler.cancel(cancelRequest.scheduleId);

        expect(
          harness.registry.current.entryForScheduleId(cancelRequest.scheduleId),
          isNull,
        );
        expect(harness.units.hasAny(cancelRequest.scheduleId), isFalse);

        final ownerAlpha = _request(
          'checkpoint-owner-alpha',
          ownerA,
          now.add(const Duration(hours: 5)),
        );
        final ownerBeta = _request(
          'checkpoint-owner-beta',
          ownerA,
          now.add(const Duration(hours: 6)),
        );
        final survivor = _request(
          'checkpoint-survivor',
          ownerB,
          now.add(const Duration(hours: 7)),
        );

        await harness.scheduler.schedule(ownerBeta);
        await harness.scheduler.schedule(survivor);
        await harness.scheduler.schedule(ownerAlpha);
        await harness.scheduler.cancelByOwner(ownerA);

        expect(
          harness.registry.current.entries.map((entry) => entry.scheduleId),
          orderedEquals(<String>[survivor.scheduleId]),
        );
        expect(harness.units.hasComplete(survivor.scheduleId), isTrue);
        expect(harness.units.hasAny(ownerAlpha.scheduleId), isFalse);
        expect(harness.units.hasAny(ownerBeta.scheduleId), isFalse);

        final stale = _request(
          'checkpoint-stale',
          ownerA,
          now.add(const Duration(hours: 8)),
        );
        final orphanId = 'checkpoint-orphan';
        final partialId = 'checkpoint-partial';

        harness.units.seedComplete(stale.scheduleId);
        harness.units.seedComplete(orphanId);
        harness.units.seedPartial(partialId, hasService: true);
        harness.registry.addEntry(await _entryFor(stale));

        await harness.scheduler.reconcile(<NotificationRequest>[survivor]);

        expect(harness.units.hasAny(stale.scheduleId), isFalse);
        expect(harness.units.hasAny(orphanId), isFalse);
        expect(harness.units.hasAny(partialId), isFalse);
        expect(harness.units.hasComplete(survivor.scheduleId), isTrue);
        expect(
          harness.registry.current.entries.map((entry) => entry.scheduleId),
          orderedEquals(<String>[survivor.scheduleId]),
        );

        harness.registry.corruptNextLoad();

        await harness.scheduler.reconcile(<NotificationRequest>[survivor]);

        expect(harness.registry.quarantineCount, 1);
        expect(harness.units.hasComplete(survivor.scheduleId), isTrue);
        expect(
          harness.registry.current.entries.map((entry) => entry.scheduleId),
          orderedEquals(<String>[survivor.scheduleId]),
        );

        final repairAlpha = _request(
          'checkpoint-repair-alpha',
          ownerA,
          now.add(const Duration(hours: 9)),
        );
        final repairBeta = _request(
          'checkpoint-repair-beta',
          ownerA,
          now.add(const Duration(hours: 10)),
        );
        harness.runner.failEnableFor(repairBeta.scheduleId);

        final error = await _expectPartial(
          () => harness.scheduler.reconcile(<NotificationRequest>[
            repairBeta,
            repairAlpha,
          ]),
        );

        expect(error.scheduleId, repairBeta.scheduleId);
        expect(
          error.completedScheduleIds,
          orderedEquals(<String>[repairAlpha.scheduleId]),
        );
        expect(
          () => error.completedScheduleIds.add('checkpoint-illegal'),
          throwsUnsupportedError,
        );
        expect(
          harness.registry.current.entries.map((entry) => entry.scheduleId),
          orderedEquals(<String>[repairAlpha.scheduleId]),
        );
        expect(harness.units.hasComplete(repairAlpha.scheduleId), isTrue);
        expect(harness.units.hasAny(repairBeta.scheduleId), isFalse);
        expect(harness.units.hasAny(survivor.scheduleId), isFalse);
      },
    );

    test(
      'composes production store renderer and driver without real systemd',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final runner = _AutomaticProcessRunner();
        final registry = _MemoryRegistryStore(units: _MemoryUnitStore());
        final gateway = RecordingNativeNotificationGateway();
        var transactionId = 0;
        final unitStore = LinuxSystemdUserUnitStore(
          pathResolver: LinuxSystemdUserUnitPathResolver(
            const _MapEnvironment(<String, String>{
              'XDG_CONFIG_HOME': '/checkpoint',
            }),
          ),
          fileSystem: fileSystem,
          transactionIdFactory: () {
            transactionId += 1;
            return 'checkpoint-$transactionId';
          },
        );
        final scheduler = LinuxSystemdNotificationScheduler(
          clock: FixedAppClock(utcValue: now, localValue: now),
          gateway: gateway,
          commandFactory: const _DeliveryFactory(),
          renderer: const LinuxSystemdUnitRenderer(),
          unitStore: unitStore,
          driver: LinuxSystemdUserDriver(processRunner: runner),
          registryStore: registry,
          fingerprint: LinuxNotificationRequestFingerprint(),
        );
        final request = _request(
          'checkpoint-adapter',
          NotificationOwner(
            type: NotificationOwnerType.routine,
            id: 'checkpoint-adapter-owner',
          ),
          now.add(const Duration(hours: 2)),
        );
        final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
        final directory = '/checkpoint/systemd/user';
        final servicePath = '$directory/${names.serviceFileName}';
        final timerPath = '$directory/${names.timerFileName}';

        await scheduler.schedule(request);

        expect(fileSystem.containsPath(servicePath), isTrue);
        expect(fileSystem.containsPath(timerPath), isTrue);
        expect(
          registry.current.entryForScheduleId(request.scheduleId),
          isNotNull,
        );
        expect(runner.requests, isNotEmpty);
        expect(
          runner.requests.every((request) => request.executable == 'systemctl'),
          isTrue,
        );

        await scheduler.cancel(request.scheduleId);

        expect(fileSystem.containsPath(servicePath), isFalse);
        expect(fileSystem.containsPath(timerPath), isFalse);
        expect(registry.current.entries, isEmpty);
        expect(gateway.calls, isEmpty);
      },
    );
  });
}

final class _LifecycleHarness {
  _LifecycleHarness({required DateTime now}) {
    units = _MemoryUnitStore();
    registry = _MemoryRegistryStore(units: units);
    runner = _AutomaticProcessRunner();
    gateway = RecordingNativeNotificationGateway();
    scheduler = LinuxSystemdNotificationScheduler(
      clock: FixedAppClock(utcValue: now, localValue: now),
      gateway: gateway,
      commandFactory: const _DeliveryFactory(),
      renderer: const LinuxSystemdUnitRenderer(),
      unitStore: units,
      driver: LinuxSystemdUserDriver(processRunner: runner),
      registryStore: registry,
      fingerprint: LinuxNotificationRequestFingerprint(),
    );
  }

  late final _MemoryUnitStore units;
  late final _MemoryRegistryStore registry;
  late final _AutomaticProcessRunner runner;
  late final RecordingNativeNotificationGateway gateway;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _DeliveryFactory
    implements LinuxNotificationDeliveryCommandFactory {
  const _DeliveryFactory();

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    return LinuxSystemdNotificationUnit(
      scheduleKey: request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: '/opt/borj',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
  }
}

enum _PairState { none, serviceOnly, timerOnly, complete }

final class _MemoryUnitStore implements LinuxSystemdUnitStore {
  final Map<String, _PairState> _states = <String, _PairState>{};

  int installCount = 0;
  int removeCount = 0;

  bool hasComplete(String scheduleId) {
    return _stateForSchedule(scheduleId) == _PairState.complete;
  }

  bool hasAny(String scheduleId) {
    return _stateForSchedule(scheduleId) != _PairState.none;
  }

  void seedComplete(String scheduleId) {
    _states[_names(scheduleId).baseName] = _PairState.complete;
  }

  void seedPartial(String scheduleId, {required bool hasService}) {
    _states[_names(scheduleId).baseName] = hasService
        ? _PairState.serviceOnly
        : _PairState.timerOnly;
  }

  LinuxSystemdUnitDiscovery discovery() {
    final complete = <LinuxSystemdUnitNames>[];
    final partial = <LinuxSystemdPartialUnitPair>[];

    for (final entry in _states.entries) {
      switch (entry.value) {
        case _PairState.none:
          break;
        case _PairState.complete:
          complete.add(LinuxSystemdUnitNames.parseBaseName(entry.key));
          break;
        case _PairState.serviceOnly:
          partial.add(
            LinuxSystemdPartialUnitPair(
              baseName: entry.key,
              hasService: true,
              hasTimer: false,
            ),
          );
          break;
        case _PairState.timerOnly:
          partial.add(
            LinuxSystemdPartialUnitPair(
              baseName: entry.key,
              hasService: false,
              hasTimer: true,
            ),
          );
          break;
      }
    }

    return LinuxSystemdUnitDiscovery(
      completePairs: complete,
      partialPairs: partial,
    );
  }

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    installCount += 1;
    final baseName = units.serviceFileName.substring(
      0,
      units.serviceFileName.length - '.service'.length,
    );
    final names = LinuxSystemdUnitNames.parseBaseName(baseName);
    return _MemoryInstallTransaction(
      names: names,
      states: _states,
      previous: _states[baseName] ?? _PairState.none,
    );
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    removeCount += 1;
    return _MemoryRemoveTransaction(
      names: names,
      states: _states,
      previous: _states[names.baseName] ?? _PairState.none,
    );
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

  _PairState _stateForSchedule(String scheduleId) {
    return _states[_names(scheduleId).baseName] ?? _PairState.none;
  }
}

final class _MemoryInstallTransaction
    implements LinuxSystemdUnitInstallTransaction {
  _MemoryInstallTransaction({
    required this.names,
    required this.states,
    required this.previous,
  });

  @override
  final LinuxSystemdUnitNames names;
  final Map<String, _PairState> states;
  final _PairState previous;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    states[names.baseName] = _PairState.complete;
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    _restorePair(states, names.baseName, previous);
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _MemoryRemoveTransaction
    implements LinuxSystemdUnitRemoveTransaction {
  _MemoryRemoveTransaction({
    required this.names,
    required this.states,
    required this.previous,
  });

  @override
  final LinuxSystemdUnitNames names;
  final Map<String, _PairState> states;
  final _PairState previous;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    states.remove(names.baseName);
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    _restorePair(states, names.baseName, previous);
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

void _restorePair(
  Map<String, _PairState> states,
  String baseName,
  _PairState previous,
) {
  if (previous == _PairState.none) {
    states.remove(baseName);
  } else {
    states[baseName] = previous;
  }
}

final class _MemoryRegistryStore implements LinuxSystemdScheduleRegistryStore {
  _MemoryRegistryStore({required this.units})
    : current = LinuxSystemdScheduleRegistry.empty();

  final _MemoryUnitStore units;
  LinuxSystemdScheduleRegistry current;

  int quarantineCount = 0;
  int discoveryCount = 0;
  bool _corruptNextLoad = false;

  void corruptNextLoad() {
    _corruptNextLoad = true;
  }

  void addEntry(LinuxSystemdScheduleRegistryEntry entry) {
    current = LinuxSystemdScheduleRegistry(
      schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
      generation: current.generation + 1,
      entries: <LinuxSystemdScheduleRegistryEntry>[
        ...current.entries.where((item) => item.scheduleId != entry.scheduleId),
        entry,
      ],
    );
  }

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    if (_corruptNextLoad) {
      _corruptNextLoad = false;
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.load,
        failure: LinuxSystemdScheduleRegistryFailure.malformedJson,
      );
    }
    return current;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() async {
    quarantineCount += 1;
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() async {
    discoveryCount += 1;
    return units.discovery();
  }
}

final class _AutomaticProcessRunner implements LinuxProcessRunner {
  final Set<String> _enabledBaseNames = <String>{};
  final Set<String> _failedEnableBaseNames = <String>{};
  final List<LinuxProcessRequest> requests = <LinuxProcessRequest>[];

  bool isEnabled(String scheduleId) {
    return _enabledBaseNames.contains(_names(scheduleId).baseName);
  }

  void failEnableFor(String scheduleId) {
    _failedEnableBaseNames.add(_names(scheduleId).baseName);
  }

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
      if (_failedEnableBaseNames.remove(baseName)) {
        return _result(request, exitCode: 1);
      }
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
      pid: 1511,
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

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}

NotificationRequest _request(
  String scheduleId,
  NotificationOwner owner,
  DateTime scheduledAtUtc, {
  String title = 'Checkpoint reminder',
}) {
  return NotificationRequest(
    scheduleId: scheduleId,
    owner: owner,
    title: title,
    body: 'Checkpoint body',
    scheduledAtUtc: scheduledAtUtc,
    payload: const <String, String>{'route': '/checkpoint'},
  );
}

Future<LinuxSystemdScheduleRegistryEntry> _entryFor(
  NotificationRequest request,
) async {
  final names = _names(request.scheduleId);
  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: request.scheduleId,
    owner: request.owner,
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: request.scheduledAtUtc,
    requestFingerprint: await LinuxNotificationRequestFingerprint().compute(
      request,
    ),
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
