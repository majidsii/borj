// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:borj/core/date_time/app_clock.dart';

import 'async_fifo_keyed_mutex.dart';
import 'async_writer_preferring_rw_lock.dart';
import 'linux_notification_delivery_command_factory.dart';
import 'linux_notification_request_fingerprint.dart';
import 'linux_process_exception.dart';
import 'linux_systemd_notification_scheduler_exception.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_schedule_registry.dart';
import 'linux_systemd_schedule_registry_exception.dart';
import 'linux_systemd_schedule_registry_store.dart';
import 'linux_systemd_timer_name.dart';
import 'linux_systemd_timer_status.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_unit_transaction.dart';
import 'linux_systemd_user_driver.dart';
import 'linux_systemd_user_unit_store_exception.dart';
import 'native_notification_gateway.dart';
import 'notification_delivery_policy.dart';
import 'notification_owner.dart';
import 'notification_payload_codec.dart';
import 'notification_request.dart';
import 'notification_scheduler.dart';
import 'stable_notification_id.dart';

final class LinuxSystemdNotificationScheduler implements NotificationScheduler {
  LinuxSystemdNotificationScheduler({
    required AppClock clock,
    required NativeNotificationGateway gateway,
    required LinuxNotificationDeliveryCommandFactory commandFactory,
    required LinuxSystemdUnitRenderer renderer,
    required LinuxSystemdUnitStore unitStore,
    required LinuxSystemdUserDriver driver,
    required LinuxSystemdScheduleRegistryStore registryStore,
    required LinuxNotificationRequestFingerprint fingerprint,
    AsyncWriterPreferringRwLock? globalLock,
    AsyncFifoKeyedMutex<String>? scheduleMutex,
  }) : _clock = clock,
       _gateway = gateway,
       _commandFactory = commandFactory,
       _renderer = renderer,
       _unitStore = unitStore,
       _driver = driver,
       _registryStore = registryStore,
       _fingerprint = fingerprint,
       _globalLock = globalLock ?? AsyncWriterPreferringRwLock(),
       _scheduleMutex = scheduleMutex ?? AsyncFifoKeyedMutex<String>();

  final AppClock _clock;
  final NativeNotificationGateway _gateway;
  final LinuxNotificationDeliveryCommandFactory _commandFactory;
  final LinuxSystemdUnitRenderer _renderer;
  final LinuxSystemdUnitStore _unitStore;
  final LinuxSystemdUserDriver _driver;
  final LinuxSystemdScheduleRegistryStore _registryStore;
  final LinuxNotificationRequestFingerprint _fingerprint;
  final AsyncWriterPreferringRwLock _globalLock;
  final AsyncFifoKeyedMutex<String> _scheduleMutex;

  @override
  Future<void> schedule(NotificationRequest request) {
    return _globalLock.runRead(
      () => _scheduleMutex.synchronized(
        request.scheduleId,
        () => _scheduleUnlocked(request),
      ),
    );
  }

  @override
  Future<void> cancel(String scheduleId) {
    return _globalLock.runRead(
      () => _scheduleMutex.synchronized(
        scheduleId,
        () => _cancelUnlocked(
          scheduleId,
          operation: LinuxSystemdNotificationSchedulerOperation.cancel,
        ),
      ),
    );
  }

  @override
  Future<void> cancelByOwner(NotificationOwner owner) {
    return _globalLock.runWrite(() => _cancelByOwnerUnlocked(owner));
  }

  Future<void> _cancelByOwnerUnlocked(NotificationOwner owner) async {
    final operation = LinuxSystemdNotificationSchedulerOperation.cancelByOwner;
    final initialRegistry = await _step<LinuxSystemdScheduleRegistry>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      owner: owner,
      action: _registryStore.load,
    );
    final scheduleIds =
        initialRegistry.entries
            .where((entry) => entry.owner == owner)
            .map((entry) => entry.scheduleId)
            .toList(growable: false)
          ..sort();

    if (scheduleIds.isEmpty) {
      return;
    }

    var workingRegistry = initialRegistry;
    final completedScheduleIds = <String>[];

    for (final scheduleId in scheduleIds) {
      try {
        await _cancelUnlocked(
          scheduleId,
          operation: operation,
          owner: owner,
          registrySnapshot: workingRegistry,
        );
      } catch (error, stackTrace) {
        final nested = error is LinuxSystemdNotificationSchedulerException
            ? error
            : null;

        throw LinuxSystemdNotificationSchedulerException(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.partialOwnerCancellation,
          scheduleId: scheduleId,
          owner: owner,
          names: LinuxSystemdUnitNames.forScheduleKey(scheduleId),
          cause: error,
          causeStackTrace: stackTrace,
          rollbackFailures:
              nested?.rollbackFailures ??
              const <LinuxSystemdSchedulerRollbackFailure>[],
          confirmedStatus: nested?.confirmedStatus,
          completedScheduleIds: completedScheduleIds,
        );
      }

      final existing = workingRegistry.entryForScheduleId(scheduleId);
      if (existing != null) {
        workingRegistry = LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: workingRegistry.generation + 1,
          entries: workingRegistry.entries.where(
            (entry) => entry.scheduleId != scheduleId,
          ),
        );
      }

