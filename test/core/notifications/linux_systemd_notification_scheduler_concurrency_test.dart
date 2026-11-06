import 'dart:async';
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

  group('keyed read-operation concurrency', () {
    test('same schedule ID operations are FIFO and never overlap', () async {
      final harness = _Harness(
        now: now,
        registry: LinuxSystemdScheduleRegistry.empty(),
      );
      final first = harness.unitStore.addBlock('task-lock-same');
      final second = harness.unitStore.addBlock('task-lock-same');

      final firstFuture = harness.scheduler.cancel('task-lock-same');
      await first.entered.future;

      final secondFuture = harness.scheduler.cancel('task-lock-same');
      await _settle();

      expect(second.entered.isCompleted, isFalse);
      expect(harness.unitStore.maxActiveBeginCalls, 1);

      first.release.complete();
      await second.entered.future;

      final firstFinalize = harness.unitStore.events.indexOf(
        'finalize:task-lock-same:1',
      );
      final secondBegin = harness.unitStore.events.indexOf(
        'begin:task-lock-same:2',
      );

      expect(firstFinalize, greaterThanOrEqualTo(0));
      expect(secondBegin, greaterThan(firstFinalize));
      expect(harness.unitStore.maxActiveBeginCalls, 1);

      second.release.complete();
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);
    });

    test('different schedule IDs overlap under the global read lock', () async {
      final harness = _Harness(
        now: now,
        registry: LinuxSystemdScheduleRegistry.empty(),
      );
      final left = harness.unitStore.addBlock('task-lock-left');
      final right = harness.unitStore.addBlock('task-lock-right');

      final leftFuture = harness.scheduler.cancel('task-lock-left');
      final rightFuture = harness.scheduler.cancel('task-lock-right');

      await Future.wait(<Future<void>>[
        left.entered.future,
        right.entered.future,
      ]);

      expect(harness.unitStore.maxActiveBeginCalls, 2);

      left.release.complete();
      right.release.complete();
      await Future.wait(<Future<void>>[leftFuture, rightFuture]);
    });
  });

  group('writer-preferring global lock', () {
    test('cancelByOwner waits for an active read operation', () async {
      final owner = _owner('writer-waits');
      final ownerScheduleId = 'task-owner-writer-waits';
      final registry = _registry(
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(ownerScheduleId, owner),
        ],
      );
      final harness = _Harness(now: now, registry: registry);
      final activeRead = harness.unitStore.addBlock('task-active-read');

      final readFuture = harness.scheduler.cancel('task-active-read');
      await activeRead.entered.future;

      final writerFuture = harness.scheduler.cancelByOwner(owner);
      await _settle();

      expect(harness.registryStore.loadCount, 1);
      expect(
        harness.unitStore.beginOrder,
        orderedEquals(<String>['task-active-read']),
      );

      activeRead.release.complete();
      await readFuture;
      await writerFuture;

      expect(harness.registryStore.loadCount, 2);
      expect(
        harness.unitStore.beginOrder,
        orderedEquals(<String>['task-active-read', ownerScheduleId]),
      );
    });

    test('new reads wait behind an already queued writer', () async {
      final owner = _owner('writer-priority');
      final ownerScheduleId = 'task-owner-writer-priority';
      final registry = _registry(
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry(ownerScheduleId, owner),
        ],
      );
      final harness = _Harness(now: now, registry: registry);
      final activeRead = harness.unitStore.addBlock(
        'task-priority-active-read',
      );
      final writerBlock = harness.unitStore.addBlock(ownerScheduleId);
      final lateRead = harness.unitStore.addBlock('task-priority-late-read');

      final activeFuture = harness.scheduler.cancel(
        'task-priority-active-read',
      );
      await activeRead.entered.future;

      final writerFuture = harness.scheduler.cancelByOwner(owner);
      await _settle();

      final lateFuture = harness.scheduler.cancel('task-priority-late-read');
      await _settle();

      expect(harness.registryStore.loadCount, 1);
      expect(lateRead.entered.isCompleted, isFalse);

      activeRead.release.complete();
      await activeFuture;
      await writerBlock.entered.future;

      expect(harness.registryStore.loadCount, 2);
      expect(lateRead.entered.isCompleted, isFalse);

      writerBlock.release.complete();
      await writerFuture;
      await lateRead.entered.future;

      expect(harness.registryStore.loadCount, 3);

      lateRead.release.complete();
      await lateFuture;
    });
  });

  group('owner cancellation batch', () {
    test('matches owners exactly and cancels sorted schedule IDs', () async {
      final target = _owner('target');
      final nearMiss = _owner('target-extra');
      final registry = _registry(
        generation: 10,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry('task-owner-zeta', _owner('target')),
          _entry('task-owner-near', nearMiss),
          _entry('task-owner-alpha', _owner('target')),
          _entry('task-owner-middle', _owner('target')),
        ],
      );
      final harness = _Harness(now: now, registry: registry);

      await harness.scheduler.cancelByOwner(target);

      expect(harness.registryStore.loadCount, 1);
      expect(
        harness.unitStore.beginOrder,
        orderedEquals(<String>[
          'task-owner-alpha',
          'task-owner-middle',
          'task-owner-zeta',
        ]),
      );
      expect(harness.registryStore.replacements, hasLength(3));
      expect(harness.registryStore.current.generation, 13);
      expect(
        harness.registryStore.current.entries.map((entry) => entry.scheduleId),
        orderedEquals(<String>['task-owner-near']),
      );
    });

    test('no exact owner matches is idempotent', () async {
      final initial = _registry(
        generation: 4,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry('task-owner-unrelated', _owner('unrelated')),
        ],
      );
      final harness = _Harness(now: now, registry: initial);

      await harness.scheduler.cancelByOwner(_owner('missing'));

      expect(harness.registryStore.loadCount, 1);
      expect(harness.unitStore.beginOrder, isEmpty);
      expect(harness.registryStore.replacements, isEmpty);
      expect(harness.registryStore.current, same(initial));
    });

    test('first failed schedule stops the sorted batch', () async {
      final target = _owner('stop-batch');
      final registry = _registry(
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry('task-owner-gamma', target),
          _entry('task-owner-beta', target),
          _entry('task-owner-alpha', target),
        ],
      );
      final harness = _Harness(now: now, registry: registry)
        ..unitStore.failBegin(
          'task-owner-beta',
          StateError('beta begin failure'),
        );

      await expectLater(
        harness.scheduler.cancelByOwner(target),
        throwsA(
          isA<LinuxSystemdNotificationSchedulerException>().having(
            (error) => error.failure,
            'failure',
            LinuxSystemdNotificationSchedulerFailure.partialOwnerCancellation,
          ),
        ),
      );

      expect(
        harness.unitStore.beginOrder,
        orderedEquals(<String>['task-owner-alpha', 'task-owner-beta']),
      );
      expect(
        harness.registryStore.current.entries.map((entry) => entry.scheduleId),
        containsAll(<String>['task-owner-beta', 'task-owner-gamma']),
      );
      expect(harness.unitStore.beginOrder, isNot(contains('task-owner-gamma')));
    });

    test(
      'partial exception has failing ID and immutable completed IDs',
      () async {
        final target = _owner('partial-evidence');
        final registry = _registry(
          entries: <LinuxSystemdScheduleRegistryEntry>[
            _entry('task-owner-gamma-evidence', target),
            _entry('task-owner-beta-evidence', target),
            _entry('task-owner-alpha-evidence', target),
          ],
        );
        final harness = _Harness(now: now, registry: registry)
          ..unitStore.failBegin(
            'task-owner-beta-evidence',
            StateError('beta evidence failure'),
          );

        LinuxSystemdNotificationSchedulerException? actual;
        try {
          await harness.scheduler.cancelByOwner(target);
          fail('Expected partial owner cancellation.');
        } on LinuxSystemdNotificationSchedulerException catch (error) {
          actual = error;
        }

        expect(actual, isNotNull);
        expect(
          actual.operation,
          LinuxSystemdNotificationSchedulerOperation.cancelByOwner,
        );
        expect(
          actual.failure,
          LinuxSystemdNotificationSchedulerFailure.partialOwnerCancellation,
        );
        expect(actual.scheduleId, 'task-owner-beta-evidence');
        expect(actual.owner, same(target));
        expect(
          actual.completedScheduleIds,
          orderedEquals(<String>['task-owner-alpha-evidence']),
        );
        expect(
          () => actual!.completedScheduleIds.add(
            'task-owner-unexpected-evidence',
          ),
          throwsUnsupportedError,
        );
        expect(actual.cause, isNotNull);
      },
    );
  });
}

