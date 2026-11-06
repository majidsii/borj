import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('LinuxSystemdUserUnitStore.beginInstall', () {
    test(
      'returns a pending retained transaction without mutating files',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();

        final transaction = await _store(fileSystem).beginInstall(units);

        expect(transaction.state, LinuxSystemdUnitTransactionState.pending);
        expect(transaction.names, _names());
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
      },
    );

    for (final previous in _PreviousPair.values) {
      test(
        'snapshots ${previous.name} previous pair without mutation',
        () async {
          final fileSystem = FakeLinuxSystemdFileSystem();
          final units = _units();
          _seedPrevious(fileSystem, units, previous);

          final transaction = await _store(fileSystem).beginInstall(units);

          await transaction.rollback();

          expect(
            transaction.state,
            LinuxSystemdUnitTransactionState.rolledBack,
          );
          _expectPrevious(fileSystem, units, previous);
          _expectNoArtifacts(fileSystem, units);
        },
      );
    }

    test(
      'rejects an unsafe transaction id before filesystem mutation',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();

        final error = await _expectStoreFailure(
          () => _store(
            fileSystem,
            transactionId: '../unsafe',
          ).beginInstall(_units()),
          LinuxSystemdUserUnitStoreOperation.beginInstall,
        );

        expect(
          error.transactionFailure,
          LinuxSystemdUserUnitTransactionFailure.invalidState,
        );
        expect(fileSystem.operations, isEmpty);
      },
    );

    for (final unsafe in <LinuxSystemdEntryType>[
      LinuxSystemdEntryType.directory,
      LinuxSystemdEntryType.symbolicLink,
      LinuxSystemdEntryType.other,
    ]) {
      test('rejects unsafe final ${unsafe.name}', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        _seedUnsafe(fileSystem, _serviceFinal(units), unsafe);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).beginInstall(units),
          LinuxSystemdUserUnitStoreOperation.beginInstall,
        );

        expect(
          error.transactionFailure,
          LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        );
        expect(error.cause, isA<LinuxSystemdUnsafeEntryException>());
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
      });
    }

    for (final artifact in <String Function(LinuxSystemdRenderedUnits)>[
      _serviceTemp,
      _timerTemp,
      _serviceBackup,
      _timerBackup,
    ]) {
      test('rejects a pre-existing transaction artifact', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        final path = artifact(units);
        fileSystem.seedFile(path, const <int>[1], mode: 0x180);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).beginInstall(units),
          LinuxSystemdUserUnitStoreOperation.beginInstall,
        );

        expect(
          error.transactionFailure,
          LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        );
        expect(fileSystem.containsPath(path), isTrue);
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
      });
    }
  });

  group('retained install apply', () {
    for (final previous in _PreviousPair.values) {
      test('applies over ${previous.name} and retains exact backups', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        _seedPrevious(fileSystem, units, previous);
        final transaction = await _store(fileSystem).beginInstall(units);

        await transaction.apply();

        expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
        expect(fileSystem.textOf(_serviceFinal(units)), units.serviceContents);
        expect(fileSystem.textOf(_timerFinal(units)), units.timerContents);
        expect(fileSystem.modeOf(_serviceFinal(units)), 0x1A4);
        expect(fileSystem.modeOf(_timerFinal(units)), 0x1A4);

        final hadService =
            previous == _PreviousPair.serviceOnly ||
            previous == _PreviousPair.complete;
        final hadTimer =
            previous == _PreviousPair.timerOnly ||
            previous == _PreviousPair.complete;

        expect(fileSystem.containsPath(_serviceBackup(units)), hadService);
        expect(fileSystem.containsPath(_timerBackup(units)), hadTimer);

        if (hadService) {
          expect(
            fileSystem.bytesOf(_serviceBackup(units)),
            utf8.encode(_oldService),
          );
          expect(fileSystem.modeOf(_serviceBackup(units)), _oldServiceMode);
        }
        if (hadTimer) {
          expect(
            fileSystem.bytesOf(_timerBackup(units)),
            utf8.encode(_oldTimer),
          );
          expect(fileSystem.modeOf(_timerBackup(units)), _oldTimerMode);
        }

        expect(fileSystem.containsPath(_serviceTemp(units)), isFalse);
        expect(fileSystem.containsPath(_timerTemp(units)), isFalse);
      });
    }

    test('uses the deterministic retained-install operation order', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _units();
      _seedPrevious(fileSystem, units, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginInstall(units);
      fileSystem.operations.clear();

      await transaction.apply();

      expect(fileSystem.operations, <String>[
        'createDirectory:$_directory',
        'write:${_serviceTemp(units)}',
        'write:${_timerTemp(units)}',
        'chmod:${_serviceTemp(units)}:420',
        'chmod:${_timerTemp(units)}:420',
        'rename:${_serviceFinal(units)}->${_serviceBackup(units)}',
        'rename:${_timerFinal(units)}->${_timerBackup(units)}',
        'rename:${_serviceTemp(units)}->${_serviceFinal(units)}',
        'rename:${_timerTemp(units)}->${_timerFinal(units)}',
        'chmod:${_serviceFinal(units)}:420',
        'chmod:${_timerFinal(units)}:420',
      ]);
    });

    test('apply is idempotent after success', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final transaction = await _store(fileSystem).beginInstall(_units());

      await transaction.apply();
      final operationsAfterFirst = List<String>.from(fileSystem.operations);
      await transaction.apply();

      expect(fileSystem.operations, operationsAfterFirst);
      expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
    });
  });

  group('retained install finalize', () {
    test('deletes retained backups and becomes idempotent', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _units();
      _seedPrevious(fileSystem, units, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginInstall(units);

      await transaction.apply();
      await transaction.finalize();
      final operationsAfterFirst = List<String>.from(fileSystem.operations);
      await transaction.finalize();

      expect(transaction.state, LinuxSystemdUnitTransactionState.finalized);
      expect(fileSystem.containsPath(_serviceBackup(units)), isFalse);
      expect(fileSystem.containsPath(_timerBackup(units)), isFalse);
      expect(fileSystem.operations, operationsAfterFirst);
      expect(fileSystem.textOf(_serviceFinal(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerFinal(units)), units.timerContents);
    });

    test('rejects finalize before apply as invalidState', () async {
      final transaction = await _store(
        FakeLinuxSystemdFileSystem(),
      ).beginInstall(_units());

      final error = await _expectStoreFailure(
        transaction.finalize,
        LinuxSystemdUserUnitStoreOperation.finalizeInstall,
      );

      expect(
        error.transactionFailure,
        LinuxSystemdUserUnitTransactionFailure.invalidState,
      );
    });

    test('rejects rollback after finalize as invalidState', () async {
      final transaction = await _store(
        FakeLinuxSystemdFileSystem(),
      ).beginInstall(_units());
      await transaction.apply();
      await transaction.finalize();

      final error = await _expectStoreFailure(
        transaction.rollback,
        LinuxSystemdUserUnitStoreOperation.rollbackInstall,
      );

      expect(
        error.transactionFailure,
        LinuxSystemdUserUnitTransactionFailure.invalidState,
      );
    });
  });

  group('retained install rollback', () {
    for (final previous in _PreviousPair.values) {
      test('restores exact ${previous.name} state after apply', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        _seedPrevious(fileSystem, units, previous);
        final transaction = await _store(fileSystem).beginInstall(units);

        await transaction.apply();
        await transaction.rollback();
        final operationsAfterFirst = List<String>.from(fileSystem.operations);
        await transaction.rollback();

        expect(transaction.state, LinuxSystemdUnitTransactionState.rolledBack);
        expect(fileSystem.operations, operationsAfterFirst);
        _expectPrevious(fileSystem, units, previous);
        _expectNoArtifacts(fileSystem, units);
      });
    }

    test('deletes the new timer before the new service', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _units();
      final transaction = await _store(fileSystem).beginInstall(units);
      await transaction.apply();
      fileSystem.operations.clear();

      await transaction.rollback();

      final timerDelete = fileSystem.operations.indexOf(
        'delete:${_timerFinal(units)}',
      );
      final serviceDelete = fileSystem.operations.indexOf(
        'delete:${_serviceFinal(units)}',
      );
      expect(timerDelete, isNonNegative);
      expect(serviceDelete, greaterThan(timerDelete));
    });

    test(
      'rollback from pending is idempotent and performs no mutation',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final transaction = await _store(fileSystem).beginInstall(_units());
        fileSystem.operations.clear();

        await transaction.rollback();
        await transaction.rollback();

        expect(fileSystem.operations, isEmpty);
        expect(transaction.state, LinuxSystemdUnitTransactionState.rolledBack);
      },
    );
  });

  group('retained install failure recovery', () {
    test('every apply failure can roll back a complete prior pair', () async {
      final units = _units();
      final failurePoints = <String>[
        'createDirectory:$_directory',
        'write:${_serviceTemp(units)}',
        'write:${_timerTemp(units)}',
        'chmod:${_serviceTemp(units)}:420',
        'chmod:${_timerTemp(units)}:420',
        'rename:${_serviceFinal(units)}->${_serviceBackup(units)}',
        'rename:${_timerFinal(units)}->${_timerBackup(units)}',
        'rename:${_serviceTemp(units)}->${_serviceFinal(units)}',
        'rename:${_timerTemp(units)}->${_timerFinal(units)}',
        'chmod:${_serviceFinal(units)}:420',
        'chmod:${_timerFinal(units)}:420',
      ];

      for (final failurePoint in failurePoints) {
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedPrevious(fileSystem, units, _PreviousPair.complete);
        final transaction = await _store(fileSystem).beginInstall(units);
        final cause = StateError('failure at $failurePoint');
        fileSystem.failNext(failurePoint, error: cause);

        final error = await _expectStoreFailure(
          transaction.apply,
          LinuxSystemdUserUnitStoreOperation.applyInstall,
        );
        expect(error.cause, same(cause));

        await transaction.rollback();

        _expectPrevious(fileSystem, units, _PreviousPair.complete);
        _expectNoArtifacts(fileSystem, units);
      }
    });

    test(
      'finalize failure remains rollback-capable through snapshots',
      () async {
        final units = _units();

        for (final failurePoint in <String>[
          'delete:${_serviceBackup(units)}',
          'delete:${_timerBackup(units)}',
        ]) {
          final fileSystem = FakeLinuxSystemdFileSystem();
          _seedPrevious(fileSystem, units, _PreviousPair.complete);
          final transaction = await _store(fileSystem).beginInstall(units);
          await transaction.apply();
          final cause = StateError('failure at $failurePoint');
          fileSystem.failNext(failurePoint, error: cause);

          final error = await _expectStoreFailure(
            transaction.finalize,
            LinuxSystemdUserUnitStoreOperation.finalizeInstall,
          );
          expect(error.cause, same(cause));

          await transaction.rollback();

          _expectPrevious(fileSystem, units, _PreviousPair.complete);
          _expectNoArtifacts(fileSystem, units);
        }
      },
    );

    test(
      'rollback reports ordered failures without stopping cleanup',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        _seedPrevious(fileSystem, units, _PreviousPair.complete);
        final transaction = await _store(fileSystem).beginInstall(units);
        await transaction.apply();

        final first = StateError('timer delete');
        final second = StateError('service backup restore');
        fileSystem
          ..failNext('delete:${_timerFinal(units)}', error: first)
          ..failNext(
            'rename:${_serviceBackup(units)}->${_serviceFinal(units)}',
            error: second,
          );

        final error = await _expectStoreFailure(
          transaction.rollback,
          LinuxSystemdUserUnitStoreOperation.rollbackInstall,
        );

        expect(error.cause, same(first));
        expect(
          error.rollbackFailures.map((failure) => failure.step),
          orderedEquals(<String>['delete-new-timer', 'restore-service-backup']),
        );
        expect(
          error.rollbackFailures.map((failure) => failure.error),
          orderedEquals(<Object>[first, second]),
        );
        expect(error.toString(), isNot(contains('timer delete')));
        expect(error.toString(), isNot(contains('service backup restore')));
      },
    );
  });

  group('install convenience wrapper', () {
    test('applies and finalizes retained installation', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _units();
      _seedPrevious(fileSystem, units, _PreviousPair.complete);

      await _store(fileSystem).install(units);

      expect(fileSystem.textOf(_serviceFinal(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerFinal(units)), units.timerContents);
      _expectNoArtifacts(fileSystem, units);
    });

    test(
      'preserves the raw primary cause and rolls back on apply failure',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = _units();
        _seedPrevious(fileSystem, units, _PreviousPair.complete);
        final cause = StateError('TOP_SECRET_PRIMARY');
        fileSystem.failNext(
          'rename:${_timerTemp(units)}->${_timerFinal(units)}',
          error: cause,
        );

        final error = await _expectStoreFailure(
          () => _store(fileSystem).install(units),
          LinuxSystemdUserUnitStoreOperation.install,
        );

        expect(error.cause, same(cause));
        expect(error.toString(), isNot(contains('TOP_SECRET_PRIMARY')));
        _expectPrevious(fileSystem, units, _PreviousPair.complete);
        _expectNoArtifacts(fileSystem, units);
      },
    );
  });
}