      completedScheduleIds.add(scheduleId);
    }
  }

  @override
  Future<void> reconcile(List<NotificationRequest> expected) {
    return _globalLock.runWrite(() => _reconcileInventoryUnlocked(expected));
  }

  Future<void> _reconcileInventoryUnlocked(
    List<NotificationRequest> expected,
  ) async {
    final operation = LinuxSystemdNotificationSchedulerOperation.reconcile;
    final nowUtc = _clock.nowUtc().toUtc();
    final desiredById = <String, NotificationRequest>{};

    for (final request in expected) {
      desiredById[request.scheduleId] = request;
    }

    final desired =
        desiredById.values
            .where((request) => request.scheduledAtUtc.isAfter(nowUtc))
            .toList(growable: false)
          ..sort((left, right) => left.scheduleId.compareTo(right.scheduleId));
    final desiredIds = desired.map((request) => request.scheduleId).toSet();
    final desiredBaseNames = desired
        .map(
          (request) =>
              LinuxSystemdUnitNames.forScheduleKey(request.scheduleId).baseName,
        )
        .toSet();

    var recoveredFromCorruption = false;
    late LinuxSystemdScheduleRegistry registry;

    try {
      registry = await _registryStore.load();
    } on LinuxSystemdScheduleRegistryException {
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        action: _registryStore.quarantineCorruptRegistry,
      );
      registry = LinuxSystemdScheduleRegistry.empty();
      recoveredFromCorruption = true;
    } catch (error, stackTrace) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    final discovery = await _step<LinuxSystemdUnitDiscovery>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      action: _registryStore.discoverAppUnitPairs,
    );
    final candidatesByBaseName = <String, _ReconciliationCleanupCandidate>{};

    void addCandidate(
      LinuxSystemdUnitNames names, {
      String? scheduleId,
      LinuxSystemdScheduleRegistryEntry? previousEntry,
    }) {
      final current = candidatesByBaseName[names.baseName];
      if (current == null ||
          (current.previousEntry == null && previousEntry != null)) {
        candidatesByBaseName[names.baseName] = _ReconciliationCleanupCandidate(
          names: names,
          scheduleId: scheduleId ?? current?.scheduleId,
          previousEntry: previousEntry ?? current?.previousEntry,
        );
      }
    }

    final retainedEntries = <LinuxSystemdScheduleRegistryEntry>[];
    final registryBaseNames = <String>{};

    if (!recoveredFromCorruption) {
      for (final entry in registry.entries) {
        final canonical = LinuxSystemdUnitNames.forScheduleKey(
          entry.scheduleId,
        );
        registryBaseNames.add(canonical.baseName);
        final namesMatch =
            entry.timerName.value == canonical.timerFileName &&
            entry.serviceFileName == canonical.serviceFileName;
        final shouldRetain =
            desiredIds.contains(entry.scheduleId) && namesMatch;

        if (shouldRetain) {
          retainedEntries.add(entry);
        } else {
          addCandidate(
            canonical,
            scheduleId: entry.scheduleId,
            previousEntry: entry,
          );
        }
      }
    }

    for (final names in discovery.completePairs) {
      if (recoveredFromCorruption ||
          (!registryBaseNames.contains(names.baseName) &&
              !desiredBaseNames.contains(names.baseName))) {
        addCandidate(names);
      }
    }

    for (final partial in discovery.partialPairs) {
      addCandidate(LinuxSystemdUnitNames.parseBaseName(partial.baseName));
    }

    final candidates = candidatesByBaseName.values.toList()
      ..sort((left, right) => left.sortKey.compareTo(right.sortKey));
    final registryChanged =
        recoveredFromCorruption ||
        !_sameRegistryEntries(registry.entries, retainedEntries);
    final nextRegistry = LinuxSystemdScheduleRegistry(
      schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
      generation: registry.generation + 1,
      entries: retainedEntries,
    );
    final removals = <_ReconciliationAppliedRemoval>[];
    var registryReplaceAttempted = false;

    try {
      for (final candidate in candidates) {
        final transaction = await _step<LinuxSystemdUnitRemoveTransaction>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: candidate.scheduleId,
          owner: candidate.previousEntry?.owner,
          names: candidate.names,
          action: () => _unitStore.beginRemove(candidate.names),
        );

        if (transaction.names != candidate.names) {
          throw LinuxSystemdNotificationSchedulerException(
            operation: operation,
            failure:
                LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
            scheduleId: candidate.scheduleId,
            owner: candidate.previousEntry?.owner,
            names: candidate.names,
            cause: StateError(
              'Remove transaction identity does not match '
              'reconciliation cleanup identity.',
            ),
            causeStackTrace: StackTrace.current,
          );
        }

        final applied = _ReconciliationAppliedRemoval(
          candidate: candidate,
          transaction: transaction,
        );
        removals.add(applied);

        await _step<LinuxSystemdTimerStatus>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
          scheduleId: candidate.scheduleId,
          owner: candidate.previousEntry?.owner,
          names: candidate.names,
          action: () => _driver.disableAndStop(
            LinuxSystemdTimerName.parse(candidate.names.timerFileName),
          ),
        );
        await _step<void>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: candidate.scheduleId,
          owner: candidate.previousEntry?.owner,
          names: candidate.names,
          action: transaction.apply,
        );
      }

      if (removals.isNotEmpty) {
        await _step<void>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
          action: _driver.reloadDaemon,
        );
      }

      if (registryChanged) {
        registryReplaceAttempted = true;
        await _step<void>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
          action: () => _registryStore.replace(nextRegistry),
        );
      }

      for (final removal in removals) {
        await _step<void>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: removal.candidate.scheduleId,
          owner: removal.candidate.previousEntry?.owner,
          names: removal.candidate.names,
          action: removal.transaction.finalize,
        );
      }
    } catch (error, stackTrace) {
      final rollbackFailures = await _rollbackReconciliationCleanup(
        removals: removals,
        previousRegistry: registry,
        registryReplaceAttempted: registryReplaceAttempted,
      );

      if (rollbackFailures.isEmpty) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.rollbackFailed,
        cause: error,
        causeStackTrace: stackTrace,
        rollbackFailures: rollbackFailures,
      );
    }

    final confirmedRegistry = registryChanged ? nextRegistry : registry;
    await _repairReconciliationDesired(
      desired: desired,
      discovery: discovery,
      registry: confirmedRegistry,
    );
  }

  Future<void> _repairReconciliationDesired({
    required List<NotificationRequest> desired,
    required LinuxSystemdUnitDiscovery discovery,
    required LinuxSystemdScheduleRegistry registry,
  }) async {
    final operation = LinuxSystemdNotificationSchedulerOperation.reconcile;
    final completeBaseNames = discovery.completePairs
        .map((names) => names.baseName)
        .toSet();
    final staged = <_ReconciliationInstall>[];
    final completedScheduleIds = <String>[];

    for (final request in desired) {
      final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
      final timerName = LinuxSystemdTimerName.parse(names.timerFileName);

      try {
        final requestFingerprint = await _step<String>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          action: () => _fingerprint.compute(request),
        );
        final previous = registry.entryForScheduleId(request.scheduleId);
        final hasCompletePair = completeBaseNames.contains(names.baseName);

        if (previous != null &&
            hasCompletePair &&
            previous.requestFingerprint == requestFingerprint) {
          final status = await _step<LinuxSystemdTimerStatus>(
            operation: operation,
            failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
            scheduleId: request.scheduleId,
            owner: request.owner,
            names: names,
            action: () => _driver.status(timerName),
          );
          if (status.isHealthy) {
            completedScheduleIds.add(request.scheduleId);
            continue;
          }
        }

        final unit = await _step<LinuxSystemdNotificationUnit>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.commandFactoryFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          action: () => _commandFactory.create(request),
        );
        final rendered = await _step<LinuxSystemdRenderedUnits>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          action: () => _renderer.render(unit),
        );

        if (rendered.serviceFileName != names.serviceFileName ||
            rendered.timerFileName != names.timerFileName) {
          throw LinuxSystemdNotificationSchedulerException(
            operation: operation,
            failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
            scheduleId: request.scheduleId,
            owner: request.owner,
            names: names,
            cause: StateError(
              'Rendered reconciliation unit identity does not match '
              'the desired schedule.',
            ),
            causeStackTrace: StackTrace.current,
          );
        }

        final transaction = await _step<LinuxSystemdUnitInstallTransaction>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          action: () => _unitStore.beginInstall(rendered),
        );

        if (transaction.names != names) {
          throw LinuxSystemdNotificationSchedulerException(
            operation: operation,
            failure:
                LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
            scheduleId: request.scheduleId,
            owner: request.owner,
            names: names,
            cause: StateError(
              'Install transaction identity does not match '
              'the desired schedule.',
            ),
            causeStackTrace: StackTrace.current,
          );
        }

        final repair = _ReconciliationInstall(
          request: request,
          names: names,
          timerName: timerName,
          requestFingerprint: requestFingerprint,
          transaction: transaction,
        );
        staged.add(repair);

        await _step<void>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          action: transaction.apply,
        );
      } catch (error, stackTrace) {
        final rollbackFailures =
            await _rollbackUnconfirmedReconciliationInstalls(
              installs: staged,
              reload: staged.isNotEmpty,
            );
        _throwPartialReconciliation(
          request: request,
          error: error,
          stackTrace: stackTrace,
          completedScheduleIds: completedScheduleIds,
          rollbackFailures: rollbackFailures,
        );
      }
    }

    if (staged.isEmpty) {
      return;
    }

    try {
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
        action: _driver.reloadDaemon,
      );
    } catch (error, stackTrace) {
      final rollbackFailures = await _rollbackUnconfirmedReconciliationInstalls(
        installs: staged,
        reload: true,
      );
      _throwPartialReconciliation(
        request: staged.first.request,
        error: error,
        stackTrace: stackTrace,
        completedScheduleIds: completedScheduleIds,
        rollbackFailures: rollbackFailures,
      );
    }

    final finalized = <_ReconciliationInstall>[];
    final nextEntries = <LinuxSystemdScheduleRegistryEntry>[
      ...registry.entries,
    ];

    for (final repair in staged) {
      try {
        final status = await _step<LinuxSystemdTimerStatus>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
          scheduleId: repair.request.scheduleId,
          owner: repair.request.owner,
          names: repair.names,
          action: () => _driver.enableAndStart(repair.timerName),
        );
        if (!status.isHealthy) {
          throw LinuxSystemdNotificationSchedulerException(
            operation: operation,
            failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
            scheduleId: repair.request.scheduleId,
            owner: repair.request.owner,
            names: repair.names,
            cause: StateError(
              'Reconciled timer did not reach the healthy waiting state.',
            ),
            causeStackTrace: StackTrace.current,
            confirmedStatus: status,
          );
        }

        repair.enabled = true;
        await _step<void>(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: repair.request.scheduleId,
          owner: repair.request.owner,
          names: repair.names,
          action: repair.transaction.finalize,
        );
        repair.finalized = true;
        finalized.add(repair);
        completedScheduleIds.add(repair.request.scheduleId);

        nextEntries.removeWhere(
          (entry) => entry.scheduleId == repair.request.scheduleId,
        );
        nextEntries.add(repair.registryEntry);
      } catch (error, stackTrace) {
        final index = staged.indexOf(repair);
        final rollbackFailures =
            await _rollbackUnconfirmedReconciliationInstalls(
              installs: staged.sublist(index),
              reload: true,
            );
        final registryFailures = await _writeConfirmedReconciliationRegistry(
          previousRegistry: registry,
          entries: nextEntries,
          rollbackFailures: rollbackFailures,
        );
        _throwPartialReconciliation(
          request: repair.request,
          error: error,
          stackTrace: stackTrace,
          completedScheduleIds: completedScheduleIds,
          rollbackFailures: registryFailures,
        );
      }
    }

    final repairRegistry = LinuxSystemdScheduleRegistry(
      schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
      generation: registry.generation + 1,
      entries: nextEntries,
    );

    try {
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        action: () => _registryStore.replace(repairRegistry),
      );
    } catch (error, stackTrace) {
      final rollbackFailures = <LinuxSystemdSchedulerRollbackFailure>[];
      final registryFailures = await _writeConfirmedReconciliationRegistry(
        previousRegistry: registry,
        entries: nextEntries,
        rollbackFailures: rollbackFailures,
      );
      _throwPartialReconciliation(
        request: finalized.isEmpty
            ? staged.first.request
            : finalized.last.request,
        error: error,
        stackTrace: stackTrace,
        completedScheduleIds: completedScheduleIds,
        rollbackFailures: registryFailures,
      );
    }
  }

  Future<List<LinuxSystemdSchedulerRollbackFailure>>
  _rollbackUnconfirmedReconciliationInstalls({
    required List<_ReconciliationInstall> installs,
    required bool reload,
  }) async {
    final failures = <LinuxSystemdSchedulerRollbackFailure>[];

    for (final repair in installs.reversed) {
      if (repair.enabled) {
        await _captureRollbackFailure(
          step: 'disable-reconcile-install/${repair.names.baseName}',
          action: () => _driver.disableAndStop(repair.timerName),
          failures: failures,
        );
      }
      if (!repair.finalized) {
        await _captureRollbackFailure(
          step: 'rollback-reconcile-install/${repair.names.baseName}',
          action: repair.transaction.rollback,
          failures: failures,
          expandUnitStoreFailures: true,
        );
      }
    }

    if (reload && installs.isNotEmpty) {
      await _captureRollbackFailure(
        step: 'reload-after-reconcile-install-rollback',
        action: _driver.reloadDaemon,
        failures: failures,
      );
    }

    return failures;
  }

  Future<List<LinuxSystemdSchedulerRollbackFailure>>
  _writeConfirmedReconciliationRegistry({
    required LinuxSystemdScheduleRegistry previousRegistry,
    required Iterable<LinuxSystemdScheduleRegistryEntry> entries,
    required List<LinuxSystemdSchedulerRollbackFailure> rollbackFailures,
  }) async {
    try {
      final current = await _registryStore.load();
      final baseGeneration = current.generation > previousRegistry.generation
          ? current.generation
          : previousRegistry.generation;
      await _registryStore.replace(
        LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: baseGeneration + 1,
          entries: entries,
        ),
      );
    } catch (error, stackTrace) {
      rollbackFailures.add(
        LinuxSystemdSchedulerRollbackFailure(
          step: 'write-confirmed-reconciliation-registry',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
    return rollbackFailures;
  }

  Never _throwPartialReconciliation({
    required NotificationRequest request,
    required Object error,
    required StackTrace stackTrace,
    required List<String> completedScheduleIds,
    required List<LinuxSystemdSchedulerRollbackFailure> rollbackFailures,
  }) {
    final nested = error is LinuxSystemdNotificationSchedulerException
        ? error
        : null;
    throw LinuxSystemdNotificationSchedulerException(
      operation: LinuxSystemdNotificationSchedulerOperation.reconcile,
      failure: LinuxSystemdNotificationSchedulerFailure.partialReconciliation,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: LinuxSystemdUnitNames.forScheduleKey(request.scheduleId),
      cause: error,
      causeStackTrace: stackTrace,
      rollbackFailures: <LinuxSystemdSchedulerRollbackFailure>[
        ...(nested?.rollbackFailures ??
            const <LinuxSystemdSchedulerRollbackFailure>[]),
        ...rollbackFailures,
      ],
      confirmedStatus: nested?.confirmedStatus,
      completedScheduleIds: completedScheduleIds,
    );
  }

  Future<List<LinuxSystemdSchedulerRollbackFailure>>
  _rollbackReconciliationCleanup({
    required List<_ReconciliationAppliedRemoval> removals,
    required LinuxSystemdScheduleRegistry previousRegistry,
    required bool registryReplaceAttempted,
  }) async {
    final failures = <LinuxSystemdSchedulerRollbackFailure>[];

    for (final removal in removals.reversed) {
      await _captureRollbackFailure(
        step: 'rollback-reconcile-remove/${removal.candidate.names.baseName}',
        action: removal.transaction.rollback,
        failures: failures,
        expandUnitStoreFailures: true,
      );
    }

    if (removals.isNotEmpty) {
      await _captureRollbackFailure(
        step: 'reload-after-reconcile-cleanup-restore',
        action: _driver.reloadDaemon,
        failures: failures,
      );
    }

    if (registryReplaceAttempted) {
      LinuxSystemdScheduleRegistry? currentRegistry;
      try {
        currentRegistry = await _registryStore.load();
      } catch (error, stackTrace) {
        failures.add(
          LinuxSystemdSchedulerRollbackFailure(
            step: 'load-registry-for-reconcile-restore',
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }

      if (currentRegistry != null) {
        final currentGeneration = currentRegistry.generation;
        final previousGeneration = previousRegistry.generation;
        final baseGeneration = currentGeneration > previousGeneration
            ? currentGeneration
            : previousGeneration;
        final restored = LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: baseGeneration + 1,
          entries: previousRegistry.entries,
        );
        await _captureRollbackFailure(
          step: 'restore-registry-after-reconcile-cleanup',
          action: () => _registryStore.replace(restored),
          failures: failures,
        );
      }
    }

    for (final removal in removals) {
      if (removal.candidate.previousEntry == null) {
        continue;
      }
      await _captureRollbackFailure(
        step: 're-enable-reconcile-timer/${removal.candidate.names.baseName}',
        action: () => _driver.enableAndStart(
          LinuxSystemdTimerName.parse(removal.candidate.names.timerFileName),
        ),
        failures: failures,
      );
    }

    return List<LinuxSystemdSchedulerRollbackFailure>.unmodifiable(failures);
  }

  bool _sameRegistryEntries(
    List<LinuxSystemdScheduleRegistryEntry> left,
    List<LinuxSystemdScheduleRegistryEntry> right,
  ) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  Future<void> _scheduleUnlocked(NotificationRequest request) async {
    final operation = LinuxSystemdNotificationSchedulerOperation.schedule;
    final nowUtc = _clock.nowUtc().toUtc();

    if (!request.scheduledAtUtc.isAfter(nowUtc)) {
      await _cancelUnlocked(
        request.scheduleId,
        operation: operation,
        owner: request.owner,
      );

      final content = NotificationDeliveryPolicy.contentFor(request);
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: LinuxSystemdUnitNames.forScheduleKey(request.scheduleId),
        action: () => _gateway.showNow(
          id: StableNotificationId.fromScheduleId(request.scheduleId),
          title: content.title,
          body: content.body,
          payload: NotificationPayloadCodec.encode(request),
        ),
      );
      return;
    }

    final requestFingerprint = await _step<String>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      action: () => _fingerprint.compute(request),
    );
    final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
    final timerName = LinuxSystemdTimerName.parse(names.timerFileName);
    final registry = await _step<LinuxSystemdScheduleRegistry>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: _registryStore.load,
    );
    final previous = registry.entryForScheduleId(request.scheduleId);

    if (previous != null && previous.requestFingerprint == requestFingerprint) {
      final status = await _step<LinuxSystemdTimerStatus>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: () => _driver.status(timerName),
      );

      if (status.isHealthy) {
        return;
      }
    }

    final unit = await _step(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.commandFactoryFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _commandFactory.create(request),
    );
    final rendered = await _step(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _renderer.render(unit),
    );

    if (rendered.serviceFileName != names.serviceFileName ||
        rendered.timerFileName != names.timerFileName) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        cause: StateError(
          'Rendered unit names do not match the schedule identity.',
        ),
        causeStackTrace: StackTrace.current,
      );
    }

    LinuxSystemdUnitInstallTransaction? transaction;
    var applyAttempted = false;
    var systemdMayHaveObserved = false;
    var registryReplaceAttempted = false;

    try {
      transaction = await _step<LinuxSystemdUnitInstallTransaction>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: () => _unitStore.beginInstall(rendered),
      );

      if (transaction.names != names) {
        throw LinuxSystemdNotificationSchedulerException(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          cause: StateError(
            'Unit transaction identity does not match the schedule.',
          ),
          causeStackTrace: StackTrace.current,
        );
      }

      applyAttempted = true;
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: transaction.apply,
      );

      systemdMayHaveObserved = true;
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: _driver.reloadDaemon,
      );

      final confirmedStatus = await _step<LinuxSystemdTimerStatus>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: () => _driver.enableAndStart(timerName),
      );

      if (!confirmedStatus.isHealthy) {
        throw LinuxSystemdNotificationSchedulerException(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
          scheduleId: request.scheduleId,
          owner: request.owner,
          names: names,
          cause: StateError(
            'Enabled timer did not reach the healthy waiting state.',
          ),
          causeStackTrace: StackTrace.current,
          confirmedStatus: confirmedStatus,
        );
      }

      final nextEntry = LinuxSystemdScheduleRegistryEntry(
        scheduleId: request.scheduleId,
        owner: request.owner,
        timerName: timerName,
        serviceFileName: names.serviceFileName,
        scheduledAtUtc: request.scheduledAtUtc,
        requestFingerprint: requestFingerprint,
      );
      final nextRegistry = LinuxSystemdScheduleRegistry(
        schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
        generation: registry.generation + 1,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          for (final entry in registry.entries)
            if (entry.scheduleId != request.scheduleId) entry,
          nextEntry,
        ],
      );

      registryReplaceAttempted = true;
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: () => _registryStore.replace(nextRegistry),
      );
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: transaction.finalize,
      );
    } catch (error, stackTrace) {
      final appliedTransaction = transaction;
      if (appliedTransaction == null || !applyAttempted) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      final rollbackFailures = await _rollbackFailedSchedule(
        transaction: appliedTransaction,
        timerName: timerName,
        previousRegistry: registry,
        previousEntry: previous,
        systemdMayHaveObserved: systemdMayHaveObserved,
        registryReplaceAttempted: registryReplaceAttempted,
      );

      if (rollbackFailures.isEmpty) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.rollbackFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        cause: error,
        causeStackTrace: stackTrace,
        rollbackFailures: rollbackFailures,
      );
    }
  }

  Future<List<LinuxSystemdSchedulerRollbackFailure>> _rollbackFailedSchedule({
    required LinuxSystemdUnitInstallTransaction transaction,
    required LinuxSystemdTimerName timerName,
    required LinuxSystemdScheduleRegistry previousRegistry,
    required LinuxSystemdScheduleRegistryEntry? previousEntry,
    required bool systemdMayHaveObserved,
    required bool registryReplaceAttempted,
  }) async {
    final failures = <LinuxSystemdSchedulerRollbackFailure>[];

    if (systemdMayHaveObserved) {
      await _captureRollbackFailure(
        step: 'disable-new-timer',
        action: () => _driver.disableAndStop(timerName),
        failures: failures,
      );
    }

    await _captureRollbackFailure(
      step: 'rollback-install-transaction',
      action: transaction.rollback,
      failures: failures,
      expandUnitStoreFailures: true,
    );

    await _captureRollbackFailure(
      step: 'reload-after-unit-restore',
      action: _driver.reloadDaemon,
      failures: failures,
    );

    if (registryReplaceAttempted) {
      LinuxSystemdScheduleRegistry? currentRegistry;

      try {
        currentRegistry = await _registryStore.load();
      } catch (error, stackTrace) {
        failures.add(
          LinuxSystemdSchedulerRollbackFailure(
            step: 'load-registry-for-restore',
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }

      if (currentRegistry != null) {
        final currentGeneration = currentRegistry.generation;
        final previousGeneration = previousRegistry.generation;
        final baseGeneration = currentGeneration > previousGeneration
            ? currentGeneration
            : previousGeneration;
        final restoredRegistry = LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: baseGeneration + 1,
          entries: previousRegistry.entries,
        );

        await _captureRollbackFailure(
          step: 'restore-registry',
          action: () => _registryStore.replace(restoredRegistry),
          failures: failures,
        );
      }
    }

    if (previousEntry != null) {
      await _captureRollbackFailure(
        step: 're-enable-previous-timer',
        action: () => _driver.enableAndStart(timerName),
        failures: failures,
      );
    }

    return List<LinuxSystemdSchedulerRollbackFailure>.unmodifiable(failures);
  }

  Future<void> _captureRollbackFailure({
    required String step,
    required FutureOr<Object?> Function() action,
    required List<LinuxSystemdSchedulerRollbackFailure> failures,
    bool expandUnitStoreFailures = false,
  }) async {
    try {
      await Future<Object?>.sync(action);
    } catch (error, stackTrace) {
      if (expandUnitStoreFailures &&
          error is LinuxSystemdUserUnitStoreException &&
          error.rollbackFailures.isNotEmpty) {
        for (final failure in error.rollbackFailures) {
          failures.add(
            LinuxSystemdSchedulerRollbackFailure(
              step: '$step/${failure.step}',
              error: failure.error,
              stackTrace: failure.stackTrace,
            ),
          );
        }
        return;
      }

      failures.add(
        LinuxSystemdSchedulerRollbackFailure(
          step: step,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _cancelUnlocked(
    String scheduleId, {
    required LinuxSystemdNotificationSchedulerOperation operation,
    NotificationOwner? owner,
    LinuxSystemdScheduleRegistry? registrySnapshot,
  }) async {
    final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
    final registry =
        registrySnapshot ??
        await _step<LinuxSystemdScheduleRegistry>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
          scheduleId: scheduleId,
          owner: owner,
          names: names,
          action: _registryStore.load,
        );
    final existing = registry.entryForScheduleId(scheduleId);
    final effectiveOwner = owner ?? existing?.owner;
    final timerName = LinuxSystemdTimerName.parse(names.timerFileName);

    LinuxSystemdUnitRemoveTransaction? transaction;
    var registryReplaceAttempted = false;

    try {
      transaction = await _step<LinuxSystemdUnitRemoveTransaction>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        action: () => _unitStore.beginRemove(names),
      );

      if (transaction.names != names) {
        throw LinuxSystemdNotificationSchedulerException(
          operation: operation,
          failure:
              LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
          scheduleId: scheduleId,
          owner: effectiveOwner,
          names: names,
          cause: StateError(
            'Remove transaction identity does not match the schedule.',
          ),
          causeStackTrace: StackTrace.current,
        );
      }

      await _step<LinuxSystemdTimerStatus>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        action: () => _driver.disableAndStop(timerName),
      );
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        action: transaction.apply,
      );
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        action: _driver.reloadDaemon,
      );

      if (existing != null) {
        final nextRegistry = LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: registry.generation + 1,
          entries: registry.entries.where(
            (entry) => entry.scheduleId != scheduleId,
          ),
        );

        registryReplaceAttempted = true;
        await _step<void>(
          operation: operation,
          failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
          scheduleId: scheduleId,
          owner: effectiveOwner,
          names: names,
          action: () => _registryStore.replace(nextRegistry),
        );
      }

      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        action: transaction.finalize,
      );
    } catch (error, stackTrace) {
      final retainedTransaction = transaction;
      if (retainedTransaction == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      final rollbackFailures = await _rollbackFailedCancel(
        transaction: retainedTransaction,
        timerName: timerName,
        previousRegistry: registry,
        previousEntry: existing,
        registryReplaceAttempted: registryReplaceAttempted,
      );

      if (rollbackFailures.isEmpty) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.rollbackFailed,
        scheduleId: scheduleId,
        owner: effectiveOwner,
        names: names,
        cause: error,
        causeStackTrace: stackTrace,
        rollbackFailures: rollbackFailures,
      );
    }
  }

  Future<List<LinuxSystemdSchedulerRollbackFailure>> _rollbackFailedCancel({
    required LinuxSystemdUnitRemoveTransaction transaction,
    required LinuxSystemdTimerName timerName,
    required LinuxSystemdScheduleRegistry previousRegistry,
    required LinuxSystemdScheduleRegistryEntry? previousEntry,
    required bool registryReplaceAttempted,
  }) async {
    final failures = <LinuxSystemdSchedulerRollbackFailure>[];

    await _captureRollbackFailure(
      step: 'rollback-remove-transaction',
      action: transaction.rollback,
      failures: failures,
      expandUnitStoreFailures: true,
    );

    await _captureRollbackFailure(
      step: 'reload-after-remove-restore',
      action: _driver.reloadDaemon,
      failures: failures,
    );

    if (registryReplaceAttempted) {
      LinuxSystemdScheduleRegistry? currentRegistry;

      try {
        currentRegistry = await _registryStore.load();
      } catch (error, stackTrace) {
        failures.add(
          LinuxSystemdSchedulerRollbackFailure(
            step: 'load-registry-for-cancel-restore',
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }

      if (currentRegistry != null) {
        final currentGeneration = currentRegistry.generation;
        final previousGeneration = previousRegistry.generation;
        final baseGeneration = currentGeneration > previousGeneration
            ? currentGeneration
            : previousGeneration;
        final restoredRegistry = LinuxSystemdScheduleRegistry(
          schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
          generation: baseGeneration + 1,
          entries: previousRegistry.entries,
        );

        await _captureRollbackFailure(
          step: 'restore-registry-after-cancel',
          action: () => _registryStore.replace(restoredRegistry),
          failures: failures,
        );
      }
    }

    if (previousEntry != null) {
      await _captureRollbackFailure(
        step: 're-enable-canceled-timer',
        action: () => _driver.enableAndStart(timerName),
        failures: failures,
      );
    }

    return List<LinuxSystemdSchedulerRollbackFailure>.unmodifiable(failures);
  }

  Future<T> _step<T>({
    required LinuxSystemdNotificationSchedulerOperation operation,
    required LinuxSystemdNotificationSchedulerFailure failure,
    required FutureOr<T> Function() action,
    String? scheduleId,
    NotificationOwner? owner,
    LinuxSystemdUnitNames? names,
  }) async {
    try {
      return await Future<T>.sync(action);
    } on LinuxProcessCancellationException {
      rethrow;
    } on LinuxSystemdNotificationSchedulerException {
      rethrow;
    } catch (error, stackTrace) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: failure,
        scheduleId: scheduleId,
        owner: owner,
        names: names,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}

final class _ReconciliationInstall {
  _ReconciliationInstall({
    required this.request,
    required this.names,
    required this.timerName,
    required this.requestFingerprint,
    required this.transaction,
  });

  final NotificationRequest request;
  final LinuxSystemdUnitNames names;
  final LinuxSystemdTimerName timerName;
  final String requestFingerprint;
  final LinuxSystemdUnitInstallTransaction transaction;

  bool enabled = false;
  bool finalized = false;

  LinuxSystemdScheduleRegistryEntry get registryEntry {
    return LinuxSystemdScheduleRegistryEntry(
      scheduleId: request.scheduleId,
      owner: request.owner,
      timerName: timerName,
      serviceFileName: names.serviceFileName,
      scheduledAtUtc: request.scheduledAtUtc,
      requestFingerprint: requestFingerprint,
    );
  }
}

final class _ReconciliationCleanupCandidate {
  const _ReconciliationCleanupCandidate({
    required this.names,
    required this.scheduleId,
    required this.previousEntry,
  });

  final LinuxSystemdUnitNames names;
  final String? scheduleId;
  final LinuxSystemdScheduleRegistryEntry? previousEntry;

  String get sortKey => scheduleId ?? names.baseName;
}

final class _ReconciliationAppliedRemoval {
  const _ReconciliationAppliedRemoval({
    required this.candidate,
    required this.transaction,
  });

  final _ReconciliationCleanupCandidate candidate;
  final LinuxSystemdUnitRemoveTransaction transaction;
}
