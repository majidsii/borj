import 'dart:collection';
import 'dart:convert';

import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:borj/core/notifications/linux_notification_request_fingerprint.dart';
import 'package:borj/core/notifications/linux_process_exception.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler.dart';
import 'package:borj/core/notifications/linux_systemd_notification_scheduler_exception.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_store.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/native_notification_gateway.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2, 8);

  group('cancel state inventory', () {
    test(
      'complete happy path uses the exact successful operation order',
      () async {
        final operations = <String>[];
        final scheduleId = 'task-cancel-complete';
        final previous = _registryWithEntry(scheduleId, generation: 4);
        final harness =
            _Harness(now: now, operations: operations, registry: previous)
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
              ..runner.enqueueSuccess();

        await harness.scheduler.cancel(scheduleId);

        expect(
          operations,
          orderedEquals(<String>[
            'registry.load',
            'unitStore.beginRemove',
            'driver.disable',
            'driver.status',
            'remove.apply',
            'driver.reload',
            'registry.replace',
            'remove.finalize',
          ]),
        );
        expect(harness.registryStore.current.entries, isEmpty);
        expect(harness.registryStore.current.generation, 5);
        expect(
          harness.unitStore.lastTransaction!.state,
          LinuxSystemdUnitTransactionState.finalized,
        );
      },
    );

    test('completely missing state is an idempotent typed cleanup', () async {
      final scheduleId = 'task-cancel-missing';
      final harness =
          _Harness(now: now, registry: LinuxSystemdScheduleRegistry.empty())
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueSuccess();

      await harness.scheduler.cancel(scheduleId);

      expect(harness.unitStore.beginRemoveCalls, 1);
      expect(harness.unitStore.lastTransaction!.applyCalls, 1);
      expect(harness.unitStore.lastTransaction!.finalizeCalls, 1);
      expect(harness.registryStore.replacements, isEmpty);
    });

    test('registry-only state removes the logical entry', () async {
      final scheduleId = 'task-cancel-registry-only';
      final previous = _registryWithEntry(scheduleId, generation: 7);
      final fileSystem = FakeLinuxSystemdFileSystem();
      final harness =
          _RealStoreHarness(
              now: now,
              scheduleId: scheduleId,
              registry: previous,
              fileSystem: fileSystem,
            )
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueSuccess();

      await harness.scheduler.cancel(scheduleId);

      expect(fileSystem.containsPath(_servicePath(scheduleId)), isFalse);
      expect(fileSystem.containsPath(_timerPath(scheduleId)), isFalse);
      expect(harness.registryStore.current.entries, isEmpty);
      expect(harness.registryStore.current.generation, 8);
    });

    test(
      'unit-only state removes orphan files without writing registry',
      () async {
        final scheduleId = 'task-cancel-unit-only';
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedCompletePair(fileSystem, scheduleId);
        final harness =
            _RealStoreHarness(
                now: now,
                scheduleId: scheduleId,
                registry: LinuxSystemdScheduleRegistry.empty(),
                fileSystem: fileSystem,
              )
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
              ..runner.enqueueSuccess();

        await harness.scheduler.cancel(scheduleId);

        expect(fileSystem.containsPath(_servicePath(scheduleId)), isFalse);
        expect(fileSystem.containsPath(_timerPath(scheduleId)), isFalse);
        expect(harness.registryStore.replacements, isEmpty);
      },
    );

    test('already-disabled status is accepted as typed success', () async {
      final scheduleId = 'task-cancel-already-disabled';
      final harness =
          _Harness(now: now, registry: _registryWithEntry(scheduleId))
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueSuccess();

      await harness.scheduler.cancel(scheduleId);

      expect(
        harness.runner.operations,
        containsAllInOrder(<String>[
          'driver.disable',
          'driver.status',
          'driver.reload',
        ]),
      );
      expect(harness.registryStore.current.entries, isEmpty);
    });
  });

  group('cancel failure rollback', () {
    test(
      'begin remove failure performs no rollback or driver mutation',
      () async {
        final scheduleId = 'task-cancel-begin-failure';
        final primary = StateError('begin remove failure');
        final harness = _Harness(
          now: now,
          registry: _registryWithEntry(scheduleId),
          beginRemoveError: primary,
        );

        final error = await _expectCancelFailure(
          () => harness.scheduler.cancel(scheduleId),
          LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        );

        expect(error.cause, same(primary));
        expect(harness.unitStore.lastTransaction, isNull);
        expect(
          harness.operations,
          orderedEquals(<String>['registry.load', 'unitStore.beginRemove']),
        );
        expect(harness.registryStore.replacements, isEmpty);
      },
    );

    test(
      'raw nonzero disable is not ignored and previous timer is restored',
      () async {
        final scheduleId = 'task-cancel-disable-failure';
        final previous = _registryWithEntry(scheduleId);
        final harness = _Harness(now: now, registry: previous)
          ..runner.enqueueExit(1)
          ..runner.enqueueSuccess()
          ..runner.enqueueSuccess()
          ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

        final error = await _expectCancelFailure(
          () => harness.scheduler.cancel(scheduleId),
          LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        );

        expect(error.cause, isNotNull);
        expect(
          harness.operations,
          orderedEquals(<String>[
            'registry.load',
            'unitStore.beginRemove',
            'driver.disable',
            'remove.rollback',
            'driver.reload',
            'driver.enable',
            'driver.status',
          ]),
        );
        expect(harness.registryStore.current, previous);
      },
    );

    test(
      'apply failure restores files, reloads, and re-enables timer',
      () async {
        final scheduleId = 'task-cancel-apply-failure';
        final primary = StateError('remove apply failure');
        final harness =
            _Harness(
                now: now,
                registry: _registryWithEntry(scheduleId),
                applyError: primary,
              )
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

        final error = await _expectCancelFailure(
          () => harness.scheduler.cancel(scheduleId),
          LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        );

        expect(error.cause, same(primary));
        expect(
          harness.operations,
          orderedEquals(<String>[
            'registry.load',
            'unitStore.beginRemove',
            'driver.disable',
            'driver.status',
            'remove.apply',
            'remove.rollback',
            'driver.reload',
            'driver.enable',
            'driver.status',
          ]),
        );
      },
    );

    test('daemon reload failure performs ordered remove rollback', () async {
      final scheduleId = 'task-cancel-reload-failure';
      final harness =
          _Harness(now: now, registry: _registryWithEntry(scheduleId))
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueExit(1)
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

      await _expectCancelFailure(
        () => harness.scheduler.cancel(scheduleId),
        LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
      );

      expect(
        harness.operations,
        orderedEquals(<String>[
          'registry.load',
          'unitStore.beginRemove',
          'driver.disable',
          'driver.status',
          'remove.apply',
          'driver.reload',
          'remove.rollback',
          'driver.reload',
          'driver.enable',
          'driver.status',
        ]),
      );
    });

    test('registry failure restores prior inventory monotonically', () async {
      final scheduleId = 'task-cancel-registry-failure';
      final previous = _registryWithEntry(scheduleId, generation: 12);
      final primary = StateError('registry replace failure');
      final harness =
          _Harness(
              now: now,
              registry: previous,
              failReplaceCall: 1,
              replaceBeforeThrow: true,
              replaceError: primary,
            )
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

      final error = await _expectCancelFailure(
        () => harness.scheduler.cancel(scheduleId),
        LinuxSystemdNotificationSchedulerFailure.registryFailed,
      );

      expect(error.cause, same(primary));
      expect(harness.registryStore.current.entries, previous.entries);
      expect(
        harness.registryStore.current.generation,
        greaterThan(previous.generation),
      );
      expect(
        harness.operations,
        containsAllInOrder(<String>[
          'registry.replace',
          'remove.rollback',
          'driver.reload',
          'registry.load',
          'registry.replace',
          'driver.enable',
          'driver.status',
        ]),
      );
    });

    test('finalize failure restores registry and previous timer', () async {
      final scheduleId = 'task-cancel-finalize-failure';
      final previous = _registryWithEntry(scheduleId, generation: 20);
      final primary = StateError('remove finalize failure');
      final harness =
          _Harness(now: now, registry: previous, finalizeError: primary)
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

      final error = await _expectCancelFailure(
        () => harness.scheduler.cancel(scheduleId),
        LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      );

      expect(error.cause, same(primary));
      expect(harness.registryStore.current.entries, previous.entries);
      expect(
        harness.registryStore.current.generation,
        greaterThan(previous.generation),
      );
      expect(harness.unitStore.lastTransaction!.rollbackCalls, 1);
      expect(
        harness.operations,
        containsAllInOrder(<String>[
          'registry.replace',
          'remove.finalize',
          'remove.rollback',
          'driver.reload',
          'registry.load',
          'registry.replace',
          'driver.enable',
          'driver.status',
        ]),
      );
    });
  });

  group('exact retained remove restoration', () {
    for (final pair in _PreviousPair.values) {
      test('registry failure restores exact ${pair.name} file state', () async {
        final scheduleId = 'task-cancel-restore-${pair.name}';
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedPair(fileSystem, scheduleId, pair);
        final previous = _registryWithEntry(scheduleId, generation: 30);
        final harness =
            _RealStoreHarness(
                now: now,
                scheduleId: scheduleId,
                registry: previous,
                fileSystem: fileSystem,
                failReplaceCall: 1,
                replaceBeforeThrow: true,
                replaceError: StateError('registry failure'),
              )
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

        await _expectCancelFailure(
          () => harness.scheduler.cancel(scheduleId),
          LinuxSystemdNotificationSchedulerFailure.registryFailed,
        );

        _expectPair(fileSystem, scheduleId, pair);
        expect(harness.registryStore.current.entries, previous.entries);
        expect(
          harness.registryStore.current.generation,
          greaterThan(previous.generation),
        );
        expect(
          harness.runner.operations,
          containsAllInOrder(<String>[
            'driver.reload',
            'driver.reload',
            'driver.enable',
            'driver.status',
          ]),
        );
      });
    }
  });

  group('cancel cancellation preservation', () {
    test('clean rollback rethrows the identical cancellation', () async {
      final scheduleId = 'task-cancel-cancellation';
      final previous = _registryWithEntry(scheduleId);
      final cancellation = _cancellation();
      final harness = _Harness(now: now, registry: previous)
        ..runner.enqueueSuccess()
        ..runner.enqueueStatus(scheduleId, enabled: false, active: false)
        ..runner.enqueueError(cancellation)
        ..runner.enqueueSuccess()
        ..runner.enqueueSuccess()
        ..runner.enqueueStatus(scheduleId, enabled: true, active: true);

      Object? caught;
      try {
        await harness.scheduler.cancel(scheduleId);
        fail('Expected cancellation.');
      } catch (error) {
        caught = error;
      }

      expect(caught, same(cancellation));
      expect(harness.unitStore.lastTransaction!.rollbackCalls, 1);
      expect(harness.registryStore.current, previous);
    });
  });
}

