import 'dart:convert';

import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('LinuxSystemdUserUnitStore rollback', () {
    test('prepare failures preserve every previous pair state', () async {
      final units = _buildRenderedUnits();
      final failurePoints = <String>[
        'write:${_serviceTemp(units)}',
        'write:${_timerTemp(units)}',
        'chmod:${_serviceTemp(units)}:420',
        'chmod:${_timerTemp(units)}:420',
      ];

      for (final previousState in _PreviousPairState.values) {
        for (final failurePoint in failurePoints) {
          final fileSystem = FakeLinuxSystemdFileSystem();
          _seedPreviousState(fileSystem, units, previousState);
          final original = StateError('failure at $failurePoint');
          fileSystem.failNext(failurePoint, error: original);

          final exception = await _expectInstallFailure(
            _buildStore(fileSystem),
            units,
          );

          expect(exception.cause, same(original));
          expect(exception.rollbackFailures, isEmpty);
          _expectPreviousState(fileSystem, units, previousState);
          _expectNoTransactionArtifacts(fileSystem);
        }
      }
    });

    test('every commit failure restores a complete previous pair', () async {
      final units = _buildRenderedUnits();
      final failurePoints = <String>[
        'rename:${_serviceFinal(units)}->${_serviceBackup(units)}',
        'rename:${_timerFinal(units)}->${_timerBackup(units)}',
        'rename:${_serviceTemp(units)}->${_serviceFinal(units)}',
        'rename:${_timerTemp(units)}->${_timerFinal(units)}',
        'chmod:${_serviceFinal(units)}:420',
        'chmod:${_timerFinal(units)}:420',
        'delete:${_serviceBackup(units)}',
        'delete:${_timerBackup(units)}',
      ];

      for (final failurePoint in failurePoints) {
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedPreviousState(fileSystem, units, _PreviousPairState.complete);
        final original = StateError('failure at $failurePoint');
        fileSystem.failNext(failurePoint, error: original);

        final exception = await _expectInstallFailure(
          _buildStore(fileSystem),
          units,
        );

        expect(exception.cause, same(original));
        expect(exception.rollbackFailures, isEmpty);
        _expectPreviousState(fileSystem, units, _PreviousPairState.complete);
        _expectNoTransactionArtifacts(fileSystem);
      }
    });

    test(
      'commit failure restores missing and partial previous pairs',
      () async {
        final units = _buildRenderedUnits();

        for (final previousState in _PreviousPairState.values) {
          final fileSystem = FakeLinuxSystemdFileSystem();
          _seedPreviousState(fileSystem, units, previousState);
          final original = StateError('final timer chmod failed');
          fileSystem.failNext(
            'chmod:${_timerFinal(units)}:420',
            error: original,
          );

          final exception = await _expectInstallFailure(
            _buildStore(fileSystem),
            units,
          );

          expect(exception.cause, same(original));
          expect(exception.rollbackFailures, isEmpty);
          _expectPreviousState(fileSystem, units, previousState);
          _expectNoTransactionArtifacts(fileSystem);
        }
      },
    );

    test(
      'second backup cleanup failure reconstructs the deleted first backup',
      () async {
        final units = _buildRenderedUnits();
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedPreviousState(fileSystem, units, _PreviousPairState.complete);
        final original = StateError('timer backup cleanup failed');
        fileSystem.failNext('delete:${_timerBackup(units)}', error: original);

        final exception = await _expectInstallFailure(
          _buildStore(fileSystem),
          units,
        );

        expect(exception.cause, same(original));
        expect(exception.rollbackFailures, isEmpty);
        _expectPreviousState(fileSystem, units, _PreviousPairState.complete);
        expect(
          fileSystem.operations,
          contains('write:${_serviceFinal(units)}'),
        );
        expect(
          fileSystem.operations,
          contains('chmod:${_serviceFinal(units)}:384'),
        );
        expect(
          fileSystem.operations,
          contains('rename:${_timerBackup(units)}->${_timerFinal(units)}'),
        );
        _expectNoTransactionArtifacts(fileSystem);
      },
    );

    test('rollback failure never replaces the original cause', () async {
      final units = _buildRenderedUnits();
      final fileSystem = FakeLinuxSystemdFileSystem();
      _seedPreviousState(fileSystem, units, _PreviousPairState.complete);
      final original = StateError('timer install failed');
      final rollbackError = StateError('service backup restore failed');
      fileSystem
        ..failNext(
          'rename:${_timerTemp(units)}->${_timerFinal(units)}',
          error: original,
        )
        ..failNext(
          'rename:${_serviceBackup(units)}->${_serviceFinal(units)}',
          error: rollbackError,
        );

      final exception = await _expectInstallFailure(
        _buildStore(fileSystem),
        units,
      );

      expect(exception.cause, same(original));
      expect(exception.rollbackFailures, hasLength(1));
      expect(exception.rollbackFailures.single.step, 'restore-service-backup');
      expect(exception.rollbackFailures.single.error, same(rollbackError));
      _expectPreviousState(fileSystem, units, _PreviousPairState.complete);
      _expectNoTransactionArtifacts(fileSystem);
    });

    test(
      'multiple rollback failures are retained in execution order',
      () async {
        final units = _buildRenderedUnits();
        final fileSystem = FakeLinuxSystemdFileSystem();
        _seedPreviousState(fileSystem, units, _PreviousPairState.complete);
        final original = StateError('timer install failed');
        final deleteError = StateError('new service delete failed');
        final restoreError = StateError('service backup restore failed');
        final cleanupError = StateError('timer temp cleanup failed');
        fileSystem
          ..failNext(
            'rename:${_timerTemp(units)}->${_timerFinal(units)}',
            error: original,
          )
          ..failNext('delete:${_serviceFinal(units)}', error: deleteError)
          ..failNext(
            'rename:${_serviceBackup(units)}->${_serviceFinal(units)}',
            error: restoreError,
          )
          ..failNext('delete:${_timerTemp(units)}', error: cleanupError);

        final exception = await _expectInstallFailure(
          _buildStore(fileSystem),
          units,
        );

        expect(exception.cause, same(original));
        expect(
          exception.rollbackFailures.map((failure) => failure.step),
          <String>[
            'delete-new-service',
            'restore-service-backup',
            'delete-timer-temp',
          ],
        );
        expect(
          exception.rollbackFailures.map((failure) => failure.error),
          <Object>[deleteError, restoreError, cleanupError],
        );
        _expectPreviousState(fileSystem, units, _PreviousPairState.complete);
        expect(fileSystem.containsPath(_timerTemp(units)), isTrue);
      },
    );

    test('rollback never changes unrelated files', () async {
      final units = _buildRenderedUnits();
      final unrelated = '$_unitDirectory/unrelated.service';
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile(unrelated, <int>[9, 8, 7], mode: 0x181);
      _seedPreviousState(fileSystem, units, _PreviousPairState.complete);
      fileSystem.failNext(
        'chmod:${_timerFinal(units)}:420',
        error: StateError('timer chmod failed'),
      );

      final exception = await _expectInstallFailure(
        _buildStore(fileSystem),
        units,
      );

      expect(exception.rollbackFailures, isEmpty);
      expect(fileSystem.bytesOf(unrelated), <int>[9, 8, 7]);
      expect(fileSystem.modeOf(unrelated), 0x181);
      _expectPreviousState(fileSystem, units, _PreviousPairState.complete);
      _expectNoTransactionArtifacts(fileSystem);
    });
  });
}