final class _Harness {
  _Harness({
    required DateTime now,
    required LinuxSystemdScheduleRegistry registry,
  }) {
    registryStore = _MemoryRegistryStore(registry);
    unitStore = _BlockingUnitStore();

    for (final entry in registry.entries) {
      unitStore.track(entry.scheduleId);
    }

    scheduler = LinuxSystemdNotificationScheduler(
      clock: FixedAppClock(utcValue: now, localValue: now),
      gateway: const _NoopGateway(),
      commandFactory: const _NoopFactory(),
      renderer: const LinuxSystemdUnitRenderer(),
      unitStore: unitStore,
      driver: LinuxSystemdUserDriver(processRunner: _AutomaticProcessRunner()),
      registryStore: registryStore,
      fingerprint: LinuxNotificationRequestFingerprint(),
    );
  }

  late final _MemoryRegistryStore registryStore;
  late final _BlockingUnitStore unitStore;
  late final LinuxSystemdNotificationScheduler scheduler;
}

final class _BlockHandle {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();
}

final class _BlockingUnitStore implements LinuxSystemdUnitStore {
  final Map<String, String> _labelsByBaseName = <String, String>{};
  final Map<String, List<_BlockHandle>> _blocks =
      <String, List<_BlockHandle>>{};
  final Map<String, Object> _beginErrors = <String, Object>{};
  final Map<String, int> _callCounts = <String, int>{};

