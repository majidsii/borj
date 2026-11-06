import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_file_store.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  const directory = '/config/systemd/user';
  const registryPath = '$directory/borj-notification-registry.json';
  const quarantinePath = '$directory/.borj-notification-registry.txn-1.corrupt';

  group('LinuxSystemdScheduleRegistryFileStore quarantine', () {
    late FakeLinuxSystemdFileSystem fileSystem;
    late LinuxSystemdScheduleRegistryStore store;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
      store = _store(fileSystem);
    });

    test('missing registry quarantine is idempotent', () async {
      await store.quarantineCorruptRegistry();
      await store.quarantineCorruptRegistry();

      expect(fileSystem.operations, <String>[
        'typeOf:$registryPath',
        'typeOf:$registryPath',
      ]);
      expect(fileSystem.containsPath(quarantinePath), isFalse);
    });

    test(
      'renames corrupt registry byte-for-byte without decoding it',
      () async {
        final corruptBytes = utf8.encode(
          '{"schemaVersion":1,"TOP_SECRET":"not valid",}',
        );
        fileSystem.seedFile(registryPath, corruptBytes, mode: 0x1A4);

        await store.quarantineCorruptRegistry();

        expect(fileSystem.containsPath(registryPath), isFalse);
        expect(fileSystem.bytesOf(quarantinePath), corruptBytes);
        expect(fileSystem.modeOf(quarantinePath), 0x1A4);
        expect(fileSystem.operations, <String>[
          'typeOf:$registryPath',
          'typeOf:$quarantinePath',
          'rename:$registryPath->$quarantinePath',
        ]);
        expect(
          fileSystem.operations.where(
            (operation) =>
                operation.startsWith('read:') ||
                operation.startsWith('fileLength:') ||
                operation.startsWith('readMode:') ||
                operation.startsWith('delete:') ||
                operation.startsWith('chmod:') ||
                operation.startsWith('write:'),
          ),
          isEmpty,
        );
      },
    );

    for (final unsafe in <({String label, LinuxSystemdEntryType type})>[
      (label: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
      (label: 'directory', type: LinuxSystemdEntryType.directory),
      (label: 'special entry', type: LinuxSystemdEntryType.other),
    ]) {
      test('rejects registry ${unsafe.label}', () async {
        _seedUnsafe(fileSystem, registryPath, unsafe.type);

        final error = await _expectFailure(
          store.quarantineCorruptRegistry,
          operation: LinuxSystemdScheduleRegistryOperation.quarantine,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );

        expect(error.cause, isNull);
        expect(fileSystem.operations, <String>['typeOf:$registryPath']);
      });
    }

    for (final unsafe in <({String label, LinuxSystemdEntryType type})>[
      (label: 'regular file', type: LinuxSystemdEntryType.regularFile),
      (label: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
      (label: 'directory', type: LinuxSystemdEntryType.directory),
      (label: 'special entry', type: LinuxSystemdEntryType.other),
    ]) {
      test('never overwrites existing quarantine ${unsafe.label}', () async {
        final original = utf8.encode('corrupt registry');
        fileSystem.seedFile(registryPath, original, mode: 0x180);
        _seedUnsafe(fileSystem, quarantinePath, unsafe.type);

        await _expectFailure(
          store.quarantineCorruptRegistry,
          operation: LinuxSystemdScheduleRegistryOperation.quarantine,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: quarantinePath,
        );

        expect(fileSystem.bytesOf(registryPath), original);
        expect(fileSystem.operations, <String>[
          'typeOf:$registryPath',
          'typeOf:$quarantinePath',
        ]);
      });
    }

    for (final transactionId in <String>[
      '',
      ' ',
      'txn.1',
      'txn/1',
      '../txn-1',
      'txn 1',
      'a' * 65,
      'تراکنش',
    ]) {
      test(
        'rejects unsafe quarantine transaction id: $transactionId',
        () async {
          fileSystem.seedFile(
            registryPath,
            utf8.encode('corrupt'),
            mode: 0x180,
          );
          final invalidStore = _store(
            fileSystem,
            transactionIdFactory: () => transactionId,
          );

          await _expectFailure(
            invalidStore.quarantineCorruptRegistry,
            operation: LinuxSystemdScheduleRegistryOperation.quarantine,
            failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
            path: registryPath,
            field: 'transactionId',
          );

          expect(fileSystem.operations, <String>['typeOf:$registryPath']);
        },
      );
    }

    test('maps rename failure to quarantineFailed', () async {
      final cause = StateError('TOP_SECRET_RENAME_FAILURE');
      fileSystem.seedFile(registryPath, utf8.encode('corrupt'), mode: 0x180);
      fileSystem.failNext(
        'rename:$registryPath->$quarantinePath',
        error: cause,
      );

      final error = await _expectFailure(
        store.quarantineCorruptRegistry,
        operation: LinuxSystemdScheduleRegistryOperation.quarantine,
        failure: LinuxSystemdScheduleRegistryFailure.quarantineFailed,
        path: registryPath,
      );

      expect(error.cause, same(cause));
      expect(fileSystem.containsPath(registryPath), isTrue);
      expect(fileSystem.containsPath(quarantinePath), isFalse);
      expect(error.toString(), isNot(contains('TOP_SECRET_RENAME_FAILURE')));
    });

    test('maps registry inspection failure to quarantineFailed', () async {
      final cause = StateError('inspection failed');
      fileSystem.failNext('typeOf:$registryPath', error: cause);

      final error = await _expectFailure(
        store.quarantineCorruptRegistry,
        operation: LinuxSystemdScheduleRegistryOperation.quarantine,
        failure: LinuxSystemdScheduleRegistryFailure.quarantineFailed,
        path: registryPath,
      );

      expect(error.cause, same(cause));
    });

    test(
      'maps quarantine destination inspection failure and preserves path',
      () async {
        fileSystem.seedFile(registryPath, utf8.encode('corrupt'), mode: 0x180);
        final cause = StateError('destination inspection failed');
        fileSystem.failNext('typeOf:$quarantinePath', error: cause);

        final error = await _expectFailure(
          store.quarantineCorruptRegistry,
          operation: LinuxSystemdScheduleRegistryOperation.quarantine,
          failure: LinuxSystemdScheduleRegistryFailure.quarantineFailed,
          path: quarantinePath,
        );

        expect(error.cause, same(cause));
        expect(fileSystem.containsPath(registryPath), isTrue);
      },
    );

    test('maps transaction-id factory failure safely', () async {
      fileSystem.seedFile(registryPath, utf8.encode('corrupt'), mode: 0x180);
      final cause = StateError('TOP_SECRET_TRANSACTION_FAILURE');
      final invalidStore = _store(
        fileSystem,
        transactionIdFactory: () => throw cause,
      );

      final error = await _expectFailure(
        invalidStore.quarantineCorruptRegistry,
        operation: LinuxSystemdScheduleRegistryOperation.quarantine,
        failure: LinuxSystemdScheduleRegistryFailure.quarantineFailed,
        path: registryPath,
        field: 'transactionId',
      );

      expect(error.cause, same(cause));
      expect(
        error.toString(),
        isNot(contains('TOP_SECRET_TRANSACTION_FAILURE')),
      );
    });

    test('maps resolver failure before touching the filesystem', () async {
      final invalidStore = LinuxSystemdScheduleRegistryFileStore(
        pathResolver: LinuxSystemdUserUnitPathResolver(
          _MapEnvironment(const <String, String>{}),
        ),
        fileSystem: fileSystem,
        codec: const LinuxSystemdScheduleRegistryCodec(),
        transactionIdFactory: () => 'txn-1',
      );

      final error = await _expectFailure(
        invalidStore.quarantineCorruptRegistry,
        operation: LinuxSystemdScheduleRegistryOperation.quarantine,
        failure: LinuxSystemdScheduleRegistryFailure.quarantineFailed,
      );

      expect(error.path, isNull);
      expect(error.cause, isA<LinuxSystemdConfigurationException>());
      expect(fileSystem.operations, isEmpty);
    });
  });

  group('LinuxSystemdScheduleRegistryFileStore discovery', () {
    late FakeLinuxSystemdFileSystem fileSystem;
    late LinuxSystemdScheduleRegistryStore store;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
      fileSystem.seedDirectory(directory);
      store = _store(fileSystem);
    });

    test('discovers exact complete and partial app-owned pairs only', () async {
      _seedFile(
        fileSystem,
        '$directory/borj-notification-aaaaaaaaaaaaaaaa.service',
      );
      _seedFile(
        fileSystem,
        '$directory/borj-notification-aaaaaaaaaaaaaaaa.timer',
      );
      _seedFile(
        fileSystem,
        '$directory/borj-notification-bbbbbbbbbbbbbbbb.service',
      );
      _seedFile(fileSystem, '$directory/unrelated.service');
      _seedFile(
        fileSystem,
        '$directory/borj-notification-CCCCCCCCCCCCCCCC.timer',
      );
      _seedFile(fileSystem, '$directory/borj-notification-cccc.timer');
      _seedFile(fileSystem, '$directory/.borj-notification-registry.txn.tmp');
      fileSystem.seedDirectory('$directory/nested');
      _seedFile(
        fileSystem,
        '$directory/nested/'
        'borj-notification-dddddddddddddddd.timer',
      );

      final discovery = await store.discoverAppUnitPairs();

      expect(
        discovery.completePairs.map((pair) => pair.baseName),
        orderedEquals(<String>['borj-notification-aaaaaaaaaaaaaaaa']),
      );
      expect(
        discovery.partialPairs,
        orderedEquals(<LinuxSystemdPartialUnitPair>[
          LinuxSystemdPartialUnitPair(
            baseName: 'borj-notification-bbbbbbbbbbbbbbbb',
            hasService: true,
            hasTimer: false,
          ),
        ]),
      );
      expect(fileSystem.operations, <String>[
        'listNames:$directory',
        'typeOf:$directory/'
            'borj-notification-aaaaaaaaaaaaaaaa.service',
        'typeOf:$directory/'
            'borj-notification-aaaaaaaaaaaaaaaa.timer',
        'typeOf:$directory/'
            'borj-notification-bbbbbbbbbbbbbbbb.service',
      ]);
    });

    test('returns empty immutable discovery for a missing directory', () async {
      final missingFileSystem = FakeLinuxSystemdFileSystem();
      final discovery = await _store(missingFileSystem).discoverAppUnitPairs();

      expect(discovery.completePairs, isEmpty);
      expect(discovery.partialPairs, isEmpty);
      expect(missingFileSystem.operations, <String>['listNames:$directory']);
    });

    test('sorts complete and partial pairs by base name', () async {
      for (final baseName in <String>[
        'borj-notification-cccccccccccccccc',
        'borj-notification-aaaaaaaaaaaaaaaa',
      ]) {
        _seedFile(fileSystem, '$directory/$baseName.service');
        _seedFile(fileSystem, '$directory/$baseName.timer');
      }
      _seedFile(
        fileSystem,
        '$directory/borj-notification-dddddddddddddddd.timer',
      );
      _seedFile(
        fileSystem,
        '$directory/borj-notification-bbbbbbbbbbbbbbbb.service',
      );

      final discovery = await store.discoverAppUnitPairs();

      expect(
        discovery.completePairs.map((pair) => pair.baseName),
        orderedEquals(<String>[
          'borj-notification-aaaaaaaaaaaaaaaa',
          'borj-notification-cccccccccccccccc',
        ]),
      );
      expect(
        discovery.partialPairs.map((pair) => pair.baseName),
        orderedEquals(<String>[
          'borj-notification-bbbbbbbbbbbbbbbb',
          'borj-notification-dddddddddddddddd',
        ]),
      );
    });

    test('inspects each exact matched name exactly once', () async {
      _seedFile(
        fileSystem,
        '$directory/borj-notification-aaaaaaaaaaaaaaaa.service',
      );
      _seedFile(
        fileSystem,
        '$directory/borj-notification-aaaaaaaaaaaaaaaa.timer',
      );
      _seedFile(
        fileSystem,
        '$directory/borj-notification-bbbbbbbbbbbbbbbb.timer',
      );

      await store.discoverAppUnitPairs();

      expect(
        fileSystem.operations.where(
          (operation) => operation == 'listNames:$directory',
        ),
        hasLength(1),
      );
      for (final name in <String>[
        'borj-notification-aaaaaaaaaaaaaaaa.service',
        'borj-notification-aaaaaaaaaaaaaaaa.timer',
        'borj-notification-bbbbbbbbbbbbbbbb.timer',
      ]) {
        expect(
          fileSystem.operations.where(
            (operation) => operation == 'typeOf:$directory/$name',
          ),
          hasLength(1),
        );
      }
    });

    for (final unsafe in <({String label, LinuxSystemdEntryType type})>[
      (
        label: 'missing entry after listing',
        type: LinuxSystemdEntryType.missing,
      ),
      (label: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
      (label: 'directory', type: LinuxSystemdEntryType.directory),
      (label: 'special entry', type: LinuxSystemdEntryType.other),
    ]) {
      test('rejects exact matched ${unsafe.label}', () async {
        const name = 'borj-notification-aaaaaaaaaaaaaaaa.timer';
        final path = '$directory/$name';

        if (unsafe.type == LinuxSystemdEntryType.missing) {
          fileSystem.seedFile(path, const <int>[1], mode: 0x1A4);
          final injectedStore = _store(
            _MissingAfterListingFileSystem(
              delegate: fileSystem,
              missingPath: path,
            ),
          );

          final error = await _expectFailure(
            injectedStore.discoverAppUnitPairs,
            operation: LinuxSystemdScheduleRegistryOperation.discover,
            failure: LinuxSystemdScheduleRegistryFailure.unsafeAppUnitPath,
            path: path,
          );
          expect(error.cause, isNull);
        } else {
          _seedUnsafe(fileSystem, path, unsafe.type);

          final error = await _expectFailure(
            store.discoverAppUnitPairs,
            operation: LinuxSystemdScheduleRegistryOperation.discover,
            failure: LinuxSystemdScheduleRegistryFailure.unsafeAppUnitPath,
            path: path,
          );
          expect(error.cause, isNull);
        }
      });
    }

    test('ignores unrelated symlink without inspecting it', () async {
      const unrelatedPath = '$directory/unrelated.service';
      fileSystem.seedSymlink(unrelatedPath, '/outside/secret');
      _seedFile(
        fileSystem,
        '$directory/borj-notification-aaaaaaaaaaaaaaaa.timer',
      );

      final discovery = await store.discoverAppUnitPairs();

      expect(discovery.completePairs, isEmpty);
      expect(discovery.partialPairs, hasLength(1));
      expect(fileSystem.operations, isNot(contains('typeOf:$unrelatedPath')));
    });

    test('maps listing failure to discoveryFailed', () async {
      final cause = StateError('TOP_SECRET_LIST_FAILURE');
      fileSystem.failNext('listNames:$directory', error: cause);

      final error = await _expectFailure(
        store.discoverAppUnitPairs,
        operation: LinuxSystemdScheduleRegistryOperation.discover,
        failure: LinuxSystemdScheduleRegistryFailure.discoveryFailed,
        path: directory,
      );

      expect(error.cause, same(cause));
      expect(error.toString(), isNot(contains('TOP_SECRET_LIST_FAILURE')));
    });

    test(
      'maps exact child inspection failure and preserves child path',
      () async {
        const name = 'borj-notification-aaaaaaaaaaaaaaaa.service';
        const path = '$directory/$name';
        _seedFile(fileSystem, path);
        final cause = StateError('TOP_SECRET_CHILD_FAILURE');
        fileSystem.failNext('typeOf:$path', error: cause);

        final error = await _expectFailure(
          store.discoverAppUnitPairs,
          operation: LinuxSystemdScheduleRegistryOperation.discover,
          failure: LinuxSystemdScheduleRegistryFailure.discoveryFailed,
          path: path,
        );

        expect(error.cause, same(cause));
        expect(error.toString(), isNot(contains('TOP_SECRET_CHILD_FAILURE')));
      },
    );

    test('maps resolver failure before listing', () async {
      final invalidStore = LinuxSystemdScheduleRegistryFileStore(
        pathResolver: LinuxSystemdUserUnitPathResolver(
          _MapEnvironment(const <String, String>{}),
        ),
        fileSystem: fileSystem,
        codec: const LinuxSystemdScheduleRegistryCodec(),
        transactionIdFactory: () => 'txn-1',
      );

      final error = await _expectFailure(
        invalidStore.discoverAppUnitPairs,
        operation: LinuxSystemdScheduleRegistryOperation.discover,
        failure: LinuxSystemdScheduleRegistryFailure.discoveryFailed,
      );

      expect(error.path, isNull);
      expect(error.cause, isA<LinuxSystemdConfigurationException>());
      expect(fileSystem.operations, isEmpty);
    });
  });
}