final class _Harness {
  _Harness({
    required DateTime now,
    List<String>? operations,
    LinuxSystemdScheduleRegistry? registry,
    Object? beginRemoveError,
    Object? applyError,
    Object? finalizeError,
    Object? rollbackError,
    int? failReplaceCall,
    bool replaceBeforeThrow = false,
    Object? replaceError,
  }) : operations = operations ?? <String>[] {
    unitStore = _ScriptedUnitStore(
      operations: this.operations,
      beginRemoveError: beginRemoveError,
      applyError: applyError,
      finalizeError: finalizeError,
      rollbackError: rollbackError,
    );
    registryStore = _ScriptedRegistryStore(
      initial: registry ?? LinuxSystemdScheduleRegistry.empty(),
      operations: this.operations,
      failReplaceCall: failReplaceCall,
      replaceBeforeThrow: replaceBeforeThrow,
      replaceError: replaceError,
    );
    runner = _ScriptedRunner(operations: this.operations);
    scheduler = _buildScheduler(
      now: now,
      unitStore: unitStore,
      registryStore: registryStore,
      runner: runner,
    );
  }

  final List<String> operations;
  late final _ScriptedUnitStore unitStore;
  late final _ScriptedRegistryStore registryStore;
  late final _ScriptedRunner runner;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _RealStoreHarness {
  _RealStoreHarness({
    required DateTime now,
    required String scheduleId,
    required LinuxSystemdScheduleRegistry registry,
    required FakeLinuxSystemdFileSystem fileSystem,
    int? failReplaceCall,
    bool replaceBeforeThrow = false,
    Object? replaceError,
  }) {
    registryStore = _ScriptedRegistryStore(
      initial: registry,
      failReplaceCall: failReplaceCall,
      replaceBeforeThrow: replaceBeforeThrow,
      replaceError: replaceError,
    );
    runner = _ScriptedRunner();
    scheduler = _buildScheduler(
      now: now,
      unitStore: LinuxSystemdUserUnitStore(
        pathResolver: LinuxSystemdUserUnitPathResolver(
          const _MapEnvironment(<String, String>{'XDG_CONFIG_HOME': '/config'}),
        ),
        fileSystem: fileSystem,
        transactionIdFactory: () => 'cancel-$scheduleId',
      ),
      registryStore: registryStore,
      runner: runner,
    );
  }

  late final _ScriptedRegistryStore registryStore;
  late final _ScriptedRunner runner;
  late final LinuxSystemdNotificationScheduler scheduler;
}

LinuxSystemdNotificationScheduler _buildScheduler({
  required DateTime now,
  required LinuxSystemdUnitStore unitStore,
  required LinuxSystemdScheduleRegistryStore registryStore,
  required LinuxProcessRunner runner,
}) {
  return LinuxSystemdNotificationScheduler(
    clock: FixedAppClock(utcValue: now, localValue: now),
    gateway: const _NoopGateway(),
    commandFactory: const _NoopFactory(),
    renderer: const LinuxSystemdUnitRenderer(),
    unitStore: unitStore,
    driver: LinuxSystemdUserDriver(processRunner: runner),
    registryStore: registryStore,
    fingerprint: LinuxNotificationRequestFingerprint(),
  );
}

final class _ScriptedUnitStore implements LinuxSystemdUnitStore {
  _ScriptedUnitStore({
    required this.operations,
    this.beginRemoveError,
    this.applyError,
    this.finalizeError,
    this.rollbackError,
  });

