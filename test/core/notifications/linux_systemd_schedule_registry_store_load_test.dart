import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_codec.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_file_store.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  const directory = '/config/systemd/user';
  const registryPath = '$directory/borj-notification-registry.json';
  const codec = LinuxSystemdScheduleRegistryCodec();

  group('LinuxSystemdScheduleRegistryFileStore.load', () {
    late FakeLinuxSystemdFileSystem fileSystem;
    late LinuxSystemdScheduleRegistryFileStore store;

    setUp(() {
      fileSystem = FakeLinuxSystemdFileSystem();
      store = _store(fileSystem);
    });

    test(
      'uses the exact final registry filename and secure mode constants',
      () {
        expect(
          LinuxSystemdScheduleRegistryFileStore.registryFileName,
          'borj-notification-registry.json',
        );
        expect(LinuxSystemdScheduleRegistryFileStore.registryFileMode, 0x180);
      },
    );

    test('returns the exact empty registry when the file is missing', () async {
      final loaded = await store.load();

      expect(loaded, LinuxSystemdScheduleRegistry.empty());
      expect(fileSystem.operations, <String>['typeOf:$registryPath']);
    });

    test('loads a valid registry after length and mode checks', () async {
      final expected = _registry(generation: 7);
      final bytes = codec.encodeBytes(expected);
      fileSystem.seedFile(
        registryPath,
        bytes,
        mode: LinuxSystemdScheduleRegistryFileStore.registryFileMode,
      );

      final loaded = await store.load();

      expect(loaded, expected);
      expect(fileSystem.operations, <String>[
        'typeOf:$registryPath',
        'fileLength:$registryPath',
        'read:$registryPath',
        'readMode:$registryPath',
      ]);
    });

    test('returns immutable data decoded through the registry codec', () async {
      final expected = _registry(generation: 2);
      fileSystem.seedFile(
        registryPath,
        codec.encodeBytes(expected),
        mode: 0x180,
      );

      final loaded = await store.load();

      expect(
        () => loaded.entries.add(_entry('another-reminder')),
        throwsUnsupportedError,
      );
    });

    test('accepts a valid registry padded to exactly one MiB', () async {
      final canonical = codec.encodeBytes(LinuxSystemdScheduleRegistry.empty());
      final bytes = <int>[
        ...canonical,
        ...List<int>.filled(
          LinuxSystemdScheduleRegistryCodec.maximumFileBytes - canonical.length,
          0x20,
        ),
      ];
      fileSystem.seedFile(registryPath, bytes, mode: 0x180);

      expect(bytes.length, LinuxSystemdScheduleRegistryCodec.maximumFileBytes);
      expect(await store.load(), LinuxSystemdScheduleRegistry.empty());
    });

    test('rejects a file larger than one MiB before reading it', () async {
      fileSystem.seedFile(
        registryPath,
        List<int>.filled(
          LinuxSystemdScheduleRegistryCodec.maximumFileBytes + 1,
          0x20,
        ),
        mode: 0x180,
      );

      await _expectLoadFailure(
        store.load,
        LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
        path: registryPath,
      );

      expect(fileSystem.operations, <String>[
        'typeOf:$registryPath',
        'fileLength:$registryPath',
      ]);
    });

    for (final unsafe in <({String name, LinuxSystemdEntryType type})>[
      (name: 'symbolic link', type: LinuxSystemdEntryType.symbolicLink),
      (name: 'directory', type: LinuxSystemdEntryType.directory),
      (name: 'special entry', type: LinuxSystemdEntryType.other),
    ]) {
      test('rejects an unsafe ${unsafe.name} registry path', () async {
        switch (unsafe.type) {
          case LinuxSystemdEntryType.symbolicLink:
            fileSystem.seedSymlink(registryPath, '/secret/target');
          case LinuxSystemdEntryType.directory:
            fileSystem.seedDirectory(registryPath);
          case LinuxSystemdEntryType.other:
            fileSystem.seedOther(registryPath);
          case LinuxSystemdEntryType.missing:
          case LinuxSystemdEntryType.regularFile:
            fail('The table must contain only unsafe existing types.');
        }

        final error = await _expectLoadFailure(
          store.load,
          LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );

        expect(error.operation, LinuxSystemdScheduleRegistryOperation.load);
        expect(fileSystem.operations, <String>['typeOf:$registryPath']);
      });
    }

    for (final mode in <int>[0x1A4, 0x100, 0x1C0, 0x000]) {
      test(
        'rejects insecure registry mode 0x${mode.toRadixString(16)}',
        () async {
          fileSystem.seedFile(
            registryPath,
            codec.encodeBytes(LinuxSystemdScheduleRegistry.empty()),
            mode: mode,
          );

          await _expectLoadFailure(
            store.load,
            LinuxSystemdScheduleRegistryFailure.insecureRegistryMode,
            path: registryPath,
          );

          expect(fileSystem.operations, <String>[
            'typeOf:$registryPath',
            'fileLength:$registryPath',
            'read:$registryPath',
            'readMode:$registryPath',
          ]);
        },
      );
    }

    test('preserves malformed UTF-8 as a typed load failure', () async {
      fileSystem.seedFile(registryPath, const <int>[
        0x7b,
        0x22,
        0x78,
        0x22,
        0x3a,
        0xff,
        0x7d,
      ], mode: 0x180);

      final error = await _expectLoadFailure(
        store.load,
        LinuxSystemdScheduleRegistryFailure.malformedUtf8,
        path: registryPath,
      );

      expect(error.cause, isA<LinuxSystemdScheduleRegistryException>());
    });

    test('preserves malformed JSON as a typed load failure', () async {
      fileSystem.seedFile(
        registryPath,
        utf8.encode('{"schemaVersion":1,}'),
        mode: 0x180,
      );

      final error = await _expectLoadFailure(
        store.load,
        LinuxSystemdScheduleRegistryFailure.malformedJson,
        path: registryPath,
      );

      expect(error.cause, isA<LinuxSystemdScheduleRegistryException>());
    });

    test('preserves unsupported schema version and field metadata', () async {
      fileSystem.seedFile(
        registryPath,
        utf8.encode('{"schemaVersion":2,"generation":0,"entries":[]}'),
        mode: 0x180,
      );

      final error = await _expectLoadFailure(
        store.load,
        LinuxSystemdScheduleRegistryFailure.unsupportedSchemaVersion,
        path: registryPath,
        field: 'schemaVersion',
      );

      expect(error.cause, isA<LinuxSystemdScheduleRegistryException>());
    });

    test('preserves invalid generation and field metadata', () async {
      fileSystem.seedFile(
        registryPath,
        utf8.encode('{"schemaVersion":1,"generation":-1,"entries":[]}'),
        mode: 0x180,
      );

      await _expectLoadFailure(
        store.load,
        LinuxSystemdScheduleRegistryFailure.invalidGeneration,
        path: registryPath,
        field: 'generation',
      );
    });

    test(
      'does not mutate, quarantine, or create anything while loading',
      () async {
        fileSystem.seedFile(
          registryPath,
          codec.encodeBytes(_registry(generation: 1)),
          mode: 0x180,
        );

        await store.load();

        expect(
          fileSystem.operations.where(
            (operation) =>
                operation.startsWith('createDirectory:') ||
                operation.startsWith('write:') ||
                operation.startsWith('rename:') ||
                operation.startsWith('delete:') ||
                operation.startsWith('chmod:') ||
                operation.startsWith('listNames:'),
          ),
          isEmpty,
        );
      },
    );

    for (final step in <String>[
      'typeOf:$registryPath',
      'fileLength:$registryPath',
      'read:$registryPath',
      'readMode:$registryPath',
    ]) {
      test('wraps filesystem failure at $step', () async {
        fileSystem.seedFile(
          registryPath,
          codec.encodeBytes(LinuxSystemdScheduleRegistry.empty()),
          mode: 0x180,
        );
        final cause = StateError('TOP_SECRET_FILESYSTEM_FAILURE');
        fileSystem.failNext(step, error: cause);

        final error = await _expectLoadFailure(
          store.load,
          LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );

        expect(error.cause, same(cause));
        expect(error.causeStackTrace, isNotNull);
        expect(
          error.toString(),
          isNot(contains('TOP_SECRET_FILESYSTEM_FAILURE')),
        );
      });
    }

    test(
      'wraps path-resolution failure before touching the filesystem',
      () async {
        final invalidStore = LinuxSystemdScheduleRegistryFileStore(
          pathResolver: LinuxSystemdUserUnitPathResolver(
            _MapEnvironment(const <String, String>{}),
          ),
          fileSystem: fileSystem,
          codec: codec,
          transactionIdFactory: () => 'txn-1',
        );

        final error = await _expectLoadFailure(
          invalidStore.load,
          LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        );

        expect(error.path, isNull);
        expect(error.cause, isA<LinuxSystemdConfigurationException>());
        expect(fileSystem.operations, isEmpty);
      },
    );

    test(
      'safe diagnostics never include registry bytes or nested cause text',
      () async {
        const secret = 'TOP_SECRET_REGISTRY_CONTENT';
        fileSystem.seedFile(
          registryPath,
          utf8.encode(
            '{"schemaVersion":1,"generation":0,"entries":['
            '{"secret":"$secret"}]}',
          ),
          mode: 0x180,
        );

        final error = await _expectLoadFailure(
          store.load,
          LinuxSystemdScheduleRegistryFailure.malformedJson,
          path: registryPath,
        );

        expect(error.toString(), isNot(contains(secret)));
        expect(error.toString(), isNot(contains('secret')));
        expect(error.toString(), contains('operation=load'));
        expect(error.toString(), contains('failure=malformedJson'));
      },
    );
  });
}