const String _directory = '/config/systemd/user';
const String _transactionId = 'txn-1';
const String _oldService = '[Service]\nOldService=true\n';
const String _oldTimer = '[Timer]\nOldTimer=true\n';
const int _oldServiceMode = 0x180;
const int _oldTimerMode = 0x1A0;

enum _PreviousPair { missing, serviceOnly, timerOnly, complete }

LinuxSystemdUnitNames _names() {
  return LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
}

LinuxSystemdRenderedUnits _units() {
  final names = _names();
  return LinuxSystemdRenderedUnits(
    serviceFileName: names.serviceFileName,
    timerFileName: names.timerFileName,
    serviceContents: '[Service]\nNewService=true\n',
    timerContents: '[Timer]\nNewTimer=true\n',
  );
}

LinuxSystemdUserUnitStore _store(
  FakeLinuxSystemdFileSystem fileSystem, {
  String transactionId = _transactionId,
}) {
  return LinuxSystemdUserUnitStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      _MapEnvironment(const <String, String>{'XDG_CONFIG_HOME': '/config'}),
    ),
    fileSystem: fileSystem,
    transactionIdFactory: () => transactionId,
  );
}

void _seedPrevious(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdRenderedUnits units,
  _PreviousPair previous,
) {
  if (previous == _PreviousPair.serviceOnly ||
      previous == _PreviousPair.complete) {
    fileSystem.seedFile(
      _serviceFinal(units),
      utf8.encode(_oldService),
      mode: _oldServiceMode,
    );
  }

  if (previous == _PreviousPair.timerOnly ||
      previous == _PreviousPair.complete) {
    fileSystem.seedFile(
      _timerFinal(units),
      utf8.encode(_oldTimer),
      mode: _oldTimerMode,
    );
  }
}