  final List<String> operations;
  final Object? beginRemoveError;
  final Object? applyError;
  final Object? finalizeError;
  final Object? rollbackError;

  int beginRemoveCalls = 0;
  _ScriptedRemoveTransaction? lastTransaction;

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    operations.add('unitStore.beginRemove');
    beginRemoveCalls += 1;
    final configuredError = beginRemoveError;
    if (configuredError != null) {
      throw configuredError;
    }

    final transaction = _ScriptedRemoveTransaction(
      names: names,
      operations: operations,
      applyError: applyError,
      finalizeError: finalizeError,
      rollbackError: rollbackError,
    );
    lastTransaction = transaction;
    return transaction;
  }

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) {
    throw UnsupportedError('Install is not used by cancel tests.');
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) {
    throw UnsupportedError('Install is not used by cancel tests.');
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    final transaction = await beginRemove(names);
    await transaction.apply();
    await transaction.finalize();
  }
}

final class _ScriptedRemoveTransaction
    implements LinuxSystemdUnitRemoveTransaction {
  _ScriptedRemoveTransaction({
    required this.names,
    required this.operations,
    this.applyError,
    this.finalizeError,
    this.rollbackError,
  });

  @override
  final LinuxSystemdUnitNames names;

  final List<String> operations;
  final Object? applyError;
  final Object? finalizeError;
  final Object? rollbackError;

  int applyCalls = 0;
  int finalizeCalls = 0;
  int rollbackCalls = 0;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    operations.add('remove.apply');
    applyCalls += 1;
    final configuredError = applyError;
    if (configuredError != null) {
      throw configuredError;
    }
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    operations.add('remove.finalize');
    finalizeCalls += 1;
    final configuredError = finalizeError;
    if (configuredError != null) {
      throw configuredError;
    }
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    operations.add('remove.rollback');
    rollbackCalls += 1;
    final configuredError = rollbackError;
    if (configuredError != null) {
      throw configuredError;
    }
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _ScriptedRegistryStore
    implements LinuxSystemdScheduleRegistryStore {
  _ScriptedRegistryStore({
    required LinuxSystemdScheduleRegistry initial,
    List<String>? operations,
    this.failReplaceCall,
    this.replaceBeforeThrow = false,
    this.replaceError,
  }) : current = initial,
       operations = operations ?? <String>[];

  final List<String> operations;
  final int? failReplaceCall;
  final bool replaceBeforeThrow;
  final Object? replaceError;

  LinuxSystemdScheduleRegistry current;
  final List<LinuxSystemdScheduleRegistry> replacements =
      <LinuxSystemdScheduleRegistry>[];
  int replaceCalls = 0;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    operations.add('registry.load');
    return current;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    operations.add('registry.replace');
    replaceCalls += 1;
    replacements.add(next);

    if (replaceBeforeThrow) {
      current = next;
    }
    if (replaceCalls == failReplaceCall) {
      throw replaceError ?? StateError('replace failure');
    }

    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() {
    throw UnsupportedError('Quarantine is not used by cancel tests.');
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() {
    throw UnsupportedError('Discovery is not used by cancel tests.');
  }
}

final class _ScriptedRunner implements LinuxProcessRunner {
  _ScriptedRunner({List<String>? operations})
    : operations = operations ?? <String>[];

  final List<String> operations;
  final Queue<_RunnerAction> _actions = Queue<_RunnerAction>();

  void enqueueSuccess() {
    _actions.addLast(const _RunnerResult(exitCode: 0));
  }

  void enqueueExit(int exitCode) {
    _actions.addLast(_RunnerResult(exitCode: exitCode));
  }

  void enqueueError(Object error) {
    _actions.addLast(_RunnerError(error, StackTrace.current));
  }

  void enqueueStatus(
    String scheduleId, {
    required bool enabled,
    required bool active,
  }) {
    final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
    _actions.addLast(
      _RunnerResult(
        exitCode: 0,
        stdout: <String>[
          'Id=${names.timerFileName}',
          'LoadState=loaded',
          'ActiveState=${active ? 'active' : 'inactive'}',
          'SubState=${active ? 'waiting' : 'dead'}',
          'UnitFileState=${enabled ? 'enabled' : 'disabled'}',
          'Result=success',
          '',
        ].join('\n'),
      ),
    );
  }

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    operations.add(_operationFor(request));

    if (_actions.isEmpty) {
      throw StateError('No scripted runner action remains.');
    }

    final action = _actions.removeFirst();
    if (action is _RunnerError) {
      Error.throwWithStackTrace(action.error, action.stackTrace);
    }

    final result = action as _RunnerResult;
    return LinuxProcessResult(
      executable: request.executable,
      arguments: request.arguments,
      pid: 9057,
      exitCode: result.exitCode,
      duration: const Duration(milliseconds: 2),
      stdout: _output(result.stdout),
      stderr: _output(''),
    );
  }

  String _operationFor(LinuxProcessRequest request) {
    if (request.arguments.contains('daemon-reload')) {
      return 'driver.reload';
    }
    if (request.arguments.contains('show')) {
      return 'driver.status';
    }
    if (request.arguments.contains('enable')) {
      return 'driver.enable';
    }
    if (request.arguments.contains('disable')) {
      return 'driver.disable';
    }
    return 'driver.process';
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

sealed class _RunnerAction {
  const _RunnerAction();
}

final class _RunnerResult extends _RunnerAction {
  const _RunnerResult({required this.exitCode, this.stdout = ''});

  final int exitCode;
  final String stdout;
}

final class _RunnerError extends _RunnerAction {
  const _RunnerError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

final class _NoopFactory implements LinuxNotificationDeliveryCommandFactory {
  const _NoopFactory();

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    throw UnsupportedError('Factory is not used by cancel tests.');
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

enum _PreviousPair { serviceOnly, timerOnly, complete }

const String _directory = '/config/systemd/user';
const String _oldService = '[Service]\nOldService=true\n';
const String _oldTimer = '[Timer]\nOldTimer=true\n';
const int _oldServiceMode = 0x180;
const int _oldTimerMode = 0x1A0;

void _seedCompletePair(
  FakeLinuxSystemdFileSystem fileSystem,
  String scheduleId,
) {
  _seedPair(fileSystem, scheduleId, _PreviousPair.complete);
}

void _seedPair(
  FakeLinuxSystemdFileSystem fileSystem,
  String scheduleId,
  _PreviousPair pair,
) {
  if (pair == _PreviousPair.serviceOnly || pair == _PreviousPair.complete) {
    fileSystem.seedFile(
      _servicePath(scheduleId),
      utf8.encode(_oldService),
      mode: _oldServiceMode,
    );
  }
  if (pair == _PreviousPair.timerOnly || pair == _PreviousPair.complete) {
    fileSystem.seedFile(
      _timerPath(scheduleId),
      utf8.encode(_oldTimer),
      mode: _oldTimerMode,
    );
  }
}

void _expectPair(
  FakeLinuxSystemdFileSystem fileSystem,
  String scheduleId,
  _PreviousPair pair,
) {
  final hasService =
      pair == _PreviousPair.serviceOnly || pair == _PreviousPair.complete;
  final hasTimer =
      pair == _PreviousPair.timerOnly || pair == _PreviousPair.complete;

  expect(fileSystem.containsPath(_servicePath(scheduleId)), hasService);
  expect(fileSystem.containsPath(_timerPath(scheduleId)), hasTimer);

  if (hasService) {
    expect(fileSystem.textOf(_servicePath(scheduleId)), _oldService);
    expect(fileSystem.modeOf(_servicePath(scheduleId)), _oldServiceMode);
  }
  if (hasTimer) {
    expect(fileSystem.textOf(_timerPath(scheduleId)), _oldTimer);
    expect(fileSystem.modeOf(_timerPath(scheduleId)), _oldTimerMode);
  }
}

String _servicePath(String scheduleId) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
  return '$_directory/${names.serviceFileName}';
}

String _timerPath(String scheduleId) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
  return '$_directory/${names.timerFileName}';
}

LinuxSystemdScheduleRegistry _registryWithEntry(
  String scheduleId, {
  int generation = 1,
}) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: generation,
    entries: <LinuxSystemdScheduleRegistryEntry>[
      LinuxSystemdScheduleRegistryEntry(
        scheduleId: scheduleId,
        owner: NotificationOwner(
          type: NotificationOwnerType.task,
          id: 'owner-$scheduleId',
        ),
        timerName: LinuxSystemdTimerName.parse(names.timerFileName),
        serviceFileName: names.serviceFileName,
        scheduledAtUtc: DateTime.utc(2026, 8, 2, 10),
        requestFingerprint: _fingerprint('a'),
      ),
    ],
  );
}

String _fingerprint(String character) {
  return List<String>.filled(64, character).join();
}

LinuxProcessCancellationException _cancellation() {
  return LinuxProcessCancellationException(
    executable: 'systemctl',
    arguments: const <String>['--user', '--no-pager', 'daemon-reload'],
    pid: 9057,
    duration: const Duration(milliseconds: 3),
  );
}

Future<LinuxSystemdNotificationSchedulerException> _expectCancelFailure(
  Future<void> Function() action,
  LinuxSystemdNotificationSchedulerFailure failure,
) async {
  try {
    await action();
    fail('Expected LinuxSystemdNotificationSchedulerException.');
  } on LinuxSystemdNotificationSchedulerException catch (error) {
    expect(error.operation, LinuxSystemdNotificationSchedulerOperation.cancel);
    expect(error.failure, failure);
    return error;
  }
}

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}
