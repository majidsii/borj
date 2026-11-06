import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('FakeLinuxSystemdFileSystem', () {
    test('writes and reads defensive byte copies', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final source = <int>[1, 2, 3];

      await fileSystem.writeBytes('/units/job.service', source);
      source.add(4);

      final firstRead = await fileSystem.readBytes('/units/job.service');
      firstRead.add(5);

      expect(await fileSystem.readBytes('/units/job.service'), <int>[1, 2, 3]);
    });

    test('seedFile copies bytes and stores the supplied mode', () {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final source = <int>[10, 20];

      fileSystem.seedFile('/units/job.service', source, mode: 0x180);
      source.add(30);

      expect(fileSystem.bytesOf('/units/job.service'), <int>[10, 20]);
      expect(fileSystem.modeOf('/units/job.service'), 0x180);
    });

    test('rename preserves bytes and mode exactly', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/job.tmp', <int>[7, 8, 9], mode: 0x1A4);

      await fileSystem.rename('/units/job.tmp', '/units/job.service');

      expect(fileSystem.containsPath('/units/job.tmp'), isFalse);
      expect(fileSystem.bytesOf('/units/job.service'), <int>[7, 8, 9]);
      expect(fileSystem.modeOf('/units/job.service'), 0x1A4);
    });

    test('typeOf identifies symlinks without following them', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/target.service', <int>[1])
        ..seedSymlink('/units/link.service', '/units/target.service');

      expect(
        await fileSystem.typeOf('/units/link.service'),
        LinuxSystemdEntryType.symbolicLink,
      );
      expect(
        fileSystem.linkTargetOf('/units/link.service'),
        '/units/target.service',
      );
    });

    test('createDirectory records a directory entry', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await fileSystem.createDirectory('/units');

      expect(
        await fileSystem.typeOf('/units'),
        LinuxSystemdEntryType.directory,
      );
    });

    test('deleteFile is idempotent for a missing path', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await expectLater(
        fileSystem.deleteFile('/units/missing.service'),
        completes,
      );
    });

    test('deleteFile rejects a symlink and preserves its target', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/target.service', <int>[1, 2])
        ..seedSymlink('/units/link.service', '/units/target.service');

      await expectLater(
        fileSystem.deleteFile('/units/link.service'),
        throwsA(isA<LinuxSystemdUnsafeEntryException>()),
      );

      expect(fileSystem.containsPath('/units/link.service'), isTrue);
      expect(fileSystem.bytesOf('/units/target.service'), <int>[1, 2]);
    });

    test('an injected operation failure happens exactly once', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..failNext('write:/units/job.service', error: StateError('disk full'));

      await expectLater(
        fileSystem.writeBytes('/units/job.service', <int>[1]),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'disk full',
          ),
        ),
      );

      await fileSystem.writeBytes('/units/job.service', <int>[2]);

      expect(fileSystem.bytesOf('/units/job.service'), <int>[2]);
    });

    test('supports multiple queued failures for one operation', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..failNext('delete:/units/job.service', error: StateError('first'))
        ..failNext('delete:/units/job.service', error: StateError('second'))
        ..seedFile('/units/job.service', <int>[1]);

      await expectLater(
        fileSystem.deleteFile('/units/job.service'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'first',
          ),
        ),
      );
      await expectLater(
        fileSystem.deleteFile('/units/job.service'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'second',
          ),
        ),
      );
      await fileSystem.deleteFile('/units/job.service');

      expect(fileSystem.containsPath('/units/job.service'), isFalse);
    });

    test('records attempted operations in execution order', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await fileSystem.createDirectory('/units');
      await fileSystem.writeBytes('/units/job.tmp', <int>[1]);
      await fileSystem.chmod('/units/job.tmp', 0x1A4);
      await fileSystem.rename('/units/job.tmp', '/units/job.service');

      expect(fileSystem.operations, <String>[
        'createDirectory:/units',
        'write:/units/job.tmp',
        'chmod:/units/job.tmp:420',
        'rename:/units/job.tmp->/units/job.service',
      ]);
    });
  });

  group('LinuxSystemdUserUnitStoreException', () {
    test('preserves operation, file names, cause, and stack trace', () {
      final cause = StateError('install failed');
      final stackTrace = StackTrace.current;
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: cause,
        causeStackTrace: stackTrace,
      );

      expect(error.operation, LinuxSystemdUserUnitStoreOperation.install);
      expect(error.serviceFileName, 'job.service');
      expect(error.timerFileName, 'job.timer');
      expect(error.cause, same(cause));
      expect(error.causeStackTrace, same(stackTrace));
      expect(error.rollbackFailures, isEmpty);
    });

    test('copies rollback failures into an immutable list', () {
      final failures = <LinuxSystemdRollbackFailure>[
        LinuxSystemdRollbackFailure(
          step: 'restore-service',
          error: StateError('restore failed'),
          stackTrace: StackTrace.current,
        ),
      ];

      final exception = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: StateError('install failed'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: failures,
      );
      failures.clear();

      expect(exception.rollbackFailures, hasLength(1));
      expect(
        () => exception.rollbackFailures.add(
          LinuxSystemdRollbackFailure(
            step: 'unexpected',
            error: StateError('unexpected'),
            stackTrace: StackTrace.current,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('toString includes context but never unit contents', () {
      const secret = 'PRIVATE_UNIT_CONTENT';
      final exception = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.remove,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: StateError('remove failed'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: <LinuxSystemdRollbackFailure>[
          LinuxSystemdRollbackFailure(
            step: 'cleanup',
            error: StateError('cleanup failed'),
            stackTrace: StackTrace.current,
          ),
        ],
      );

      final text = exception.toString();

      expect(text, contains('remove'));
      expect(text, contains('job.service'));
      expect(text, contains('job.timer'));
      expect(text, contains('rollbackFailures: 1'));
      expect(text, isNot(contains(secret)));
      expect(utf8.encode(text), isNot(containsAllInOrder(utf8.encode(secret))));
    });
  });

  group('LinuxSystemdUserUnitStore successful installation', () {
    test('installs a new service and timer with mode 0644', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      final store = _buildStore(fileSystem);

      await store.install(units);

      expect(fileSystem.textOf(_servicePath(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerPath(units)), units.timerContents);
      expect(fileSystem.modeOf(_servicePath(units)), 0x1A4);
      expect(fileSystem.modeOf(_timerPath(units)), 0x1A4);
    });

    test('creates the systemd user directory', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final store = _buildStore(fileSystem);

      await store.install(_buildRenderedUnits());

      expect(
        await fileSystem.typeOf(_unitDirectory),
        LinuxSystemdEntryType.directory,
      );
    });

    test('prepares both temporary files before replacing finals', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      final store = _buildStore(fileSystem);

      await store.install(units);

      final serviceTemp = _transactionPath(
        units.serviceFileName,
        suffix: 'tmp',
      );
      final timerTemp = _transactionPath(units.timerFileName, suffix: 'tmp');
      final firstRenameIndex = fileSystem.operations.indexWhere(
        (operation) => operation.startsWith('rename:'),
      );

      expect(
        fileSystem.operations.indexOf('write:$serviceTemp'),
        lessThan(firstRenameIndex),
      );
      expect(
        fileSystem.operations.indexOf('write:$timerTemp'),
        lessThan(firstRenameIndex),
      );
      expect(
        fileSystem.operations.indexOf('chmod:$serviceTemp:420'),
        lessThan(firstRenameIndex),
      );
      expect(
        fileSystem.operations.indexOf('chmod:$timerTemp:420'),
        lessThan(firstRenameIndex),
      );
    });

    test('replaces an existing complete pair', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem
        ..seedFile(_servicePath(units), utf8.encode('old service'), mode: 0x180)
        ..seedFile(_timerPath(units), utf8.encode('old timer'), mode: 0x180);

      await _buildStore(fileSystem).install(units);

      expect(fileSystem.textOf(_servicePath(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerPath(units)), units.timerContents);
    });

    test('replaces an existing service-only pair', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem.seedFile(_servicePath(units), utf8.encode('old service'));

      await _buildStore(fileSystem).install(units);

      expect(fileSystem.textOf(_servicePath(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerPath(units)), units.timerContents);
    });

    test('replaces an existing timer-only pair', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem.seedFile(_timerPath(units), utf8.encode('old timer'));

      await _buildStore(fileSystem).install(units);

      expect(fileSystem.textOf(_servicePath(units)), units.serviceContents);
      expect(fileSystem.textOf(_timerPath(units)), units.timerContents);
    });

    test('leaves no transaction artifacts after success', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();

      await _buildStore(fileSystem).install(units);

      expect(
        fileSystem.pathsWhere(
          (path) => path.contains('.tx-1.tmp') || path.contains('.tx-1.bak'),
        ),
        isEmpty,
      );
    });

    test('preserves unrelated entries byte for byte', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('$_unitDirectory/unrelated.service', <int>[
          9,
          8,
          7,
        ], mode: 0x180);

      await _buildStore(fileSystem).install(_buildRenderedUnits());

      expect(fileSystem.bytesOf('$_unitDirectory/unrelated.service'), <int>[
        9,
        8,
        7,
      ]);
      expect(fileSystem.modeOf('$_unitDirectory/unrelated.service'), 0x180);
    });

    test('rejects absolute traversal and separator file names', () async {
      final invalidNames = <String>[
        '/tmp/job.service',
        '../job.service',
        r'folder\job.service',
        'folder/job.service',
        'job\u0000.service',
      ];

      for (final serviceName in invalidNames) {
        final fileSystem = FakeLinuxSystemdFileSystem();
        final units = LinuxSystemdRenderedUnits(
          serviceFileName: serviceName,
          timerFileName: 'borj-notification-0123456789abcdef.timer',
          serviceContents: 'service\n',
          timerContents: 'timer\n',
        );

        await expectLater(
          _buildStore(fileSystem).install(units),
          throwsA(isA<LinuxSystemdUserUnitStoreException>()),
          reason: 'unsafe name must fail: $serviceName',
        );
      }
    });

    test('rejects unexpected unit file suffixes', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = LinuxSystemdRenderedUnits(
        serviceFileName: 'borj-notification-0123456789abcdef.socket',
        timerFileName: 'borj-notification-0123456789abcdef.timer',
        serviceContents: 'service\n',
        timerContents: 'timer\n',
      );

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(isA<LinuxSystemdUserUnitStoreException>()),
      );
    });

    test('rejects service and timer names with different bases', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = LinuxSystemdRenderedUnits(
        serviceFileName: 'borj-notification-0123456789abcdef.service',
        timerFileName: 'borj-notification-fedcba9876543210.timer',
        serviceContents: 'service\n',
        timerContents: 'timer\n',
      );

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(isA<LinuxSystemdUserUnitStoreException>()),
      );
    });

    test('rejects an unsafe transaction id', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await expectLater(
        _buildStore(
          fileSystem,
          transactionId: '../unsafe',
        ).install(_buildRenderedUnits()),
        throwsA(isA<LinuxSystemdUserUnitStoreException>()),
      );
    });

    test('rejects a destination symbolic link', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem
        ..seedFile('$_unitDirectory/target.service', utf8.encode('target'))
        ..seedSymlink(_servicePath(units), '$_unitDirectory/target.service');

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(
          isA<LinuxSystemdUserUnitStoreException>().having(
            (error) => error.cause,
            'cause',
            isA<LinuxSystemdUnsafeEntryException>(),
          ),
        ),
      );

      expect(fileSystem.textOf('$_unitDirectory/target.service'), 'target');
    });

    test('rejects a destination directory', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem.seedDirectory(_timerPath(units));

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(
          isA<LinuxSystemdUserUnitStoreException>().having(
            (error) => error.cause,
            'cause',
            isA<LinuxSystemdUnsafeEntryException>(),
          ),
        ),
      );
    });

    test('rejects a destination special entry', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem.seedOther(_servicePath(units));

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(
          isA<LinuxSystemdUserUnitStoreException>().having(
            (error) => error.cause,
            'cause',
            isA<LinuxSystemdUnsafeEntryException>(),
          ),
        ),
      );
    });

    test('rejects pre-existing transaction artifacts', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final units = _buildRenderedUnits();
      fileSystem.seedFile(
        _transactionPath(units.serviceFileName, suffix: 'tmp'),
        <int>[1],
      );

      await expectLater(
        _buildStore(fileSystem).install(units),
        throwsA(
          isA<LinuxSystemdUserUnitStoreException>().having(
            (error) => error.cause,
            'cause',
            isA<LinuxSystemdUnsafeEntryException>(),
          ),
        ),
      );
    });
  });
}