const _unitDirectory = '/xdg/systemd/user';
const _transactionId = 'tx-rollback';
const _oldServiceContents = 'old service\n';
const _oldTimerContents = 'old timer\n';
const _oldServiceMode = 0x180;
const _oldTimerMode = 0x1A0;

enum _PreviousPairState { missing, complete, serviceOnly, timerOnly }

LinuxSystemdRenderedUnits _buildRenderedUnits() {
  final names = LinuxSystemdUnitNames.forScheduleKey('rollback-schedule');

  return LinuxSystemdRenderedUnits(
    serviceFileName: names.serviceFileName,
    timerFileName: names.timerFileName,
    serviceContents: 'new service\n',
    timerContents: 'new timer\n',
  );
}

LinuxSystemdUserUnitStore _buildStore(FakeLinuxSystemdFileSystem fileSystem) {
  return LinuxSystemdUserUnitStore(
    pathResolver: LinuxSystemdUserUnitPathResolver(
      const _MapLinuxSystemdEnvironment(<String, String>{
        'XDG_CONFIG_HOME': '/xdg',
      }),
    ),
    fileSystem: fileSystem,
    transactionIdFactory: () => _transactionId,
  );
}

Future<LinuxSystemdUserUnitStoreException> _expectInstallFailure(
  LinuxSystemdUserUnitStore store,
  LinuxSystemdRenderedUnits units,
) async {
  try {
    await store.install(units);
    fail('Expected installation to fail.');
  } on LinuxSystemdUserUnitStoreException catch (error) {
    return error;
  }
}

