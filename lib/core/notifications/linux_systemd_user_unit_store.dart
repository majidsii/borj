import 'dart:convert';

import 'linux_systemd_file_system.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_unit_transaction.dart';
import 'linux_systemd_user_unit_path_resolver.dart';
import 'linux_systemd_user_unit_store_exception.dart';

typedef LinuxSystemdTransactionIdFactory = String Function();

/// Persists matching systemd user service and timer files.
///
/// Gate 10.5.2 adds retained install transactions. The retained remove
/// transaction is added separately in Gate 10.5.3.
final class LinuxSystemdUserUnitStore implements LinuxSystemdUnitStore {
  factory LinuxSystemdUserUnitStore({
    required LinuxSystemdUserUnitPathResolver pathResolver,
    required LinuxSystemdFileSystem fileSystem,
    required LinuxSystemdTransactionIdFactory transactionIdFactory,
  }) {
    return LinuxSystemdUserUnitStore._(
      pathResolver,
      fileSystem,
      transactionIdFactory,
    );
  }

  LinuxSystemdUserUnitStore._(
    this._pathResolver,
    this._fileSystem,
    this._transactionIdFactory,
  );

  static final RegExp _serviceNamePattern = RegExp(
    r'^(borj-notification-[0-9a-f]{16})\.service$',
  );
  static final RegExp _timerNamePattern = RegExp(
    r'^(borj-notification-[0-9a-f]{16})\.timer$',
  );
  static final RegExp _transactionIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static const int _unitFileMode = 0x1A4;