const _unitDirectory = '/xdg/systemd/user';

LinuxSystemdRenderedUnits _buildRenderedUnits() {
  final names = LinuxSystemdUnitNames.forScheduleKey('schedule-1');

  return LinuxSystemdRenderedUnits(
    serviceFileName: names.serviceFileName,
    timerFileName: names.timerFileName,
    serviceContents: '[Service]\nType=oneshot\n',
    timerContents: '[Timer]\nPersistent=true\n',
  );
}

LinuxSystemdUserUnitStore _buildStore(
  FakeLinuxSystemdFileSystem fileSystem, {
  String transactionId = 'tx-1',
}) {
  return LinuxSystemdUserUnitStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      const _MapLinuxSystemdEnvironment(<String, String>{
        'XDG_CONFIG_HOME': '/xdg',
      }),
    ),
    fileSystem: fileSystem,
    transactionIdFactory: () => transactionId,
  );
}

String _servicePath(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/${units.serviceFileName}';
}

String _timerPath(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/${units.timerFileName}';
}

String _transactionPath(String fileName, {required String suffix}) {
  return '$_unitDirectory/.$fileName.tx-1.$suffix';
}

final class _MapLinuxSystemdEnvironment implements LinuxSystemdEnvironment {
  const _MapLinuxSystemdEnvironment(this._values);

  final Map<String, String> _values;

  @override
  String? value(String name) => _values[name];
}
