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

  group('pre-apply failures', () {
    test('command factory failure does not begin or roll back units', () async {
      final primary = StateError('factory failure');
      final harness = _Harness(now: now, factoryError: primary);

      final error = await _expectSchedulerFailure(
        () => harness.scheduler.schedule(_futureRequest(now, 'factory')),
        LinuxSystemdNotificationSchedulerFailure.commandFactoryFailed,
      );

      expect(error.cause, same(primary));
      expect(harness.unitStore.beginInstallCalls, 0);
      expect(harness.unitStore.lastTransaction, isNull);
      expect(
        harness.operations,
        orderedEquals(<String>['registry.load', 'factory.create']),
      );
      expect(harness.registryStore.replacements, isEmpty);
    });

    test('render identity failure does not begin or roll back units', () async {
      final harness = _Harness(
        now: now,
        factoryScheduleKey: 'different-schedule-key',
      );

      await _expectSchedulerFailure(
        () => harness.scheduler.schedule(_futureRequest(now, 'render')),
        LinuxSystemdNotificationSchedulerFailure.renderFailed,
      );

      expect(harness.unitStore.beginInstallCalls, 0);
      expect(harness.unitStore.lastTransaction, isNull);
      expect(
        harness.operations,
        orderedEquals(<String>['registry.load', 'factory.create']),
      );
      expect(harness.registryStore.replacements, isEmpty);
    });

    test('begin install failure does not run rollback', () async {
      final primary = StateError('begin install failure');
      final harness = _Harness(now: now, beginInstallError: primary);

      final error = await _expectSchedulerFailure(
        () => harness.scheduler.schedule(_futureRequest(now, 'begin')),
        LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      );

      expect(error.cause, same(primary));
      expect(harness.unitStore.beginInstallCalls, 1);
      expect(harness.unitStore.lastTransaction, isNull);
      expect(
        harness.operations,
        orderedEquals(<String>[
          'registry.load',
          'factory.create',
          'unitStore.beginInstall',
        ]),
      );
    });
  });

  group('post-apply rollback', () {
    test(
      'apply failure rolls back, reloads, and re-enables previous timer',
      () async {
        final operations = <String>[];
        final primary = StateError('apply failure');
        final request = _futureRequest(now, 'apply');
        final previous = _previousRegistry(request);
        final harness =
            _Harness(
                now: now,
                operations: operations,
                registry: previous,
                applyError: primary,
              )
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: true, active: true);

        final error = await _expectSchedulerFailure(
          () => harness.scheduler.schedule(request),
          LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        );

        expect(error.cause, same(primary));
        expect(
          operations,
          orderedEquals(<String>[
            'registry.load',
            'factory.create',
            'unitStore.beginInstall',
            'install.apply',
            'install.rollback',
            'driver.reload',
            'driver.enable',
            'driver.status',
          ]),
        );
        expect(harness.registryStore.replacements, isEmpty);
        expect(harness.unitStore.lastTransaction!.rollbackCalls, 1);
      },
    );

    test('daemon reload failure performs exact rollback order', () async {
      final operations = <String>[];
      final request = _futureRequest(now, 'reload');
      final previous = _previousRegistry(request);
      final harness =
          _Harness(now: now, operations: operations, registry: previous)
            ..runner.enqueueExit(1)
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(request, enabled: false, active: false)
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(request, enabled: true, active: true);

      await _expectSchedulerFailure(
        () => harness.scheduler.schedule(request),
        LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
      );

      expect(
        operations,
        orderedEquals(<String>[
          'registry.load',
          'factory.create',
          'unitStore.beginInstall',
          'install.apply',
          'driver.reload',
          'driver.disable',
          'driver.status',
          'install.rollback',
          'driver.reload',
          'driver.enable',
          'driver.status',
        ]),
      );
      expect(harness.registryStore.replacements, isEmpty);
    });

    test(
      'enable failure disables, restores units, reloads, and re-enables',
      () async {
        final operations = <String>[];
        final request = _futureRequest(now, 'enable');
        final previous = _previousRegistry(request);
        final harness =
            _Harness(now: now, operations: operations, registry: previous)
              ..runner.enqueueSuccess()
              ..runner.enqueueExit(1)
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: false, active: false)
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: true, active: true);

        await _expectSchedulerFailure(
          () => harness.scheduler.schedule(request),
          LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        );

        expect(
          operations,
          orderedEquals(<String>[
            'registry.load',
            'factory.create',
            'unitStore.beginInstall',
            'install.apply',
            'driver.reload',
            'driver.enable',
            'driver.disable',
            'driver.status',
            'install.rollback',
            'driver.reload',
            'driver.enable',
            'driver.status',
          ]),
        );
      },
    );

    test(
      'registry replace failure restores inventory with higher generation',
      () async {
        final operations = <String>[];
        final request = _futureRequest(now, 'registry');
        final previous = _previousRegistry(request, generation: 12);
        final primary = StateError('registry replace failure');
        final harness =
            _Harness(
                now: now,
                operations: operations,
                registry: previous,
                failReplaceCall: 1,
                replaceBeforeThrow: true,
                replaceError: primary,
              )
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: true, active: true)
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: false, active: false)
              ..runner.enqueueSuccess()
              ..runner.enqueueSuccess()
              ..runner.enqueueStatus(request, enabled: true, active: true);

        final error = await _expectSchedulerFailure(
          () => harness.scheduler.schedule(request),
          LinuxSystemdNotificationSchedulerFailure.registryFailed,
        );

        expect(error.cause, same(primary));
        expect(harness.registryStore.current.entries, previous.entries);
        expect(
          harness.registryStore.current.generation,
          greaterThan(previous.generation),
        );
        expect(harness.registryStore.replacements, hasLength(2));
        expect(
          operations,
          containsAllInOrder(<String>[
            'registry.replace',
            'driver.disable',
            'install.rollback',
            'driver.reload',
            'registry.load',
            'registry.replace',
            'driver.enable',
          ]),
        );
      },
    );

    test('finalize failure restores registry and previous timer', () async {
      final operations = <String>[];
      final request = _futureRequest(now, 'finalize');
      final previous = _previousRegistry(request, generation: 20);
      final primary = StateError('finalize failure');
      final harness =
          _Harness(
              now: now,
              operations: operations,
              registry: previous,
              finalizeError: primary,
            )
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(request, enabled: true, active: true)
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(request, enabled: false, active: false)
            ..runner.enqueueSuccess()
            ..runner.enqueueSuccess()
            ..runner.enqueueStatus(request, enabled: true, active: true);

      final error = await _expectSchedulerFailure(
        () => harness.scheduler.schedule(request),
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
        operations,
        containsAllInOrder(<String>[
          'registry.replace',
          'install.finalize',
          'driver.disable',
          'install.rollback',
          'driver.reload',
          'registry.load',
          'registry.replace',
          'driver.enable',
        ]),
      );
    });
  });

  group('real retained install restoration', () {
    for (final pair in _PreviousPair.values) {
      test(
        'registry failure restores exact ${pair.name} prior file pair',
        () async {
          final fileSystem = FakeLinuxSystemdFileSystem();
          final request = _futureRequest(now, 'pair-${_pairSlug(pair)}');
          final names = LinuxSystemdUnitNames.forScheduleKey(
            request.scheduleId,
          );
          _seedPair(fileSystem, names, pair);

          final registryStore = _ScriptedRegistryStore(
            initial: LinuxSystemdScheduleRegistry.empty(),
            failReplaceCall: 1,
            replaceBeforeThrow: true,
            replaceError: StateError('registry failure'),
          );
          final runner = _ScriptedRunner()
            ..enqueueSuccess()
            ..enqueueSuccess()
            ..enqueueStatus(request, enabled: true, active: true)
            ..enqueueSuccess()
            ..enqueueStatus(request, enabled: false, active: false)
            ..enqueueSuccess();
          final scheduler = LinuxSystemdNotificationScheduler(
            clock: FixedAppClock(utcValue: now, localValue: now),
            gateway: const _NoopGateway(),
            commandFactory: const _DeliveryFactory(),
            renderer: const LinuxSystemdUnitRenderer(),
            unitStore: LinuxSystemdUserUnitStore(
              pathResolver: LinuxSystemdUserUnitPathResolver(
                const _MapEnvironment(<String, String>{
                  'XDG_CONFIG_HOME': '/config',
                }),
              ),
              fileSystem: fileSystem,
              transactionIdFactory: () => 'schedule-rollback',
            ),
            driver: LinuxSystemdUserDriver(processRunner: runner),
            registryStore: registryStore,
            fingerprint: LinuxNotificationRequestFingerprint(),
          );

          await _expectSchedulerFailure(
            () => scheduler.schedule(request),
            LinuxSystemdNotificationSchedulerFailure.registryFailed,
          );

          _expectPair(fileSystem, names, pair);
          _expectNoArtifacts(fileSystem, names);
          expect(registryStore.current.entries, isEmpty);
          expect(registryStore.current.generation, greaterThan(0));
        },
      );
    }
  });

  group('cancellation preservation', () {
    test('successful rollback rethrows the identical cancellation', () async {
      final request = _futureRequest(now, 'cancel');
      final cancellation = _cancellation();
      final harness = _Harness(now: now)
        ..runner.enqueueError(cancellation)
        ..runner.enqueueSuccess()
        ..runner.enqueueStatus(request, enabled: false, active: false)
        ..runner.enqueueSuccess();

      Object? caught;
      try {
        await harness.scheduler.schedule(request);
        fail('Expected cancellation.');
      } catch (error) {
        caught = error;
      }

      expect(caught, same(cancellation));
      expect(harness.unitStore.lastTransaction!.rollbackCalls, 1);
      expect(harness.registryStore.replacements, isEmpty);
    });

    test('rollback failure keeps cancellation as primary cause', () async {
      final request = _futureRequest(now, 'cancel-rollback-fails');
      final cancellation = _cancellation();
      final rollbackError = StateError('rollback failure');
      final harness = _Harness(now: now, rollbackError: rollbackError)
        ..runner.enqueueError(cancellation)
        ..runner.enqueueSuccess()
        ..runner.enqueueStatus(request, enabled: false, active: false)
        ..runner.enqueueSuccess();

      final error = await _expectSchedulerFailure(
        () => harness.scheduler.schedule(request),
        LinuxSystemdNotificationSchedulerFailure.rollbackFailed,
      );

      expect(error.cause, same(cancellation));
      expect(error.rollbackFailures, isNotEmpty);
      expect(
        error.rollbackFailures.map((failure) => failure.step),
        contains('rollback-install-transaction'),
      );
      expect(
        error.rollbackFailures
            .map((failure) => failure.error)
            .where((failure) => identical(failure, rollbackError)),
        isNotEmpty,
      );
    });
  });
}