LinuxSystemdScheduleRegistryFileStore _store(
  LinuxSystemdFileSystem fileSystem, {
  LinuxSystemdRegistryTransactionIdFactory? transactionIdFactory,
}) {
  return LinuxSystemdScheduleRegistryFileStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      _MapEnvironment(const <String, String>{'XDG_CONFIG_HOME': '/config'}),
    ),
    fileSystem: fileSystem,
    codec: const LinuxSystemdScheduleRegistryCodec(),
    transactionIdFactory: transactionIdFactory ?? () => 'txn-1',
  );
}

void _seedFile(FakeLinuxSystemdFileSystem fileSystem, String path) {
  fileSystem.seedFile(path, const <int>[1], mode: 0x1A4);
}

void _seedUnsafe(
  FakeLinuxSystemdFileSystem fileSystem,
  String path,
  LinuxSystemdEntryType type,
) {
  switch (type) {
    case LinuxSystemdEntryType.regularFile:
      fileSystem.seedFile(path, const <int>[1], mode: 0x180);
    case LinuxSystemdEntryType.directory:
      fileSystem.seedDirectory(path);
    case LinuxSystemdEntryType.symbolicLink:
      fileSystem.seedSymlink(path, '/unsafe/target');
    case LinuxSystemdEntryType.other:
      fileSystem.seedOther(path);
    case LinuxSystemdEntryType.missing:
      fail('Missing must not be seeded.');
  }
}

