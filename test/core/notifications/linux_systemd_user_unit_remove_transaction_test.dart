import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('LinuxSystemdUserUnitStore.beginRemove', () {
    for (final previous in _PreviousPair.values) {
      test('snapshots ${previous.name} without deleting either unit', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, previous);

        final transaction = await _store(fileSystem).beginRemove(names);

        expect(transaction.state, LinuxSystemdUnitTransactionState.pending);
        expect(transaction.names, names);
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
        _expectPrevious(fileSystem, names, previous);
      });
    }

    test('reads exact bytes and modes into an immutable snapshot', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);

      final transaction = await _store(fileSystem).beginRemove(names);

      fileSystem.seedFile(
        _servicePath(names),
        utf8.encode('mutated service'),
        mode: 0x1A4,
      );
      fileSystem.seedFile(
        _timerPath(names),
        utf8.encode('mutated timer'),
        mode: 0x1A4,
      );

      await transaction.apply();
      await transaction.rollback();

      _expectPrevious(fileSystem, names, _PreviousPair.complete);
    });

    for (final unsafe in <LinuxSystemdEntryType>[
      LinuxSystemdEntryType.directory,
      LinuxSystemdEntryType.symbolicLink,
      LinuxSystemdEntryType.other,
    ]) {
      test('rejects unsafe timer ${unsafe.name} without mutation', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        fileSystem.seedFile(
          _servicePath(names),
          utf8.encode(_oldService),
          mode: _oldServiceMode,
        );
        _seedUnsafe(fileSystem, _timerPath(names), unsafe);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).beginRemove(names),
          LinuxSystemdUserUnitStoreOperation.beginRemove,
        );

        expect(
          error.transactionFailure,
          LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        );
        expect(error.cause, isA<LinuxSystemdUnsafeEntryException>());
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
        expect(fileSystem.containsPath(_servicePath(names)), isTrue);
      });

      test('rejects unsafe service ${unsafe.name} without mutation', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        fileSystem.seedFile(
          _timerPath(names),
          utf8.encode(_oldTimer),
          mode: _oldTimerMode,
        );
        _seedUnsafe(fileSystem, _servicePath(names), unsafe);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).beginRemove(names),
          LinuxSystemdUserUnitStoreOperation.beginRemove,
        );

        expect(
          error.transactionFailure,
          LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        );
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
        expect(fileSystem.containsPath(_timerPath(names)), isTrue);
      });
    }

    for (final failurePoint in <String Function(LinuxSystemdUnitNames)>[
      (names) => 'read:${_servicePath(names)}',
      (names) => 'readMode:${_servicePath(names)}',
      (names) => 'read:${_timerPath(names)}',
      (names) => 'readMode:${_timerPath(names)}',
    ]) {
      test('wraps snapshot failure without mutation', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, _PreviousPair.complete);
        final operation = failurePoint(names);
        final cause = StateError('TOP_SECRET_SNAPSHOT_FAILURE');
        fileSystem.failNext(operation, error: cause);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).beginRemove(names),
          LinuxSystemdUserUnitStoreOperation.beginRemove,
        );

        expect(error.cause, same(cause));
        expect(
          error.toString(),
          isNot(contains('TOP_SECRET_SNAPSHOT_FAILURE')),
        );
        expect(fileSystem.operations.any(_isMutationOperation), isFalse);
        _expectPrevious(fileSystem, names, _PreviousPair.complete);
      });
    }
  });

  group('retained remove apply', () {
    for (final previous in _PreviousPair.values) {
      test('applies exact ${previous.name} removal', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, previous);
        final transaction = await _store(fileSystem).beginRemove(names);

        await transaction.apply();

        expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
        expect(fileSystem.containsPath(_timerPath(names)), isFalse);
        expect(fileSystem.containsPath(_servicePath(names)), isFalse);
      });
    }

    test('deletes timer before service', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      fileSystem.operations.clear();

      await transaction.apply();

      expect(fileSystem.operations, <String>[
        'delete:${_timerPath(names)}',
        'delete:${_servicePath(names)}',
      ]);
    });

    test('apply is idempotent after successful removal', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);

      await transaction.apply();
      final afterFirst = List<String>.from(fileSystem.operations);
      await transaction.apply();

      expect(fileSystem.operations, afterFirst);
      expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
    });

    test('timer deletion failure prevents service deletion', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      final cause = StateError('timer delete failure');
      fileSystem.failNext('delete:${_timerPath(names)}', error: cause);

      final error = await _expectStoreFailure(
        transaction.apply,
        LinuxSystemdUserUnitStoreOperation.applyRemove,
      );

      expect(error.cause, same(cause));
      expect(fileSystem.containsPath(_timerPath(names)), isTrue);
      expect(fileSystem.containsPath(_servicePath(names)), isTrue);
      expect(
        fileSystem.operations,
        isNot(contains('delete:${_servicePath(names)}')),
      );
    });

    test('service deletion failure remains rollback-capable', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      final cause = StateError('service delete failure');
      fileSystem.failNext('delete:${_servicePath(names)}', error: cause);

      final error = await _expectStoreFailure(
        transaction.apply,
        LinuxSystemdUserUnitStoreOperation.applyRemove,
      );
      expect(error.cause, same(cause));
      expect(fileSystem.containsPath(_timerPath(names)), isFalse);
      expect(fileSystem.containsPath(_servicePath(names)), isTrue);

      await transaction.rollback();

      _expectPrevious(fileSystem, names, _PreviousPair.complete);
    });
  });

  group('retained remove finalize', () {
    test('releases rollback state and becomes idempotent', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);

      await transaction.apply();
      await transaction.finalize();
      final afterFirst = List<String>.from(fileSystem.operations);
      await transaction.finalize();

      expect(transaction.state, LinuxSystemdUnitTransactionState.finalized);
      expect(fileSystem.operations, afterFirst);
      expect(fileSystem.containsPath(_timerPath(names)), isFalse);
      expect(fileSystem.containsPath(_servicePath(names)), isFalse);
    });

    test('rejects finalize before apply', () async {
      final transaction = await _store(
        FakeLinuxSystemdFileSystem(),
      ).beginRemove(_names());

      final error = await _expectStoreFailure(
        transaction.finalize,
        LinuxSystemdUserUnitStoreOperation.finalizeRemove,
      );

      expect(
        error.transactionFailure,
        LinuxSystemdUserUnitTransactionFailure.invalidState,
      );
    });

    test('rejects rollback after finalize', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      await transaction.apply();
      await transaction.finalize();

      final error = await _expectStoreFailure(
        transaction.rollback,
        LinuxSystemdUserUnitStoreOperation.rollbackRemove,
      );

      expect(
        error.transactionFailure,
        LinuxSystemdUserUnitTransactionFailure.invalidState,
      );
    });
  });

  group('retained remove rollback', () {
    for (final previous in _PreviousPair.values) {
      test('restores exact ${previous.name} bytes and modes', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, previous);
        final transaction = await _store(fileSystem).beginRemove(names);

        await transaction.apply();
        await transaction.rollback();
        final afterFirst = List<String>.from(fileSystem.operations);
        await transaction.rollback();

        expect(transaction.state, LinuxSystemdUnitTransactionState.rolledBack);
        expect(fileSystem.operations, afterFirst);
        _expectPrevious(fileSystem, names, previous);
      });
    }

    test('restores service before timer', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      await transaction.apply();
      fileSystem.operations.clear();

      await transaction.rollback();

      expect(fileSystem.operations, <String>[
        'write:${_servicePath(names)}',
        'chmod:${_servicePath(names)}:384',
        'write:${_timerPath(names)}',
        'chmod:${_timerPath(names)}:416',
      ]);
    });

    test(
      'rollback from untouched pending state performs no mutation',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, _PreviousPair.complete);
        final transaction = await _store(fileSystem).beginRemove(names);
        fileSystem.operations.clear();

        await transaction.rollback();
        await transaction.rollback();

        expect(fileSystem.operations, isEmpty);
        expect(transaction.state, LinuxSystemdUnitTransactionState.rolledBack);
        _expectPrevious(fileSystem, names, _PreviousPair.complete);
      },
    );

    test('records snapshot write failure and continues with timer', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      await transaction.apply();

      final cause = StateError('service snapshot write');
      fileSystem.failNext('write:${_servicePath(names)}', error: cause);

      final error = await _expectStoreFailure(
        transaction.rollback,
        LinuxSystemdUserUnitStoreOperation.rollbackRemove,
      );

      expect(error.cause, same(cause));
      expect(
        error.rollbackFailures.map((failure) => failure.step),
        orderedEquals(<String>['restore-service-snapshot-write']),
      );
      expect(fileSystem.containsPath(_servicePath(names)), isFalse);
      expect(fileSystem.textOf(_timerPath(names)), _oldTimer);
      expect(fileSystem.modeOf(_timerPath(names)), _oldTimerMode);
    });

    test('records mode restoration failure without hiding primary', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      await transaction.apply();

      final cause = StateError('service mode restore');
      fileSystem.failNext(
        'chmod:${_servicePath(names)}:$_oldServiceMode',
        error: cause,
      );

      final error = await _expectStoreFailure(
        transaction.rollback,
        LinuxSystemdUserUnitStoreOperation.rollbackRemove,
      );

      expect(error.cause, same(cause));
      expect(
        error.rollbackFailures.map((failure) => failure.step),
        orderedEquals(<String>['restore-service-snapshot-mode']),
      );
      expect(fileSystem.textOf(_timerPath(names)), _oldTimer);
      expect(fileSystem.modeOf(_timerPath(names)), _oldTimerMode);
    });

    test('aggregates rollback failures in encounter order', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final transaction = await _store(fileSystem).beginRemove(names);
      await transaction.apply();

      final first = StateError('service write');
      final second = StateError('timer mode');
      fileSystem
        ..failNext('write:${_servicePath(names)}', error: first)
        ..failNext('chmod:${_timerPath(names)}:$_oldTimerMode', error: second);

      final error = await _expectStoreFailure(
        transaction.rollback,
        LinuxSystemdUserUnitStoreOperation.rollbackRemove,
      );

      expect(error.cause, same(first));
      expect(
        error.rollbackFailures.map((failure) => failure.step),
        orderedEquals(<String>[
          'restore-service-snapshot-write',
          'restore-timer-snapshot-mode',
        ]),
      );
      expect(
        error.rollbackFailures.map((failure) => failure.error),
        orderedEquals(<Object>[first, second]),
      );
      expect(error.toString(), isNot(contains('service write')));
      expect(error.toString(), isNot(contains('timer mode')));
    });
  });

  group('remove convenience wrapper', () {
    for (final previous in _PreviousPair.values) {
      test('removes and finalizes ${previous.name}', () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, previous);

        await _store(fileSystem).remove(names);

        expect(fileSystem.containsPath(_timerPath(names)), isFalse);
        expect(fileSystem.containsPath(_servicePath(names)), isFalse);
      });
    }

    test('rolls back timer after service deletion failure', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _names();
      _seedPrevious(fileSystem, names, _PreviousPair.complete);
      final cause = StateError('TOP_SECRET_PRIMARY');
      fileSystem.failNext('delete:${_servicePath(names)}', error: cause);

      final error = await _expectStoreFailure(
        () => _store(fileSystem).remove(names),
        LinuxSystemdUserUnitStoreOperation.remove,
      );

      expect(error.cause, same(cause));
      expect(error.rollbackFailures, isEmpty);
      expect(error.toString(), isNot(contains('TOP_SECRET_PRIMARY')));
      _expectPrevious(fileSystem, names, _PreviousPair.complete);
    });

    test(
      'keeps primary delete failure and attaches rollback failure',
      () async {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final names = _names();
        _seedPrevious(fileSystem, names, _PreviousPair.complete);
        final primary = StateError('primary delete');
        final rollback = StateError('timer restore');
        fileSystem
          ..failNext('delete:${_servicePath(names)}', error: primary)
          ..failNext('write:${_timerPath(names)}', error: rollback);

        final error = await _expectStoreFailure(
          () => _store(fileSystem).remove(names),
          LinuxSystemdUserUnitStoreOperation.remove,
        );

        expect(error.cause, same(primary));
        expect(
          error.rollbackFailures.map((failure) => failure.step),
          orderedEquals(<String>['restore-timer-snapshot-write']),
        );
        expect(error.rollbackFailures.single.error, same(rollback));
      },
    );
  });
}