  final LinuxSystemdUserUnitPathResolver _pathResolver;
  final LinuxSystemdFileSystem _fileSystem;
  final LinuxSystemdTransactionIdFactory _transactionIdFactory;

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    try {
      final names = _validatedNames(units.serviceFileName, units.timerFileName);
      final transactionId = _transactionIdFactory();
      _validateTransactionId(transactionId);

      final directory = _pathResolver.resolve();
      final paths = _InstallPaths(
        directory: directory,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        transactionId: transactionId,
      );

      final serviceType = await _validateFinalPath(paths.service.finalPath);
      final timerType = await _validateFinalPath(paths.timer.finalPath);

      await _requireMissing(paths.service.tempPath);
      await _requireMissing(paths.timer.tempPath);
      await _requireMissing(paths.service.backupPath);
      await _requireMissing(paths.timer.backupPath);

      final state = _InstallMutationState(
        service: _UnitMutationState(
          previous: await _snapshotExisting(
            paths.service.finalPath,
            serviceType,
          ),
        ),
        timer: _UnitMutationState(
          previous: await _snapshotExisting(paths.timer.finalPath, timerType),
        ),
      );

      return _RetainedInstallTransaction(
        fileSystem: _fileSystem,
        names: names,
        units: units,
        paths: paths,
        mutationState: state,
      );
    } catch (error, stackTrace) {
      throw _exception(
        operation: LinuxSystemdUserUnitStoreOperation.beginInstall,
        failure: error is ArgumentError
            ? LinuxSystemdUserUnitTransactionFailure.invalidState
            : LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    try {
      final validatedNames = _validatedNames(
        names.serviceFileName,
        names.timerFileName,
      );
      final directory = _pathResolver.resolve();
      final servicePath = '$directory/${validatedNames.serviceFileName}';
      final timerPath = '$directory/${validatedNames.timerFileName}';

      final timerType = await _validateRemovalPath(timerPath);
      final serviceType = await _validateRemovalPath(servicePath);

      final serviceSnapshot = await _snapshotExisting(servicePath, serviceType);
      final timerSnapshot = await _snapshotExisting(timerPath, timerType);

      return _RetainedRemoveTransaction(
        fileSystem: _fileSystem,
        names: validatedNames,
        servicePath: servicePath,
        timerPath: timerPath,
        serviceSnapshot: serviceSnapshot,
        timerSnapshot: timerSnapshot,
      );
    } catch (error, stackTrace) {
      throw _exception(
        operation: LinuxSystemdUserUnitStoreOperation.beginRemove,
        failure: error is ArgumentError
            ? LinuxSystemdUserUnitTransactionFailure.invalidState
            : LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) async {
    LinuxSystemdUnitInstallTransaction? transaction;

    try {
      transaction = await beginInstall(units);
      await transaction.apply();
      await transaction.finalize();
    } catch (error, stackTrace) {
      final rollbackFailures = <LinuxSystemdRollbackFailure>[];

      if (transaction != null &&
          transaction.state != LinuxSystemdUnitTransactionState.finalized &&
          transaction.state != LinuxSystemdUnitTransactionState.rolledBack) {
        try {
          await transaction.rollback();
        } on LinuxSystemdUserUnitStoreException catch (rollbackError) {
          if (rollbackError.rollbackFailures.isNotEmpty) {
            rollbackFailures.addAll(rollbackError.rollbackFailures);
          } else {
            rollbackFailures.add(
              LinuxSystemdRollbackFailure(
                step: 'install-wrapper-rollback',
                error: rollbackError.cause,
                stackTrace: rollbackError.causeStackTrace,
              ),
            );
          }
        } catch (rollbackError, rollbackStackTrace) {
          rollbackFailures.add(
            LinuxSystemdRollbackFailure(
              step: 'install-wrapper-rollback',
              error: rollbackError,
              stackTrace: rollbackStackTrace,
            ),
          );
        }
      }

      final primary = _primaryFailure(error, stackTrace);

      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        cause: primary.error,
        causeStackTrace: primary.stackTrace,
        rollbackFailures: <LinuxSystemdRollbackFailure>[
          ...primary.rollbackFailures,
          ...rollbackFailures,
        ],
      );
    }
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    LinuxSystemdUnitRemoveTransaction? transaction;

    try {
      transaction = await beginRemove(names);
      await transaction.apply();
      await transaction.finalize();
    } catch (error, stackTrace) {
      final rollbackFailures = <LinuxSystemdRollbackFailure>[];

      if (transaction != null &&
          transaction.state != LinuxSystemdUnitTransactionState.finalized &&
          transaction.state != LinuxSystemdUnitTransactionState.rolledBack) {
        try {
          await transaction.rollback();
        } on LinuxSystemdUserUnitStoreException catch (rollbackError) {
          if (rollbackError.rollbackFailures.isNotEmpty) {
            rollbackFailures.addAll(rollbackError.rollbackFailures);
          } else {
            rollbackFailures.add(
              LinuxSystemdRollbackFailure(
                step: 'remove-wrapper-rollback',
                error: rollbackError.cause,
                stackTrace: rollbackError.causeStackTrace,
              ),
            );
          }
        } catch (rollbackError, rollbackStackTrace) {
          rollbackFailures.add(
            LinuxSystemdRollbackFailure(
              step: 'remove-wrapper-rollback',
              error: rollbackError,
              stackTrace: rollbackStackTrace,
            ),
          );
        }
      }

      final primary = _primaryFailure(error, stackTrace);

      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.remove,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: primary.error,
        causeStackTrace: primary.stackTrace,
        rollbackFailures: <LinuxSystemdRollbackFailure>[
          ...primary.rollbackFailures,
          ...rollbackFailures,
        ],
      );
    }
  }

  Future<_ExistingUnitSnapshot?> _snapshotExisting(
    String path,
    LinuxSystemdEntryType type,
  ) async {
    if (type == LinuxSystemdEntryType.missing) {
      return null;
    }

    return _ExistingUnitSnapshot(
      bytes: await _fileSystem.readBytes(path),
      mode: await _fileSystem.readMode(path),
    );
  }

  LinuxSystemdUnitNames _validatedNames(
    String serviceFileName,
    String timerFileName,
  ) {
    final serviceMatch = _serviceNamePattern.firstMatch(serviceFileName);
    final timerMatch = _timerNamePattern.firstMatch(timerFileName);

    if (serviceMatch == null || timerMatch == null) {
      throw ArgumentError(
        'Systemd unit file names must use renderer-generated names.',
      );
    }

    final serviceBaseName = serviceMatch.group(1)!;
    if (serviceBaseName != timerMatch.group(1)) {
      throw ArgumentError(
        'The service and timer must share the same unit base name.',
      );
    }

    return LinuxSystemdUnitNames.parseBaseName(serviceBaseName);
  }

  Future<LinuxSystemdEntryType> _validateRemovalPath(String path) async {
    final type = await _fileSystem.typeOf(path);

    if (type == LinuxSystemdEntryType.missing ||
        type == LinuxSystemdEntryType.regularFile) {
      return type;
    }

    throw LinuxSystemdUnsafeEntryException(
      path: path,
      entryType: type,
      operation: 'remove',
    );
  }

  void _validateTransactionId(String transactionId) {
    if (!_transactionIdPattern.hasMatch(transactionId)) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'must contain only letters, digits, underscore, or hyphen',
      );
    }
  }

  Future<LinuxSystemdEntryType> _validateFinalPath(String path) async {
    final type = await _fileSystem.typeOf(path);

    if (type == LinuxSystemdEntryType.missing ||
        type == LinuxSystemdEntryType.regularFile) {
      return type;
    }

    throw LinuxSystemdUnsafeEntryException(
      path: path,
      entryType: type,
      operation: 'replace',
    );
  }

  Future<void> _requireMissing(String path) async {
    final type = await _fileSystem.typeOf(path);
    if (type == LinuxSystemdEntryType.missing) {
      return;
    }

    throw LinuxSystemdUnsafeEntryException(
      path: path,
      entryType: type,
      operation: 'reuse transaction artifact',
    );
  }
}

