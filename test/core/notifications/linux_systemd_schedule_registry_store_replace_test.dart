import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_file_store.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_store.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

const directory = '/config/systemd/user';
const registryPath = '$directory/borj-notification-registry.json';
const tempPath = '$directory/.borj-notification-registry.txn-1.tmp';
const backupPath = '$directory/.borj-notification-registry.txn-1.bak';
const codec = LinuxSystemdScheduleRegistryCodec();

void main() {
  group('LinuxSystemdScheduleRegistryFileStore.replace success', () {
    late FakeLinuxSystemdFileSystem fileSystem;
    late LinuxSystemdScheduleRegistryFileStore store;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
      store = _store(fileSystem);
    });

    test('installs generation one when the registry is missing', () async {
      final next = _registry(generation: 1);

      await store.replace(next);

      expect(fileSystem.operations, <String>[
        'typeOf:$registryPath',
        'createDirectory:$directory',
        'typeOf:$registryPath',
        'typeOf:$tempPath',
        'typeOf:$backupPath',
        'write:$tempPath',
        'chmod:$tempPath:384',
        'rename:$tempPath->$registryPath',
        'chmod:$registryPath:384',
      ]);
      expect(fileSystem.bytesOf(registryPath), codec.encodeBytes(next));
      expect(fileSystem.modeOf(registryPath), 0x180);
      expect(fileSystem.containsPath(tempPath), isFalse);
      expect(fileSystem.containsPath(backupPath), isFalse);
      expect(await store.load(), next);
    });

    test('atomically replaces an existing generation', () async {
      final previous = _registry(generation: 7);
      final next = _registry(generation: 8, fingerprintCharacter: 'b');
      _seedRegistry(fileSystem, previous);

      await store.replace(next);

      expect(fileSystem.operations, <String>[
        'typeOf:$registryPath',
        'fileLength:$registryPath',
        'read:$registryPath',
        'readMode:$registryPath',
        'createDirectory:$directory',
        'typeOf:$registryPath',
        'typeOf:$tempPath',
        'typeOf:$backupPath',
        'write:$tempPath',
        'chmod:$tempPath:384',
        'rename:$registryPath->$backupPath',
        'rename:$tempPath->$registryPath',
        'chmod:$registryPath:384',
        'delete:$backupPath',
      ]);
      expect(fileSystem.bytesOf(registryPath), codec.encodeBytes(next));
      expect(fileSystem.modeOf(registryPath), 0x180);
      expect(fileSystem.containsPath(tempPath), isFalse);
      expect(fileSystem.containsPath(backupPath), isFalse);
    });

    test('preserves canonical entry ordering in the final bytes', () async {
      final next = LinuxSystemdScheduleRegistry(
        schemaVersion: 1,
        generation: 1,
        entries: <LinuxSystemdScheduleRegistryEntry>[
          _entry('z-reminder'),
          _entry('a-reminder'),
        ],
      );

      await store.replace(next);

      expect(
        utf8.decode(fileSystem.bytesOf(registryPath)),
        contains('"scheduleId":"a-reminder"'),
      );
      expect(
        utf8
            .decode(fileSystem.bytesOf(registryPath))
            .indexOf('"scheduleId":"a-reminder"'),
        lessThan(
          utf8
              .decode(fileSystem.bytesOf(registryPath))
              .indexOf('"scheduleId":"z-reminder"'),
        ),
      );
    });
  });

  group('LinuxSystemdScheduleRegistryFileStore.replace validation', () {
    late FakeLinuxSystemdFileSystem fileSystem;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
    });

    for (final transition in <({int current, int next})>[
      (current: 0, next: 0),
      (current: 0, next: 2),
      (current: 7, next: 7),
      (current: 7, next: 9),
      (current: 7, next: 1),
    ]) {
      test(
        'rejects generation ${transition.current} to ${transition.next}',
        () async {
          if (transition.current > 0) {
            _seedRegistry(
              fileSystem,
              _registry(generation: transition.current),
            );
          }

          final store = _store(fileSystem);
          final error = await _expectReplaceFailure(
            () => store.replace(_registry(generation: transition.next)),
            LinuxSystemdScheduleRegistryFailure.invalidGenerationTransition,
            path: registryPath,
            field: 'generation',
          );

          expect(error.cause, isNull);
          expect(
            fileSystem.operations.any(
              (operation) =>
                  operation.startsWith('createDirectory:') ||
                  operation.startsWith('write:') ||
                  operation.startsWith('rename:') ||
                  operation.startsWith('delete:') ||
                  operation.startsWith('chmod:'),
            ),
            isFalse,
          );
        },
      );
    }

    for (final transactionId in <String>[
      '',
      ' ',
      'txn.1',
      'txn/1',
      '../txn-1',
      'txn 1',
      List<String>.filled(65, 'a').join(),
      'تراکنش',
    ]) {
      test('rejects unsafe transaction id: $transactionId', () async {
        final store = _store(
          fileSystem,
          transactionIdFactory: () => transactionId,
        );

        await _expectReplaceFailure(
          () => store.replace(_registry(generation: 1)),
          LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
          field: 'transactionId',
        );

        expect(fileSystem.operations, <String>['typeOf:$registryPath']);
      });
    }

    test('wraps a transaction-id factory failure safely', () async {
      final cause = StateError('TOP_SECRET_TRANSACTION_FAILURE');
      final store = _store(fileSystem, transactionIdFactory: () => throw cause);

      final error = await _expectReplaceFailure(
        () => store.replace(_registry(generation: 1)),
        LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
        path: registryPath,
        field: 'transactionId',
      );

      expect(error.cause, same(cause));
      expect(
        error.toString(),
        isNot(contains('TOP_SECRET_TRANSACTION_FAILURE')),
      );
    });

    for (final unsafe in <({String name, LinuxSystemdEntryType type})>[
      (name: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
      (name: 'directory', type: LinuxSystemdEntryType.directory),
      (name: 'special entry', type: LinuxSystemdEntryType.other),
    ]) {
      test('rejects unsafe final ${unsafe.name}', () async {
        _seedUnsafe(fileSystem, registryPath, unsafe.type);

        await _expectReplaceFailure(
          () => _store(fileSystem).replace(_registry(generation: 1)),
          LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );

        expect(fileSystem.operations, <String>['typeOf:$registryPath']);
      });
    }

    for (final target in <({String label, String path})>[
      (label: 'temp', path: tempPath),
      (label: 'backup', path: backupPath),
    ]) {
      for (final unsafe in <({String name, LinuxSystemdEntryType type})>[
        (name: 'regular file', type: LinuxSystemdEntryType.regularFile),
        (name: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
        (name: 'directory', type: LinuxSystemdEntryType.directory),
        (name: 'special entry', type: LinuxSystemdEntryType.other),
      ]) {
        test('rejects existing ${target.label} ${unsafe.name}', () async {
          _seedUnsafe(fileSystem, target.path, unsafe.type);

          await _expectReplaceFailure(
            () => _store(fileSystem).replace(_registry(generation: 1)),
            LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
            path: target.path,
          );

          expect(fileSystem.containsPath(registryPath), isFalse);
          expect(fileSystem.containsPath(target.path), isTrue);
        });
      }
    }
  });

  group('LinuxSystemdScheduleRegistryFileStore.replace rollback', () {
    late FakeLinuxSystemdFileSystem fileSystem;
    late LinuxSystemdScheduleRegistry previous;
    late List<int> previousBytes;
    late LinuxSystemdScheduleRegistryFileStore store;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
      previous = _registry(generation: 7);
      previousBytes = <int>[...codec.encodeBytes(previous), 0x20, 0x20];
      fileSystem.seedFile(registryPath, previousBytes, mode: 0x180);
      store = _store(fileSystem);
    });

    for (final step in <String>[
      'createDirectory:$directory',
      'typeOf:$registryPath',
      'typeOf:$tempPath',
      'typeOf:$backupPath',
      'write:$tempPath',
      'chmod:$tempPath:384',
      'rename:$registryPath->$backupPath',
      'rename:$tempPath->$registryPath',
      'chmod:$registryPath:384',
      'delete:$backupPath',
    ]) {
      test('restores exact previous bytes after failure at $step', () async {
        final cause = StateError('PRIMARY_FAILURE_AT_$step');

        fileSystem.failNext(step, error: cause);

        final error = await _expectReplaceFailure(
          () => store.replace(
            _registry(generation: 8, fingerprintCharacter: 'b'),
          ),
          LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
          path: registryPath,
        );

        expect(error.cause, same(cause));
        expect(error.rollbackFailures, isEmpty);
        expect(fileSystem.bytesOf(registryPath), previousBytes);
        expect(fileSystem.modeOf(registryPath), 0x180);
        expect(fileSystem.containsPath(tempPath), isFalse);
        expect(fileSystem.containsPath(backupPath), isFalse);
        expect(error.toString(), isNot(contains('PRIMARY_FAILURE_AT_')));
      });
    }

    test(
      'removes a newly-created final file when no previous file existed',
      () async {
        final emptyFileSystem = FakeLinuxSystemdFileSystem();
        final emptyStore = _store(emptyFileSystem);
        final cause = StateError('FINAL_CHMOD_FAILURE');
        emptyFileSystem.failNext('chmod:$registryPath:384', error: cause);

        final error = await _expectReplaceFailure(
          () => emptyStore.replace(_registry(generation: 1)),
          LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
          path: registryPath,
        );

        expect(error.cause, same(cause));
        expect(emptyFileSystem.containsPath(registryPath), isFalse);
        expect(emptyFileSystem.containsPath(tempPath), isFalse);
        expect(emptyFileSystem.containsPath(backupPath), isFalse);
      },
    );

    test(
      'keeps the primary error and attaches backup-restore failure',
      () async {
        final primary = StateError('TOP_SECRET_PRIMARY');
        final rollback = StateError('TOP_SECRET_ROLLBACK');
        fileSystem.failNext('chmod:$registryPath:384', error: primary);
        fileSystem.failNext(
          'rename:$backupPath->$registryPath',
          error: rollback,
        );

        final error = await _expectReplaceFailure(
          () => store.replace(
            _registry(generation: 8, fingerprintCharacter: 'b'),
          ),
          LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
          path: registryPath,
        );

        expect(error.cause, same(primary));
        expect(error.rollbackFailures, hasLength(1));
        expect(error.rollbackFailures.single.step, 'restore-registry-backup');
        expect(error.rollbackFailures.single.error, same(rollback));
        expect(fileSystem.bytesOf(registryPath), previousBytes);
        expect(fileSystem.modeOf(registryPath), 0x180);
        expect(fileSystem.containsPath(tempPath), isFalse);
        expect(fileSystem.containsPath(backupPath), isFalse);
        expect(error.toString(), contains('operation=replace'));
        expect(error.toString(), contains('failure=atomicReplacementFailed'));
        expect(error.toString(), contains('rollbackFailures=1'));
        expect(error.toString(), isNot(contains('TOP_SECRET_PRIMARY')));
        expect(error.toString(), isNot(contains('TOP_SECRET_ROLLBACK')));
      },
    );

    test(
      'records fallback rewrite failure after backup restore fails',
      () async {
        final primary = StateError('primary');
        final restore = StateError('restore');
        final rewrite = StateError('rewrite');
        fileSystem.failNext('chmod:$registryPath:384', error: primary);
        fileSystem.failNext(
          'rename:$backupPath->$registryPath',
          error: restore,
        );
        fileSystem.failNext('write:$registryPath', error: rewrite);

        final error = await _expectReplaceFailure(
          () => store.replace(
            _registry(generation: 8, fingerprintCharacter: 'b'),
          ),
          LinuxSystemdScheduleRegistryFailure.atomicReplacementFailed,
          path: registryPath,
        );

        expect(error.cause, same(primary));
        expect(
          error.rollbackFailures.map((failure) => failure.step),
          orderedEquals(<String>[
            'restore-registry-backup',
            'rewrite-previous-registry',
          ]),
        );
      },
    );
  });
}