Future<LinuxSystemdScheduleRegistryException> _expectFailure(
  Future<dynamic> Function() action, {
  required LinuxSystemdScheduleRegistryOperation operation,
  required LinuxSystemdScheduleRegistryFailure failure,
  String? path,
  String? field,
}) async {
  try {
    await action();
    fail('Expected LinuxSystemdScheduleRegistryException.');
  } on LinuxSystemdScheduleRegistryException catch (error) {
    expect(error.operation, operation);
    expect(error.failure, failure);

    if (path != null) {
      expect(error.path, path);
    }
    if (field != null) {
      expect(error.field, field);
    }

    return error;
  }
}

final class _MapEnvironment implements LinuxSystemdEnvironment {
  const _MapEnvironment(this.values);

  final Map<String, String> values;

  @override
  String? value(String name) => values[name];
}

final class _MissingAfterListingFileSystem implements LinuxSystemdFileSystem {
  const _MissingAfterListingFileSystem({
    required this.delegate,
    required this.missingPath,
  });

  final FakeLinuxSystemdFileSystem delegate;
  final String missingPath;

  @override
  Future<void> chmod(String path, int mode) {
    return delegate.chmod(path, mode);
  }

  @override
  Future<void> createDirectory(String path) {
    return delegate.createDirectory(path);
  }

  @override
  Future<void> deleteFile(String path) {
    return delegate.deleteFile(path);
  }

  @override
  Future<int> fileLength(String path) {
    return delegate.fileLength(path);
  }

  @override
  Future<List<String>> listNames(String directoryPath) {
    return delegate.listNames(directoryPath);
  }

  @override
  Future<List<int>> readBytes(String path) {
    return delegate.readBytes(path);
  }

  @override
  Future<int> readMode(String path) {
    return delegate.readMode(path);
  }

  @override
  Future<void> rename(String sourcePath, String destinationPath) {
    return delegate.rename(sourcePath, destinationPath);
  }

  @override
  Future<LinuxSystemdEntryType> typeOf(String path) async {
    if (path == missingPath) {
      delegate.operations.add('typeOf:$path');
      return LinuxSystemdEntryType.missing;
    }

    return delegate.typeOf(path);
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) {
    return delegate.writeBytes(path, bytes);
  }
}