LinuxSystemdScheduleRegistryFileStore _store(
  FakeLinuxSystemdFileSystem fileSystem,
) {
  return LinuxSystemdScheduleRegistryFileStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      _MapEnvironment(const <String, String>{'XDG_CONFIG_HOME': '/config'}),
    ),
    fileSystem: fileSystem,
    codec: const LinuxSystemdScheduleRegistryCodec(),
    transactionIdFactory: () => 'txn-1',
  );
}

LinuxSystemdScheduleRegistry _registry({required int generation}) {
  return LinuxSystemdScheduleRegistry(
    schemaVersion: 1,
    generation: generation,
    entries: <LinuxSystemdScheduleRegistryEntry>[_entry('task-42-reminder')],
  );
}

LinuxSystemdScheduleRegistryEntry _entry(String scheduleId) {
  final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);

  return LinuxSystemdScheduleRegistryEntry(
    scheduleId: scheduleId,
    owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
    timerName: LinuxSystemdTimerName.parse(names.timerFileName),
    serviceFileName: names.serviceFileName,
    scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
    requestFingerprint: 'a' * 64,
  );
}

Future<LinuxSystemdScheduleRegistryException> _expectLoadFailure(
  Future<LinuxSystemdScheduleRegistry> Function() action,
  LinuxSystemdScheduleRegistryFailure failure, {
  String? path,
  String? field,
}) async {
  try {
    await action();
    fail('Expected LinuxSystemdScheduleRegistryException.');
  } on LinuxSystemdScheduleRegistryException catch (error) {
    expect(error.operation, LinuxSystemdScheduleRegistryOperation.load);
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
