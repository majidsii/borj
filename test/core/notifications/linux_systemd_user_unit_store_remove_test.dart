import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_file_system.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('LinuxSystemdUserUnitStore remove', () {
    test('removes timer before service', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      fileSystem
        ..seedFile(_servicePath(names), utf8.encode('service'))
        ..seedFile(_timerPath(names), utf8.encode('timer'));

      await _buildStore(fileSystem).remove(names);

      expect(fileSystem.containsPath(_timerPath(names)), isFalse);
      expect(fileSystem.containsPath(_servicePath(names)), isFalse);

      final timerDeleteIndex = fileSystem.operations.indexOf(
        'delete:${_timerPath(names)}',
      );
      final serviceDeleteIndex = fileSystem.operations.indexOf(
        'delete:${_servicePath(names)}',
      );

      expect(timerDeleteIndex, isNonNegative);
      expect(serviceDeleteIndex, greaterThan(timerDeleteIndex));
    });

    test('succeeds when both files are missing', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();

      await expectLater(_buildStore(fileSystem).remove(names), completes);

      expect(
        fileSystem.operations.any(
          (operation) => operation.startsWith('createDirectory:'),
        ),
        isFalse,
      );
      expect(
        fileSystem.operations.any(
          (operation) => operation.startsWith('delete:'),
        ),
        isFalse,
      );
    });

    test('removes an existing service-only pair', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      fileSystem.seedFile(_servicePath(names), utf8.encode('service'));

      await _buildStore(fileSystem).remove(names);

      expect(fileSystem.containsPath(_servicePath(names)), isFalse);
      expect(fileSystem.containsPath(_timerPath(names)), isFalse);
    });

    test('removes an existing timer-only pair', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      fileSystem.seedFile(_timerPath(names), utf8.encode('timer'));

      await _buildStore(fileSystem).remove(names);

      expect(fileSystem.containsPath(_timerPath(names)), isFalse);
      expect(fileSystem.containsPath(_servicePath(names)), isFalse);
    });

    test('rejects a timer symlink before deleting service', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      fileSystem
        ..seedFile(_servicePath(names), utf8.encode('service'))
        ..seedFile('$_unitDirectory/target.timer', utf8.encode('target'))
        ..seedSymlink(_timerPath(names), '$_unitDirectory/target.timer');

      final exception = await _expectRemoveFailure(
        _buildStore(fileSystem),
        names,
      );

      expect(exception.operation, LinuxSystemdUserUnitStoreOperation.remove);
      expect(exception.cause, isA<LinuxSystemdUnsafeEntryException>());
      expect(fileSystem.containsPath(_servicePath(names)), isTrue);
      expect(
        fileSystem.operations.any(
          (operation) => operation.startsWith('delete:'),
        ),
        isFalse,
      );
    });

    test('rejects a service symlink before deleting timer', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      fileSystem
        ..seedFile(_timerPath(names), utf8.encode('timer'))
        ..seedFile('$_unitDirectory/target.service', utf8.encode('target'))
        ..seedSymlink(_servicePath(names), '$_unitDirectory/target.service');

      final exception = await _expectRemoveFailure(
        _buildStore(fileSystem),
        names,
      );

      expect(exception.cause, isA<LinuxSystemdUnsafeEntryException>());
      expect(fileSystem.containsPath(_timerPath(names)), isTrue);
      expect(
        fileSystem.operations.any(
          (operation) => operation.startsWith('delete:'),
        ),
        isFalse,
      );
    });

    test('rejects directory and special destination entries', () async {
      final names = _buildNames();

      for (final entryType in <LinuxSystemdEntryType>[
        LinuxSystemdEntryType.directory,
        LinuxSystemdEntryType.other,
      ]) {
        final fileSystem = FakeLinuxSystemdFileSystem();

        if (entryType == LinuxSystemdEntryType.directory) {
          fileSystem.seedDirectory(_servicePath(names));
        } else {
          fileSystem.seedOther(_servicePath(names));
        }

        final exception = await _expectRemoveFailure(
          _buildStore(fileSystem),
          names,
        );

        expect(
          exception.cause,
          isA<LinuxSystemdUnsafeEntryException>().having(
            (error) => error.entryType,
            'entryType',
            entryType,
          ),
        );
      }
    });

    test('preserves the directory and unrelated entries', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      const unrelatedPath = '$_unitDirectory/unrelated.service';
      fileSystem
        ..seedDirectory(_unitDirectory)
        ..seedFile(_servicePath(names), utf8.encode('service'))
        ..seedFile(_timerPath(names), utf8.encode('timer'))
        ..seedFile(unrelatedPath, <int>[9, 8, 7], mode: 0x181);

      await _buildStore(fileSystem).remove(names);

      expect(
        await fileSystem.typeOf(_unitDirectory),
        LinuxSystemdEntryType.directory,
      );
      expect(fileSystem.bytesOf(unrelatedPath), <int>[9, 8, 7]);
      expect(fileSystem.modeOf(unrelatedPath), 0x181);
    });

    test('timer deletion failure prevents service deletion', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      final original = StateError('timer delete failed');
      fileSystem
        ..seedFile(_servicePath(names), utf8.encode('service'))
        ..seedFile(_timerPath(names), utf8.encode('timer'))
        ..failNext('delete:${_timerPath(names)}', error: original);

      final exception = await _expectRemoveFailure(
        _buildStore(fileSystem),
        names,
      );

      expect(exception.cause, same(original));
      expect(exception.rollbackFailures, isEmpty);
      expect(fileSystem.containsPath(_timerPath(names)), isTrue);
      expect(fileSystem.containsPath(_servicePath(names)), isTrue);
      expect(
        fileSystem.operations,
        isNot(contains('delete:${_servicePath(names)}')),
      );
    });

    test('service deletion failure restores the removed timer', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final names = _buildNames();
      final original = StateError('service delete failed');
      fileSystem
        ..seedFile(_servicePath(names), utf8.encode('service'))
        ..seedFile(_timerPath(names), utf8.encode('timer'))
        ..failNext('delete:${_servicePath(names)}', error: original);

      final exception = await _expectRemoveFailure(
        _buildStore(fileSystem),
        names,
      );

      expect(exception.operation, LinuxSystemdUserUnitStoreOperation.remove);
      expect(exception.cause, same(original));
      expect(exception.serviceFileName, names.serviceFileName);
      expect(exception.timerFileName, names.timerFileName);
      expect(exception.rollbackFailures, isEmpty);
      expect(fileSystem.containsPath(_timerPath(names)), isTrue);
      expect(fileSystem.bytesOf(_timerPath(names)), utf8.encode('timer'));
      expect(fileSystem.containsPath(_servicePath(names)), isTrue);
    });
  });
}