void _seedPreviousState(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdRenderedUnits units,
  _PreviousPairState state,
) {
  if (state == _PreviousPairState.complete ||
      state == _PreviousPairState.serviceOnly) {
    fileSystem.seedFile(
      _serviceFinal(units),
      utf8.encode(_oldServiceContents),
      mode: _oldServiceMode,
    );
  }

  if (state == _PreviousPairState.complete ||
      state == _PreviousPairState.timerOnly) {
    fileSystem.seedFile(
      _timerFinal(units),
      utf8.encode(_oldTimerContents),
      mode: _oldTimerMode,
    );
  }
}

void _expectPreviousState(
  FakeLinuxSystemdFileSystem fileSystem,
  LinuxSystemdRenderedUnits units,
  _PreviousPairState state,
) {
  final expectedService =
      state == _PreviousPairState.complete ||
      state == _PreviousPairState.serviceOnly;
  final expectedTimer =
      state == _PreviousPairState.complete ||
      state == _PreviousPairState.timerOnly;

  expect(fileSystem.containsPath(_serviceFinal(units)), expectedService);
  expect(fileSystem.containsPath(_timerFinal(units)), expectedTimer);

  if (expectedService) {
    expect(fileSystem.textOf(_serviceFinal(units)), _oldServiceContents);
    expect(fileSystem.modeOf(_serviceFinal(units)), _oldServiceMode);
  }

  if (expectedTimer) {
    expect(fileSystem.textOf(_timerFinal(units)), _oldTimerContents);
    expect(fileSystem.modeOf(_timerFinal(units)), _oldTimerMode);
  }
}

void _expectNoTransactionArtifacts(FakeLinuxSystemdFileSystem fileSystem) {
  expect(
    fileSystem.pathsWhere(
      (path) =>
          path.contains('.$_transactionId.tmp') ||
          path.contains('.$_transactionId.bak'),
    ),
    isEmpty,
  );
}

String _serviceFinal(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/${units.serviceFileName}';
}

String _timerFinal(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/${units.timerFileName}';
}

String _serviceTemp(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/.${units.serviceFileName}.'
      '$_transactionId.tmp';
}

String _timerTemp(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/.${units.timerFileName}.'
      '$_transactionId.tmp';
}

String _serviceBackup(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/.${units.serviceFileName}.'
      '$_transactionId.bak';
}

String _timerBackup(LinuxSystemdRenderedUnits units) {
  return '$_unitDirectory/.${units.timerFileName}.'
      '$_transactionId.bak';
}

final class _MapLinuxSystemdEnvironment implements LinuxSystemdEnvironment {
  const _MapLinuxSystemdEnvironment(this._values);

  final Map<String, String> _values;

  @override
  String? value(String name) => _values[name];
}