LinuxSystemdScheduleRegistryFileStore _store(
  FakeLinuxSystemdFileSystem fileSystem, {
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

void _seedRegistry(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdScheduleRegistry registry,
) {
  fileSystem.seedFile(registryPath, codec.encodeBytes(registry), mode: 0x180);
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
      fail('Missing is not an unsafe seeded entry.');
  }
}

LinuxSystemdScheduleRegistry _registry({
  required int generation,
  String fingerprintCharacter = 'a',
}) {
  return LinuxSystemdScheduleRegistry(
    schemaVersion: 1,
    generation: generation,
    entries: <LinuxSystemdScheduleRegistryEntry>[
      _entry('task-42-reminder', fingerprintCharacter: fingerprintCharacter),
    ],
  );
}

LinuxSystemdScheduleRegistryEntry _entry(
  String scheduleId, {
  String fingerprintCharacter = 'a',
}) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);

  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
    requestFingerprint: List<String>.filled(64, fingerprintCharacter).join(),
  );
}

Future<LinuxSystemdScheduleRegistryException> _expectReplaceFailure(
  Future<void> Function() action,
  LinuxSystemdScheduleRegistryFailure failure, {
  String? path,
  String? field,
}) async {
  try {
    await action();
    fail('Expected LinuxSystemdScheduleRegistryException.');
  } on LinuxSystemdScheduleRegistryException catch (error) {
    expect(error.operation, LinuxSystemdScheduleRegistryOperation.replace);
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