void _expectPrevious(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdRenderedUnits units,
  _PreviousPair previous,
) {
  final expectsService =
      previous == _PreviousPair.serviceOnly ||
      previous == _PreviousPair.complete;
  final expectsTimer =
      previous == _PreviousPair.timerOnly || previous == _PreviousPair.complete;

  expect(fileSystem.containsPath(_serviceFinal(units)), expectsService);
  expect(fileSystem.containsPath(_timerFinal(units)), expectsTimer);

  if (expectsService) {
    expect(fileSystem.textOf(_serviceFinal(units)), _oldService);
    expect(fileSystem.modeOf(_serviceFinal(units)), _oldServiceMode);
  }
  if (expectsTimer) {
    expect(fileSystem.textOf(_timerFinal(units)), _oldTimer);
    expect(fileSystem.modeOf(_timerFinal(units)), _oldTimerMode);
  }
}

void _expectNoArtifacts(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdRenderedUnits units,
) {
  expect(fileSystem.containsPath(_serviceTemp(units)), isFalse);
  expect(fileSystem.containsPath(_timerTemp(units)), isFalse);
  expect(fileSystem.containsPath(_serviceBackup(units)), isFalse);
  expect(fileSystem.containsPath(_timerBackup(units)), isFalse);
}

void _seedUnsafe(
  FakeLinuxSystemdFileSystem fileSystem,
  String path,
  LinuxSystemdEntryType type,
) {
  switch (type) {
    case LinuxSystemdEntryType.directory:
      fileSystem.seedDirectory(path);
    case LinuxSystemdEntryType.symbolicLink:
      fileSystem.seedSymlink(path, '/outside/target');
    case LinuxSystemdEntryType.other:
      fileSystem.seedOther(path);
    case LinuxSystemdEntryType.regularFile:
      fileSystem.seedFile(path, const <int>[1], mode: 0x180);
    case LinuxSystemdEntryType.missing:
      fail('Missing must not be seeded.');
  }
}