final class _RetainedRemoveTransaction
    implements LinuxSystemdUnitRemoveTransaction {
  _RetainedRemoveTransaction({
    required this._fileSystem,
    required this.names,
    required this.servicePath,
    required this.timerPath,
    required this._serviceSnapshot,
    required this._timerSnapshot,
  });

  final LinuxSystemdFileSystem _fileSystem;
  final String servicePath;
  final String timerPath;

  _ExistingUnitSnapshot? _serviceSnapshot;
  _ExistingUnitSnapshot? _timerSnapshot;

  bool _applyAttempted = false;
  bool _serviceRemoved = false;
  bool _timerRemoved = false;

  @override
  final LinuxSystemdUnitNames names;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    if (state == LinuxSystemdUnitTransactionState.applied) {
      return;
    }

    if (state != LinuxSystemdUnitTransactionState.pending || _applyAttempted) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.applyRemove);
    }

    _applyAttempted = true;

    try {
      if (_timerSnapshot != null) {
        await _fileSystem.deleteFile(timerPath);
        _timerRemoved = true;
      }

      if (_serviceSnapshot != null) {
        await _fileSystem.deleteFile(servicePath);
        _serviceRemoved = true;
      }

      state = LinuxSystemdUnitTransactionState.applied;
    } catch (error, stackTrace) {
      throw _exception(
        operation: LinuxSystemdUserUnitStoreOperation.applyRemove,
        failure: LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> finalize() async {
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      return;
    }

    if (state != LinuxSystemdUnitTransactionState.applied) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.finalizeRemove);
    }

    _serviceSnapshot = null;
    _timerSnapshot = null;
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    if (state == LinuxSystemdUnitTransactionState.rolledBack) {
      return;
    }

    if (state == LinuxSystemdUnitTransactionState.finalized) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.rollbackRemove);
    }

    if (state == LinuxSystemdUnitTransactionState.pending && !_applyAttempted) {
      _serviceSnapshot = null;
      _timerSnapshot = null;
      state = LinuxSystemdUnitTransactionState.rolledBack;
      return;
    }

    final failures = <LinuxSystemdRollbackFailure>[];

    await _restoreRemovedUnit(
      label: 'service',
      path: servicePath,
      snapshot: _serviceSnapshot,
      removed: _serviceRemoved,
      failures: failures,
    );
    await _restoreRemovedUnit(
      label: 'timer',
      path: timerPath,
      snapshot: _timerSnapshot,
      removed: _timerRemoved,
      failures: failures,
    );

    if (failures.isNotEmpty) {
      final first = failures.first;
      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.rollbackRemove,
        transactionFailure:
            LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: first.error,
        causeStackTrace: first.stackTrace,
        rollbackFailures: failures,
      );
    }

    _serviceSnapshot = null;
    _timerSnapshot = null;
    _serviceRemoved = false;
    _timerRemoved = false;
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }

  Future<void> _restoreRemovedUnit({
    required String label,
    required String path,
    required _ExistingUnitSnapshot? snapshot,
    required bool removed,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    if (!removed || snapshot == null) {
      return;
    }

    final bytesRestored = await _attempt(
      step: 'restore-$label-snapshot-write',
      action: () => _fileSystem.writeBytes(path, snapshot.bytes),
      failures: failures,
    );

    if (!bytesRestored) {
      return;
    }

    await _attempt(
      step: 'restore-$label-snapshot-mode',
      action: () => _fileSystem.chmod(path, snapshot.mode),
      failures: failures,
    );
  }

  Future<bool> _attempt({
    required String step,
    required Future<void> Function() action,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      failures.add(
        LinuxSystemdRollbackFailure(
          step: step,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }
  }

  LinuxSystemdUserUnitStoreException _invalidState(
    LinuxSystemdUserUnitStoreOperation operation,
  ) {
    return LinuxSystemdUserUnitStoreException(
      operation: operation,
      transactionFailure: LinuxSystemdUserUnitTransactionFailure.invalidState,
      serviceFileName: names.serviceFileName,
      timerFileName: names.timerFileName,
      cause: StateError('Invalid retained remove transaction state.'),
      causeStackTrace: StackTrace.current,
    );
  }
}

final class _RetainedInstallTransaction
    implements LinuxSystemdUnitInstallTransaction {
  _RetainedInstallTransaction({
    required this._fileSystem,
    required this.names,
    required this.units,
    required this._paths,
    required this._mutationState,
  });

  final LinuxSystemdFileSystem _fileSystem;
  final LinuxSystemdRenderedUnits units;
  final _InstallPaths _paths;
  final _InstallMutationState _mutationState;

  bool _applyAttempted = false;
  bool _finalizeAttempted = false;

  @override
  final LinuxSystemdUnitNames names;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    if (state == LinuxSystemdUnitTransactionState.applied) {
      return;
    }

    if (state != LinuxSystemdUnitTransactionState.pending || _applyAttempted) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.applyInstall);
    }

    _applyAttempted = true;

    try {
      await _fileSystem.createDirectory(_paths.directory);

      await _fileSystem.writeBytes(
        _paths.service.tempPath,
        utf8.encode(units.serviceContents),
      );
      _mutationState.service.tempExists = true;

      await _fileSystem.writeBytes(
        _paths.timer.tempPath,
        utf8.encode(units.timerContents),
      );
      _mutationState.timer.tempExists = true;

      await _fileSystem.chmod(
        _paths.service.tempPath,
        LinuxSystemdUserUnitStore._unitFileMode,
      );
      await _fileSystem.chmod(
        _paths.timer.tempPath,
        LinuxSystemdUserUnitStore._unitFileMode,
      );

      if (_mutationState.service.previous != null) {
        await _fileSystem.rename(
          _paths.service.finalPath,
          _paths.service.backupPath,
        );
        _mutationState.service.backupExists = true;
      }

      if (_mutationState.timer.previous != null) {
        await _fileSystem.rename(
          _paths.timer.finalPath,
          _paths.timer.backupPath,
        );
        _mutationState.timer.backupExists = true;
      }

      await _fileSystem.rename(
        _paths.service.tempPath,
        _paths.service.finalPath,
      );
      _mutationState.service
        ..tempExists = false
        ..installed = true;

      await _fileSystem.rename(_paths.timer.tempPath, _paths.timer.finalPath);
      _mutationState.timer
        ..tempExists = false
        ..installed = true;

      await _fileSystem.chmod(
        _paths.service.finalPath,
        LinuxSystemdUserUnitStore._unitFileMode,
      );
      await _fileSystem.chmod(
        _paths.timer.finalPath,
        LinuxSystemdUserUnitStore._unitFileMode,
      );

      state = LinuxSystemdUnitTransactionState.applied;
    } catch (error, stackTrace) {
      throw _exception(
        operation: LinuxSystemdUserUnitStoreOperation.applyInstall,
        failure: LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> finalize() async {
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      return;
    }

    if (state != LinuxSystemdUnitTransactionState.applied ||
        _finalizeAttempted) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.finalizeInstall);
    }

    _finalizeAttempted = true;

    try {
      if (_mutationState.service.backupExists) {
        await _fileSystem.deleteFile(_paths.service.backupPath);
        _mutationState.service.backupExists = false;
      }

      if (_mutationState.timer.backupExists) {
        await _fileSystem.deleteFile(_paths.timer.backupPath);
        _mutationState.timer.backupExists = false;
      }

      state = LinuxSystemdUnitTransactionState.finalized;
    } catch (error, stackTrace) {
      throw _exception(
        operation: LinuxSystemdUserUnitStoreOperation.finalizeInstall,
        failure: LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> rollback() async {
    if (state == LinuxSystemdUnitTransactionState.rolledBack) {
      return;
    }

    if (state == LinuxSystemdUnitTransactionState.finalized) {
      throw _invalidState(LinuxSystemdUserUnitStoreOperation.rollbackInstall);
    }

    if (state == LinuxSystemdUnitTransactionState.pending && !_applyAttempted) {
      state = LinuxSystemdUnitTransactionState.rolledBack;
      return;
    }

    final failures = <LinuxSystemdRollbackFailure>[];

    await _deleteInstalledUnit(
      label: 'timer',
      paths: _paths.timer,
      unitState: _mutationState.timer,
      failures: failures,
    );
    await _deleteInstalledUnit(
      label: 'service',
      paths: _paths.service,
      unitState: _mutationState.service,
      failures: failures,
    );

    await _restorePreviousUnit(
      label: 'service',
      paths: _paths.service,
      unitState: _mutationState.service,
      failures: failures,
    );
    await _restorePreviousUnit(
      label: 'timer',
      paths: _paths.timer,
      unitState: _mutationState.timer,
      failures: failures,
    );

    await _deleteTempUnit(
      label: 'service',
      paths: _paths.service,
      unitState: _mutationState.service,
      failures: failures,
    );
    await _deleteTempUnit(
      label: 'timer',
      paths: _paths.timer,
      unitState: _mutationState.timer,
      failures: failures,
    );

    if (failures.isNotEmpty) {
      final first = failures.first;
      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.rollbackInstall,
        transactionFailure:
            LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: first.error,
        causeStackTrace: first.stackTrace,
        rollbackFailures: failures,
      );
    }

    state = LinuxSystemdUnitTransactionState.rolledBack;
  }

  Future<void> _deleteInstalledUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitMutationState unitState,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    if (!unitState.installed) {
      return;
    }

    final succeeded = await _attempt(
      step: 'delete-new-$label',
      action: () => _fileSystem.deleteFile(paths.finalPath),
      failures: failures,
    );

    if (succeeded) {
      unitState.installed = false;
    }
  }

  Future<void> _restorePreviousUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitMutationState unitState,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    final previous = unitState.previous;
    if (previous == null) {
      return;
    }

    var restored = false;

    if (unitState.backupExists) {
      restored = await _attempt(
        step: 'restore-$label-backup',
        action: () => _fileSystem.rename(paths.backupPath, paths.finalPath),
        failures: failures,
      );

      if (restored) {
        unitState
          ..backupExists = false
          ..installed = false;
      }
    }

    if (!restored) {
      final bytesRestored = await _attempt(
        step: 'restore-$label-snapshot-write',
        action: () => _fileSystem.writeBytes(paths.finalPath, previous.bytes),
        failures: failures,
      );

      if (bytesRestored) {
        final modeRestored = await _attempt(
          step: 'restore-$label-snapshot-mode',
          action: () => _fileSystem.chmod(paths.finalPath, previous.mode),
          failures: failures,
        );

        if (modeRestored) {
          restored = true;
          unitState.installed = false;
        }
      }
    }

    if (restored && unitState.backupExists) {
      final deleted = await _attempt(
        step: 'delete-$label-backup-after-restore',
        action: () => _fileSystem.deleteFile(paths.backupPath),
        failures: failures,
      );

      if (deleted) {
        unitState.backupExists = false;
      }
    }
  }

  Future<void> _deleteTempUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitMutationState unitState,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    if (!unitState.tempExists) {
      return;
    }

    final deleted = await _attempt(
      step: 'delete-$label-temp',
      action: () => _fileSystem.deleteFile(paths.tempPath),
      failures: failures,
    );

    if (deleted) {
      unitState.tempExists = false;
    }
  }

  Future<bool> _attempt({
    required String step,
    required Future<void> Function() action,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      failures.add(
        LinuxSystemdRollbackFailure(
          step: step,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }
  }

  LinuxSystemdUserUnitStoreException _invalidState(
    LinuxSystemdUserUnitStoreOperation operation,
  ) {
    return LinuxSystemdUserUnitStoreException(
      operation: operation,
      transactionFailure: LinuxSystemdUserUnitTransactionFailure.invalidState,
      serviceFileName: names.serviceFileName,
      timerFileName: names.timerFileName,
      cause: StateError('Invalid retained install transaction state.'),
      causeStackTrace: StackTrace.current,
    );
  }
}

LinuxSystemdUserUnitStoreException _exception({
  required LinuxSystemdUserUnitStoreOperation operation,
  required LinuxSystemdUserUnitTransactionFailure failure,
  required String serviceFileName,
  required String timerFileName,
  required Object error,
  required StackTrace stackTrace,
  List<LinuxSystemdRollbackFailure> rollbackFailures =
      const <LinuxSystemdRollbackFailure>[],
}) {
  return LinuxSystemdUserUnitStoreException(
    operation: operation,
    transactionFailure: failure,
    serviceFileName: serviceFileName,
    timerFileName: timerFileName,
    cause: error,
    causeStackTrace: stackTrace,
    rollbackFailures: rollbackFailures,
  );
}

_PrimaryFailure _primaryFailure(Object error, StackTrace stackTrace) {
  if (error is LinuxSystemdUserUnitStoreException) {
    return _PrimaryFailure(
      error: error.cause,
      stackTrace: error.causeStackTrace,
      rollbackFailures: error.rollbackFailures,
    );
  }

  return _PrimaryFailure(
    error: error,
    stackTrace: stackTrace,
    rollbackFailures: const <LinuxSystemdRollbackFailure>[],
  );
}

final class _PrimaryFailure {
  const _PrimaryFailure({
    required this.error,
    required this.stackTrace,
    required this.rollbackFailures,
  });

  final Object error;
  final StackTrace stackTrace;
  final List<LinuxSystemdRollbackFailure> rollbackFailures;
}

final class _ExistingUnitSnapshot {
  _ExistingUnitSnapshot({required List<int> bytes, required this.mode})
    : bytes = List<int>.unmodifiable(bytes);

  final List<int> bytes;
  final int mode;
}

final class _UnitMutationState {
  _UnitMutationState({required this.previous});

  final _ExistingUnitSnapshot? previous;
  bool tempExists = false;
  bool backupExists = false;
  bool installed = false;
}

final class _InstallMutationState {
  const _InstallMutationState({required this.service, required this.timer});

  final _UnitMutationState service;
  final _UnitMutationState timer;
}

final class _UnitPaths {
  const _UnitPaths({
    required this.finalPath,
    required this.tempPath,
    required this.backupPath,
  });

  final String finalPath;
  final String tempPath;
  final String backupPath;
}

final class _InstallPaths {
  _InstallPaths({
    required this.directory,
    required String serviceFileName,
    required String timerFileName,
    required String transactionId,
  }) : service = _UnitPaths(
         finalPath: '$directory/$serviceFileName',
         tempPath: '$directory/.$serviceFileName.$transactionId.tmp',
         backupPath: '$directory/.$serviceFileName.$transactionId.bak',
       ),
       timer = _UnitPaths(
         finalPath: '$directory/$timerFileName',
         tempPath: '$directory/.$timerFileName.$transactionId.tmp',
         backupPath: '$directory/.$timerFileName.$transactionId.bak',
       );

  final String directory;
  final _UnitPaths service;
  final _UnitPaths timer;
}