final class _Harness {
  _Harness({
    required DateTime now,
    List<String>? operations,
    LinuxSystemdScheduleRegistry? registry,
    Object? factoryError,
    String? factoryScheduleKey,
    Object? beginInstallError,
    Object? applyError,
    Object? finalizeError,
    Object? rollbackError,
    int? failReplaceCall,
    bool replaceBeforeThrow = false,
    Object? replaceError,
  }) : operations = operations ?? <String>[] {
    factory = _ScriptedFactory(
      operations: this.operations,
      error: factoryError,
      scheduleKey: factoryScheduleKey,
    );
    unitStore = _ScriptedUnitStore(
      operations: this.operations,
      beginError: beginInstallError,
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

  final List<String> operations;
  late final _ScriptedFactory factory;
  late final _ScriptedUnitStore unitStore;
  late final _ScriptedRegistryStore registryStore;
  late final _ScriptedRunner runner;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _ScriptedFactory
    implements LinuxNotificationDeliveryCommandFactory {
  const _ScriptedFactory({
    required this.operations,
    this.error,
    this.scheduleKey,
  });

  final List<String> operations;
  final Object? error;
  final String? scheduleKey;

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    operations.add('factory.create');
    final configuredError = error;
    if (configuredError != null) {
      throw configuredError;
    }

    return LinuxSystemdNotificationUnit(
      scheduleKey: scheduleKey ?? request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: '/opt/borj/borj',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
  }
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
      executablePath: '/opt/borj/borj',
      arguments: <String>['--deliver-notification', request.scheduleId],
    );
  }
}

final class _ScriptedUnitStore implements LinuxSystemdUnitStore {
  _ScriptedUnitStore({
    required this.operations,
    this.beginError,
    this.applyError,
    this.finalizeError,
    this.rollbackError,
  });

