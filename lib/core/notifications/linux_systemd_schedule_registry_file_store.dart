import 'dart:collection';

import 'linux_systemd_file_system.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_schedule_registry.dart';
import 'linux_systemd_schedule_registry_codec.dart';
import 'linux_systemd_schedule_registry_exception.dart';
import 'linux_systemd_schedule_registry_store.dart';
import 'linux_systemd_user_unit_path_resolver.dart';

/// File-backed registry inventory stored beside app-owned systemd user units.
final class LinuxSystemdScheduleRegistryFileStore
    implements LinuxSystemdScheduleRegistryStore {
  const LinuxSystemdScheduleRegistryFileStore({
    required this.pathResolver,
    required this.fileSystem,
    required this.codec,
    required this.transactionIdFactory,
  });

  static const String registryFileName = 'borj-notification-registry.json';
  static const int registryFileMode = 0x180;

  static final RegExp _transactionIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static final RegExp _servicePattern = RegExp(
    r'^(borj-notification-[0-9a-f]{16})\.service$',
  );
  static final RegExp _timerPattern = RegExp(
    r'^(borj-notification-[0-9a-f]{16})\.timer$',
  );

  final LinuxSystemdUserUnitPathResolver pathResolver;
  final LinuxSystemdFileSystem fileSystem;
  final LinuxSystemdScheduleRegistryCodec codec;
  final LinuxSystemdRegistryTransactionIdFactory transactionIdFactory;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    final directory = _resolveDirectory(
      LinuxSystemdScheduleRegistryOperation.load,
    );
    final registryPath = '$directory/$registryFileName';
    final snapshot = await _loadSnapshot(
      registryPath,
      operation: LinuxSystemdScheduleRegistryOperation.load,
    );

    return snapshot.registry;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    final operation = LinuxSystemdScheduleRegistryOperation.replace;
    final directory = _resolveDirectory(operation);
    final registryPath = '$directory/$registryFileName';
    final snapshot = await _loadSnapshot(registryPath, operation: operation);

    if (next.generation != snapshot.registry.generation + 1) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure:
            LinuxSystemdScheduleRegistryFailure.invalidGenerationTransition,
        path: registryPath,
        field: 'generation',
      );
    }

    final nextBytes = _encodeForReplace(next, registryPath: registryPath);
    final transactionId = _createTransactionId(
      operation: operation,
      registryPath: registryPath,
    );
    final tempPath =
        '$directory/.borj-notification-registry.'
        '$transactionId.tmp';
    final backupPath =
        '$directory/.borj-notification-registry.'
        '$transactionId.bak';
    final state = _RegistryReplaceState();
    final rollbackFailures = <LinuxSystemdRegistryRollbackFailure>[];

    try {
      await fileSystem.createDirectory(directory);

      final finalType = await fileSystem.typeOf(registryPath);
      final expectedFinalType = snapshot.existed
          ? LinuxSystemdEntryType.regularFile
          : LinuxSystemdEntryType.missing;

      if (finalType != expectedFinalType) {
        throw LinuxSystemdScheduleRegistryException(
          operation: operation,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );
      }

      await _requireMissingTransactionPath(tempPath, operation: operation);
      await _requireMissingTransactionPath(backupPath, operation: operation);

      await fileSystem.writeBytes(tempPath, nextBytes);
      state.tempExists = true;

      await fileSystem.chmod(tempPath, registryFileMode);

      if (snapshot.existed) {
        await fileSystem.rename(registryPath, backupPath);
        state.backupExists = true;
      }

      await fileSystem.rename(tempPath, registryPath);
      state.tempExists = false;
      state.newFinalExists = true;

      await fileSystem.chmod(registryPath, registryFileMode);

      if (state.backupExists) {
        await fileSystem.deleteFile(backupPath);
        state.backupExists = false;
      }
    } catch (error, stackTrace) {
      await _rollbackReplace(
        registryPath: registryPath,
        tempPath: tempPath,
        backupPath: backupPath,
        snapshot: snapshot,
        state: state,
        failures: rollbackFailures,
      );

      Error.throwWithStackTrace(
        _replaceException(
          error,
          stackTrace,
          registryPath: registryPath,
          rollbackFailures: rollbackFailures,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> quarantineCorruptRegistry() async {
    final operation = LinuxSystemdScheduleRegistryOperation.quarantine;
    final directory = _resolveDirectory(operation);
    final registryPath = '$directory/$registryFileName';
    final entryType = await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.typeOf(registryPath),
    );

    switch (entryType) {
      case LinuxSystemdEntryType.missing:
        return;
      case LinuxSystemdEntryType.regularFile:
        break;
      case LinuxSystemdEntryType.directory:
      case LinuxSystemdEntryType.symbolicLink:
      case LinuxSystemdEntryType.other:
        throw LinuxSystemdScheduleRegistryException(
          operation: operation,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );
    }

    final transactionId = _createTransactionId(
      operation: operation,
      registryPath: registryPath,
    );
    final quarantinePath =
        '$directory/.borj-notification-registry.'
        '$transactionId.corrupt';
    final quarantineType = await _filesystemStep(
      operation,
      quarantinePath,
      () => fileSystem.typeOf(quarantinePath),
    );

    if (quarantineType != LinuxSystemdEntryType.missing) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        path: quarantinePath,
      );
    }

    await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.rename(registryPath, quarantinePath),
    );
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() async {
    final operation = LinuxSystemdScheduleRegistryOperation.discover;
    final directory = _resolveDirectory(operation);
    final names = await _filesystemStep(
      operation,
      directory,
      () => fileSystem.listNames(directory),
    );
    final grouped = SplayTreeMap<String, _DiscoveredUnitParts>();

    for (final name in names) {
      final serviceMatch = _servicePattern.firstMatch(name);
      final timerMatch = _timerPattern.firstMatch(name);

      if (serviceMatch == null && timerMatch == null) {
        continue;
      }

      final baseName = (serviceMatch ?? timerMatch)!.group(1)!;
      final path = '$directory/$name';
      final entryType = await _filesystemStep(
        operation,
        path,
        () => fileSystem.typeOf(path),
      );

      if (entryType != LinuxSystemdEntryType.regularFile) {
        throw LinuxSystemdScheduleRegistryException(
          operation: operation,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeAppUnitPath,
          path: path,
        );
      }

      final parts = grouped.putIfAbsent(baseName, _DiscoveredUnitParts.new);

      if (serviceMatch != null) {
        parts.hasService = true;
      } else {
        parts.hasTimer = true;
      }
    }

    final complete = <LinuxSystemdUnitNames>[];
    final partial = <LinuxSystemdPartialUnitPair>[];

    for (final entry in grouped.entries) {
      final parts = entry.value;

      if (parts.hasService && parts.hasTimer) {
        complete.add(LinuxSystemdUnitNames.parseBaseName(entry.key));
      } else {
        partial.add(
          LinuxSystemdPartialUnitPair(
            baseName: entry.key,
            hasService: parts.hasService,
            hasTimer: parts.hasTimer,
          ),
        );
      }
    }

    return LinuxSystemdUnitDiscovery(
      completePairs: complete,
      partialPairs: partial,
    );
  }

  Future<_RegistrySnapshot> _loadSnapshot(
    String registryPath, {
    required LinuxSystemdScheduleRegistryOperation operation,
  }) async {
    final entryType = await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.typeOf(registryPath),
    );

    switch (entryType) {
      case LinuxSystemdEntryType.missing:
        return _RegistrySnapshot.missing();
      case LinuxSystemdEntryType.regularFile:
        break;
      case LinuxSystemdEntryType.directory:
      case LinuxSystemdEntryType.symbolicLink:
      case LinuxSystemdEntryType.other:
        throw LinuxSystemdScheduleRegistryException(
          operation: operation,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );
    }

    final length = await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.fileLength(registryPath),
    );

    if (length > LinuxSystemdScheduleRegistryCodec.maximumFileBytes) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
        path: registryPath,
      );
    }

    final bytes = await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.readBytes(registryPath),
    );
    final mode = await _filesystemStep(
      operation,
      registryPath,
      () => fileSystem.readMode(registryPath),
    );

    if (mode != registryFileMode) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: LinuxSystemdScheduleRegistryFailure.insecureRegistryMode,
        path: registryPath,
      );
    }

    try {
      return _RegistrySnapshot.existing(
        registry: codec.decodeBytes(bytes),
        bytes: bytes,
        mode: mode,
      );
    } on LinuxSystemdScheduleRegistryException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LinuxSystemdScheduleRegistryException(
          operation: operation,
          failure: error.failure,
          path: registryPath,
          field: error.field,
          cause: error,
          causeStackTrace: stackTrace,
          rollbackFailures: error.rollbackFailures,
        ),
        stackTrace,
      );
    }
  }

  List<int> _encodeForReplace(
    LinuxSystemdScheduleRegistry next, {
    required String registryPath,
  }) {
    try {
      return codec.encodeBytes(next);
    } on LinuxSystemdScheduleRegistryException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.replace,
          failure: error.failure,
          path: registryPath,
          field: error.field,
          cause: error,
          causeStackTrace: stackTrace,
          rollbackFailures: error.rollbackFailures,
        ),
        stackTrace,
      );
    }
  }

  String _createTransactionId({
    required LinuxSystemdScheduleRegistryOperation operation,
    required String registryPath,
  }) {
    late final String transactionId;

    try {
      transactionId = transactionIdFactory();
    } catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: _failureForOperation(operation),
        path: registryPath,
        field: 'transactionId',
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    if (!_transactionIdPattern.hasMatch(transactionId)) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        path: registryPath,
        field: 'transactionId',
      );
    }

    return transactionId;
  }

  Future<void> _requireMissingTransactionPath(
    String path, {
    required LinuxSystemdScheduleRegistryOperation operation,
  }) async {
    final entryType = await fileSystem.typeOf(path);

    if (entryType != LinuxSystemdEntryType.missing) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        path: path,
      );
    }
  }

  Future<void> _rollbackReplace({
    required String registryPath,
    required String tempPath,
    required String backupPath,
    required _RegistrySnapshot snapshot,
    required _RegistryReplaceState state,
    required List<LinuxSystemdRegistryRollbackFailure> failures,
  }) async {
    if (state.newFinalExists) {
      final deleted = await _attemptRollback(
        step: 'delete-new-registry',
        action: () => fileSystem.deleteFile(registryPath),
        failures: failures,
      );

      if (deleted) {
        state.newFinalExists = false;
      }
    }

    if (snapshot.existed && state.backupExists) {
      final restored = await _attemptRollback(
        step: 'restore-registry-backup',
        action: () => fileSystem.rename(backupPath, registryPath),
        failures: failures,
      );

      if (restored) {
        state.backupExists = false;
      } else {
        final rewritten = await _attemptRollback(
          step: 'rewrite-previous-registry',
          action: () => fileSystem.writeBytes(registryPath, snapshot.bytes),
          failures: failures,
        );

        if (rewritten) {
          final modeRestored = await _attemptRollback(
            step: 'restore-previous-registry-mode',
            action: () => fileSystem.chmod(registryPath, snapshot.mode!),
            failures: failures,
          );

          if (modeRestored) {
            final backupDeleted = await _attemptRollback(
              step: 'delete-registry-backup',
              action: () => fileSystem.deleteFile(backupPath),
              failures: failures,
            );

            if (backupDeleted) {
              state.backupExists = false;
            }
          }
        }
      }
    }

    if (state.tempExists) {
      final deleted = await _attemptRollback(
        step: 'delete-registry-temp',
        action: () => fileSystem.deleteFile(tempPath),
        failures: failures,
      );

      if (deleted) {
        state.tempExists = false;
      }
    }
  }

  Future<bool> _attemptRollback({
    required String step,
    required Future<void> Function() action,
    required List<LinuxSystemdRegistryRollbackFailure> failures,
  }) async {
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      failures.add(
        LinuxSystemdRegistryRollbackFailure(
          step: step,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }
  }

  LinuxSystemdScheduleRegistryException _replaceException(
    Object error,
    StackTrace stackTrace, {
    required String registryPath,
    required List<LinuxSystemdRegistryRollbackFailure> rollbackFailures,
  }) {
    if (error is LinuxSystemdScheduleRegistryException &&
        error.operation == LinuxSystemdScheduleRegistryOperation.replace) {
      return LinuxSystemdScheduleRegistryException(
        operation: error.operation,
        failure: error.failure,
        path: error.path ?? registryPath,
        field: error.field,
        cause: error.cause,
        causeStackTrace: error.causeStackTrace ?? stackTrace,
        rollbackFailures: <LinuxSystemdRegistryRollbackFailure>[
          ...error.rollbackFailures,
          ...rollbackFailures,
        ],
      );
    }

    return LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.replace,
      failure: LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
      path: registryPath,
      cause: error,
      causeStackTrace: stackTrace,
      rollbackFailures: rollbackFailures,
    );
  }

  String _resolveDirectory(LinuxSystemdScheduleRegistryOperation operation) {
    try {
      return pathResolver.resolve();
    } catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: _failureForOperation(operation),
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  Future<T> _filesystemStep<T>(
    LinuxSystemdScheduleRegistryOperation operation,
    String path,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: operation,
        failure: _failureForOperation(operation),
        path: path,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  LinuxSystemdScheduleRegistryFailure _failureForOperation(
    LinuxSystemdScheduleRegistryOperation operation,
  ) {
    return switch (operation) {
      LinuxSystemdScheduleRegistryOperation.load =>
        LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
      LinuxSystemdScheduleRegistryOperation.replace =>
        LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
      LinuxSystemdScheduleRegistryOperation.quarantine =>
        LinuxSystemdScheduleRegistryFailure.quarantineFailed,
      LinuxSystemdScheduleRegistryOperation.discover =>
        LinuxSystemdScheduleRegistryFailure.discoveryFailed,
      LinuxSystemdScheduleRegistryOperation.validate =>
        LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
      LinuxSystemdScheduleRegistryOperation.decode =>
        LinuxSystemdScheduleRegistryFailure.malformedJson,
    };
  }
}

final class _RegistrySnapshot {
  const _RegistrySnapshot._({
    required this.registry,
    required this.existed,
    required this.bytes,
    required this.mode,
  });

  factory _RegistrySnapshot.missing() {
    return _RegistrySnapshot._(
      registry: LinuxSystemdScheduleRegistry.empty(),
      existed: false,
      bytes: const <int>[],
      mode: null,
    );
  }

  factory _RegistrySnapshot.existing({
    required LinuxSystemdScheduleRegistry registry,
    required List<int> bytes,
    required int mode,
  }) {
    return _RegistrySnapshot._(
      registry: registry,
      existed: true,
      bytes: List<int>.unmodifiable(bytes),
      mode: mode,
    );
  }

  final LinuxSystemdScheduleRegistry registry;
  final bool existed;
  final List<int> bytes;
  final int? mode;
}

final class _RegistryReplaceState {
  bool tempExists = false;
  bool backupExists = false;
  bool newFinalExists = false;
}

final class _DiscoveredUnitParts {
  bool hasService = false;
  bool hasTimer = false;
}