const String _directory = '/config/systemd/user';
const String _oldService = '[Service]\nOldService=true\n';
const String _oldTimer = '[Timer]\nOldTimer=true\n';
const int _oldServiceMode = 0x180;
const int _oldTimerMode = 0x1A0;

enum _PreviousPair { missing, serviceOnly, timerOnly, complete }

LinuxSystemdUnitNames _names() {
  return LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
}

LinuxSystemdUserUnitStore _store(FakeLinuxSystemdFileSystem fileSystem) {
  return LinuxSystemdUserUnitStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      _MapEnvironment(const <String, String>{'XDG_CONFIG_HOME': '/config'}),
    ),
    fileSystem: fileSystem,
    transactionIdFactory: () => 'unused-remove-id',
  );
}

void _seedPrevious(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdUnitNames names,
  _PreviousPair previous,
) {
  if (previous == _PreviousPair.serviceOnly ||
      previous == _PreviousPair.complete) {
    fileSystem.seedFile(
      _servicePath(names),
      utf8.encode(_oldService),
      mode: _oldServiceMode,
    );
  }

  if (previous == _PreviousPair.timerOnly ||
      previous == _PreviousPair.complete) {
    fileSystem.seedFile(
      _timerPath(names),
      utf8.encode(_oldTimer),
      mode: _oldTimerMode,
    );
  }
}

void _expectPrevious(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdUnitNames names,
  _PreviousPair previous,
) {
  final expectsService =
      previous == _PreviousPair.serviceOnly ||
      previous == _PreviousPair.complete;
  final expectsTimer =
      previous == _PreviousPair.timerOnly || previous == _PreviousPair.complete;

  expect(fileSystem.containsPath(_servicePath(names)), expectsService);
  expect(fileSystem.containsPath(_timerPath(names)), expectsTimer);

  if (expectsService) {
    expect(fileSystem.textOf(_servicePath(names)), _oldService);
    expect(fileSystem.modeOf(_servicePath(names)), _oldServiceMode);
  }

  if (expectsTimer) {
    expect(fileSystem.textOf(_timerPath(names)), _oldTimer);
    expect(fileSystem.modeOf(_timerPath(names)), _oldTimerMode);
  }
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

String _servicePath(LinuxSystemdUnitNames names) {
  return '$_directory/${names.serviceFileName}';
}

String _timerPath(LinuxSystemdUnitNames names) {
  return '$_directory/${names.timerFileName}';
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