  final List<String> operations;
  final Object? beginError;
  final Object? applyError;
  final Object? finalizeError;
  final Object? rollbackError;

  int beginInstallCalls = 0;
  _ScriptedInstallTransaction? lastTransaction;

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    operations.add('unitStore.beginInstall');
    beginInstallCalls += 1;
    final configuredError = beginError;
    if (configuredError != null) {
      throw configuredError;
    }

    final baseName = units.serviceFileName.substring(
      0,
      units.serviceFileName.length - '.service'.length,
    );
    final transaction = _ScriptedInstallTransaction(
      names: LinuxSystemdUnitNames.parseBaseName(baseName),
      operations: operations,
      applyError: applyError,
      finalizeError: finalizeError,
      rollbackError: rollbackError,
    );
    lastTransaction = transaction;
    return transaction;
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) {
    throw UnsupportedError('Remove is not used by this test.');
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) async {
    final transaction = await beginInstall(units);
    await transaction.apply();
    await transaction.finalize();
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) {
    throw UnsupportedError('Remove is not used by this test.');
  }
}

final class _ScriptedInstallTransaction
    implements LinuxSystemdUnitInstallTransaction {
  _ScriptedInstallTransaction({
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
    operations.add('install.apply');
    applyCalls += 1;
    final configuredError = applyError;
    if (configuredError != null) {
      throw configuredError;
    }
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    operations.add('install.finalize');
    finalizeCalls += 1;
    final configuredError = finalizeError;
    if (configuredError != null) {
      throw configuredError;
    }
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    operations.add('install.rollback');
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
    throw UnsupportedError('Quarantine is not used by this test.');
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() {
    throw UnsupportedError('Discovery is not used by this test.');
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
    NotificationRequest request, {
    required bool enabled,
    required bool active,
  }) {
    final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
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
      pid: 9042,
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

enum _PreviousPair { missing, serviceOnly, timerOnly, complete }

const String _directory = '/config/systemd/user';
const String _oldService = '[Service]\nOldService=true\n';
const String _oldTimer = '[Timer]\nOldTimer=true\n';
const int _oldServiceMode = 0x180;
const int _oldTimerMode = 0x1A0;
const String _transactionId = 'schedule-rollback';

String _pairSlug(_PreviousPair pair) {
  return switch (pair) {
    _PreviousPair.missing => 'missing',
    _PreviousPair.serviceOnly => 'service-only',
    _PreviousPair.timerOnly => 'timer-only',
    _PreviousPair.complete => 'complete',
  };
}

void _seedPair(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdUnitNames names,
  _PreviousPair pair,
) {
  if (pair == _PreviousPair.serviceOnly || pair == _PreviousPair.complete) {
    fileSystem.seedFile(
      _servicePath(names),
      utf8.encode(_oldService),
      mode: _oldServiceMode,
    );
  }

  if (pair == _PreviousPair.timerOnly || pair == _PreviousPair.complete) {
    fileSystem.seedFile(
      _timerPath(names),
      utf8.encode(_oldTimer),
      mode: _oldTimerMode,
    );
  }
}

void _expectPair(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdUnitNames names,
  _PreviousPair pair,
) {
  final hasService =
      pair == _PreviousPair.serviceOnly || pair == _PreviousPair.complete;
  final hasTimer =
      pair == _PreviousPair.timerOnly || pair == _PreviousPair.complete;

  expect(fileSystem.containsPath(_servicePath(names)), hasService);
  expect(fileSystem.containsPath(_timerPath(names)), hasTimer);

  if (hasService) {
    expect(fileSystem.textOf(_servicePath(names)), _oldService);
    expect(fileSystem.modeOf(_servicePath(names)), _oldServiceMode);
  }
  if (hasTimer) {
    expect(fileSystem.textOf(_timerPath(names)), _oldTimer);
    expect(fileSystem.modeOf(_timerPath(names)), _oldTimerMode);
  }
}

void _expectNoArtifacts(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdUnitNames names,
) {
  for (final path in <String>[
    '$_directory/.${names.serviceFileName}.$_transactionId.tmp',
    '$_directory/.${names.timerFileName}.$_transactionId.tmp',
    '$_directory/.${names.serviceFileName}.$_transactionId.bak',
    '$_directory/.${names.timerFileName}.$_transactionId.bak',
  ]) {
    expect(fileSystem.containsPath(path), isFalse);
  }
}

String _servicePath(LinuxSystemdUnitNames names) {
  return '$_directory/${names.serviceFileName}';
}

String _timerPath(LinuxSystemdUnitNames names) {
  return '$_directory/${names.timerFileName}';
}

NotificationRequest _futureRequest(DateTime now, String suffix) {
  return NotificationRequest(
    scheduleId: 'task-rollback-$suffix',
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    title: 'Rollback reminder',
    body: 'Rollback body',
    scheduledAtUtc: now.add(const Duration(hours: 2)),
    payload: const <String, String>{'route': '/tasks/42'},
  );
}

LinuxSystemdScheduleRegistry _previousRegistry(
  NotificationRequest request, {
  int generation = 5,
}) {
  final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: generation,
    entries: <LinuxSystemdScheduleRegistryEntry>[
      LinuxSystemdScheduleRegistryEntry(
        scheduleId: request.scheduleId,
        owner: request.owner,
        timerName: LinuxSystemdTimerName.parse(names.timerFileName),
        serviceFileName: names.serviceFileName,
        scheduledAtUtc: request.scheduledAtUtc.subtract(
          const Duration(hours: 1),
        ),
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
    pid: 9042,
    duration: const Duration(milliseconds: 3),
  );
}

Future<LinuxSystemdNotificationSchedulerException> _expectSchedulerFailure(
  Future<void> Function() action,
  LinuxSystemdNotificationSchedulerFailure failure,
) async {
  try {
    await action();
    fail('Expected LinuxSystemdNotificationSchedulerException.');
  } on LinuxSystemdNotificationSchedulerException catch (error) {
    expect(
      error.operation,
      LinuxSystemdNotificationSchedulerOperation.schedule,
    );
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