const _unitDirectory = '/xdg/systemd/user';

LinuxSystemdUnitNames _buildNames() {
  return LinuxSystemdUnitNames.forScheduleKey('remove-schedule');
}

LinuxSystemdUserUnitStore _buildStore(FakeLinuxSystemdFileSystem fileSystem) {
  return LinuxSystemdUserUnitStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      const _MapLinuxSystemdEnvironment(<String, String>{
        'XDG_CONFIG_HOME': '/xdg',
      }),
    ),
    fileSystem: fileSystem,
    transactionIdFactory: () => 'unused-remove-id',
  );
}

Future<LinuxSystemdUserUnitStoreException> _expectRemoveFailure(
  LinuxSystemdUserUnitStore store,
  LinuxSystemdUnitNames names,
) async {
  try {
    await store.remove(names);
    fail('Expected removal to fail.');
  } on LinuxSystemdUserUnitStoreException catch (error) {
    return error;
  }
}

String _servicePath(LinuxSystemdUnitNames names) {
  return '$_unitDirectory/${names.serviceFileName}';
}

String _timerPath(LinuxSystemdUnitNames names) {
  return '$_unitDirectory/${names.timerFileName}';
}

final class _MapLinuxSystemdEnvironment implements LinuxSystemdEnvironment {
  const _MapLinuxSystemdEnvironment(this._values);

  final Map<String, String> _values;

  @override
  String? value(String name) => _values[name];
}