bool _isMutationOperation(String operation) {
  return operation.startsWith('createDirectory:') ||
      operation.startsWith('write:') ||
      operation.startsWith('chmod:') ||
      operation.startsWith('rename:') ||
      operation.startsWith('delete:');
}

String _serviceFinal(LinuxSystemdRenderedUnits units) {
  return '$_directory/${units.serviceFileName}';
}

String _timerFinal(LinuxSystemdRenderedUnits units) {
  return '$_directory/${units.timerFileName}';
}

String _serviceTemp(LinuxSystemdRenderedUnits units) {
  return '$_directory/.${units.serviceFileName}.$_transactionId.tmp';
}

String _timerTemp(LinuxSystemdRenderedUnits units) {
  return '$_directory/.${units.timerFileName}.$_transactionId.tmp';
}

String _serviceBackup(LinuxSystemdRenderedUnits units) {
  return '$_directory/.${units.serviceFileName}.$_transactionId.bak';
}

String _timerBackup(LinuxSystemdRenderedUnits units) {
  return '$_directory/.${units.timerFileName}.$_transactionId.bak';
}

Future<LinuxSystemdUserUnitStoreException> _expectStoreFailure(
  Future<Object?> Function() action,
  LinuxSystemdUserUnitStoreOperation operation,
) async {
  try {
    await action();
    fail('Expected LinuxSystemdUserUnitStoreException.');
  } on LinuxSystemdUserUnitStoreException catch (error) {
    expect(error.operation, operation);
    return error;
  }
}

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}