  final List<String> beginOrder = <String>[];
  final List<String> events = <String>[];

  int _activeBeginCalls = 0;
  int maxActiveBeginCalls = 0;

  void track(String scheduleId) {
    final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
    _labelsByBaseName[names.baseName] = scheduleId;
  }

  _BlockHandle addBlock(String scheduleId) {
    track(scheduleId);
    final handle = _BlockHandle();
    _blocks.putIfAbsent(scheduleId, () => <_BlockHandle>[]).add(handle);
    return handle;
  }

  void failBegin(String scheduleId, Object error) {
    track(scheduleId);
    _beginErrors[scheduleId] = error;
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    final scheduleId = _labelsByBaseName[names.baseName] ?? names.baseName;
    final call = (_callCounts[scheduleId] ?? 0) + 1;
    _callCounts[scheduleId] = call;
    beginOrder.add(scheduleId);
    events.add('begin:$scheduleId:$call');

    final blocks = _blocks[scheduleId];
    final block = blocks == null || blocks.isEmpty ? null : blocks.removeAt(0);

    _activeBeginCalls += 1;
    if (_activeBeginCalls > maxActiveBeginCalls) {
      maxActiveBeginCalls = _activeBeginCalls;
    }

    if (block != null) {
      if (!block.entered.isCompleted) {
        block.entered.complete();
      }
      await block.release.future;
    }

    _activeBeginCalls -= 1;

    final configuredError = _beginErrors[scheduleId];
    if (configuredError != null) {
      throw configuredError;
    }

    return _RemoveTransaction(
      names: names,
      scheduleId: scheduleId,
      call: call,
      events: events,
    );
  }

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) {
    throw UnsupportedError('Install is not used by concurrency tests.');
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) {
    throw UnsupportedError('Install is not used by concurrency tests.');
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    final transaction = await beginRemove(names);
    await transaction.apply();
    await transaction.finalize();
  }
}

final class _RemoveTransaction implements LinuxSystemdUnitRemoveTransaction {
  _RemoveTransaction({
    required this.names,
    required this.scheduleId,
    required this.call,
    required this.events,
  });

  @override
  final LinuxSystemdUnitNames names;

  final String scheduleId;
  final int call;
  final List<String> events;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    events.add('apply:$scheduleId:$call');
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    events.add('finalize:$scheduleId:$call');
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    events.add('rollback:$scheduleId:$call');
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _MemoryRegistryStore implements LinuxSystemdScheduleRegistryStore {
  _MemoryRegistryStore(this.current);

  LinuxSystemdScheduleRegistry current;
  final List<LinuxSystemdScheduleRegistry> replacements =
      <LinuxSystemdScheduleRegistry>[];

  int loadCount = 0;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    loadCount += 1;
    return current;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    replacements.add(next);
    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() {
    throw UnsupportedError('Quarantine is not used by concurrency tests.');
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() {
    throw UnsupportedError('Discovery is not used by concurrency tests.');
  }
}

final class _AutomaticProcessRunner implements LinuxProcessRunner {
  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    final isStatus = request.arguments.contains('show');
    final timerName = request.arguments.firstWhere(
      (argument) => argument.endsWith('.timer'),
      orElse: () => 'borj-notification-0000000000000000.timer',
    );
    final stdout = isStatus
        ? <String>[
            'Id=$timerName',
            'LoadState=loaded',
            'ActiveState=inactive',
            'SubState=dead',
            'UnitFileState=disabled',
            'Result=success',
            '',
          ].join('\n')
        : '';
    final stdoutBytes = utf8.encode(stdout);

    return LinuxProcessResult(
      executable: request.executable,
      arguments: request.arguments,
      pid: 1058,
      exitCode: 0,
      duration: const Duration(milliseconds: 1),
      stdout: LinuxBoundedOutput(
        text: stdout,
        totalBytes: stdoutBytes.length,
        retainedBytes: stdoutBytes.length,
        droppedBytes: 0,
        truncated: false,
        malformedUtf8: false,
      ),
      stderr: LinuxBoundedOutput(
        text: '',
        totalBytes: 0,
        retainedBytes: 0,
        droppedBytes: 0,
        truncated: false,
        malformedUtf8: false,
      ),
    );
  }
}

final class _NoopFactory implements LinuxNotificationDeliveryCommandFactory {
  const _NoopFactory();

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    throw UnsupportedError('Factory is not used by concurrency tests.');
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

NotificationOwner _owner(String id) {
  return NotificationOwner(type: NotificationOwnerType.task, id: id);
}

LinuxSystemdScheduleRegistryEntry _entry(
  String scheduleId,
  NotificationOwner owner,
) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner: owner,
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: DateTime.utc(2026, 8, 2, 10),
    requestFingerprint: _fingerprint('a'),
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

String _fingerprint(String character) {
  return List<String>.filled(64, character).join();
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
