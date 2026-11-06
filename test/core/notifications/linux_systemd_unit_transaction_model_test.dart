import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdUnitTransactionState', () {
    test('exposes the exact retained transaction lifecycle', () {
      expect(
        LinuxSystemdUnitTransactionState.values.map((value) => value.name),
        orderedEquals(<String>[
          'pending',
          'applied',
          'finalized',
          'rolledBack',
        ]),
      );
    });
  });

  group('LinuxSystemdUserUnitStoreOperation', () {
    test('retains legacy wrapper operations and adds transaction phases', () {
      expect(
        LinuxSystemdUserUnitStoreOperation.values.map((value) => value.name),
        orderedEquals(<String>[
          'install',
          'remove',
          'beginInstall',
          'beginRemove',
          'applyInstall',
          'finalizeInstall',
          'rollbackInstall',
          'applyRemove',
          'finalizeRemove',
          'rollbackRemove',
        ]),
      );
    });
  });

  group('LinuxSystemdUserUnitTransactionFailure', () {
    test('exposes only safe lifecycle failure categories', () {
      expect(
        LinuxSystemdUserUnitTransactionFailure.values.map(
          (value) => value.name,
        ),
        orderedEquals(<String>['invalidState', 'filesystemFailure']),
      );
    });
  });

  group('LinuxSystemdUnitInstallTransaction contract', () {
    test('exposes stable names and starts pending', () {
      final names = _names();
      final transaction = _RecordingInstallTransaction(names);

      expect(transaction.names, names);
      expect(transaction.state, LinuxSystemdUnitTransactionState.pending);
    });

    test('apply is idempotent after successful application', () async {
      final transaction = _RecordingInstallTransaction(_names());

      await transaction.apply();
      await transaction.apply();

      expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
      expect(transaction.applyCalls, 1);
    });

    test('finalize is idempotent after successful finalization', () async {
      final transaction = _RecordingInstallTransaction(_names());

      await transaction.apply();
      await transaction.finalize();
      await transaction.finalize();

      expect(transaction.state, LinuxSystemdUnitTransactionState.finalized);
      expect(transaction.finalizeCalls, 1);
    });

    test('rollback is idempotent after successful rollback', () async {
      final transaction = _RecordingInstallTransaction(_names());

      await transaction.apply();
      await transaction.rollback();
      await transaction.rollback();

      expect(transaction.state, LinuxSystemdUnitTransactionState.rolledBack);
      expect(transaction.rollbackCalls, 1);
    });
  });

  group('LinuxSystemdUnitRemoveTransaction contract', () {
    test('exposes stable names and starts pending', () {
      final names = _names();
      final transaction = _RecordingRemoveTransaction(names);

      expect(transaction.names, names);
      expect(transaction.state, LinuxSystemdUnitTransactionState.pending);
    });

    test(
      'apply, finalize, and rollback expose the same lifecycle API',
      () async {
        final applied = _RecordingRemoveTransaction(_names());
        await applied.apply();
        await applied.apply();

        expect(applied.applyCalls, 1);
        expect(applied.state, LinuxSystemdUnitTransactionState.applied);

        await applied.finalize();
        await applied.finalize();

        expect(applied.finalizeCalls, 1);
        expect(applied.state, LinuxSystemdUnitTransactionState.finalized);

        final rolledBack = _RecordingRemoveTransaction(_names());
        await rolledBack.apply();
        await rolledBack.rollback();
        await rolledBack.rollback();

        expect(rolledBack.rollbackCalls, 1);
        expect(rolledBack.state, LinuxSystemdUnitTransactionState.rolledBack);
      },
    );
  });

  group('LinuxSystemdUnitStore contract', () {
    test('begins install and remove transactions with stable names', () async {
      final names = _names();
      final units = _units(names);
      final store = _RecordingUnitStore();

      final install = await store.beginInstall(units);
      final remove = await store.beginRemove(names);

      expect(install.names, names);
      expect(remove.names, names);
      expect(store.beginInstallCalls, 1);
      expect(store.beginRemoveCalls, 1);
    });

    test('keeps install and remove convenience wrappers', () async {
      final names = _names();
      final units = _units(names);
      final store = _RecordingUnitStore();

      await store.install(units);
      await store.remove(names);

      expect(store.installCalls, 1);
      expect(store.removeCalls, 1);
    });
  });

  group('LinuxSystemdUserUnitStoreException transaction metadata', () {
    test('preserves safe operation, failure, names, cause, and stack', () {
      final cause = StateError('TOP_SECRET_CAUSE');
      final stackTrace = StackTrace.current;
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.rollbackInstall,
        transactionFailure:
            LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: _names().serviceFileName,
        timerFileName: _names().timerFileName,
        cause: cause,
        causeStackTrace: stackTrace,
      );

      expect(
        error.operation,
        LinuxSystemdUserUnitStoreOperation.rollbackInstall,
      );
      expect(
        error.transactionFailure,
        LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
      );
      expect(error.cause, same(cause));
      expect(error.causeStackTrace, same(stackTrace));
      expect(error.rollbackFailures, isEmpty);
    });

    test('copies rollback failures into an immutable list', () {
      final failures = <LinuxSystemdRollbackFailure>[
        LinuxSystemdRollbackFailure(
          step: 'restore-service',
          error: StateError('TOP_SECRET_ROLLBACK'),
          stackTrace: StackTrace.current,
        ),
      ];
      final names = _names();
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.rollbackInstall,
        transactionFailure:
            LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: StateError('TOP_SECRET_CAUSE'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: failures,
      );

      failures.clear();

      expect(error.rollbackFailures, hasLength(1));
      expect(
        () => error.rollbackFailures.add(
          LinuxSystemdRollbackFailure(
            step: 'unexpected',
            error: StateError('unexpected'),
            stackTrace: StackTrace.current,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('toString includes safe context but never nested error text', () {
      final names = _names();
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.rollbackInstall,
        transactionFailure:
            LinuxSystemdUserUnitTransactionFailure.filesystemFailure,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: StateError('TOP_SECRET_CAUSE'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: <LinuxSystemdRollbackFailure>[
          LinuxSystemdRollbackFailure(
            step: 'restore-service',
            error: StateError('TOP_SECRET_ROLLBACK'),
            stackTrace: StackTrace.current,
          ),
        ],
      );

      final text = error.toString();

      expect(text, contains('rollbackInstall'));
      expect(text, contains('filesystemFailure'));
      expect(text, contains(names.serviceFileName));
      expect(text, contains(names.timerFileName));
      expect(text, contains('rollbackFailures: 1'));
      expect(text, isNot(contains('TOP_SECRET_CAUSE')));
      expect(text, isNot(contains('TOP_SECRET_ROLLBACK')));
      expect(text, isNot(contains('cause:')));
    });

    test('legacy wrapper exceptions may omit transaction failure', () {
      final names = _names();
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: names.serviceFileName,
        timerFileName: names.timerFileName,
        cause: StateError('install failed'),
        causeStackTrace: StackTrace.current,
      );

      expect(error.transactionFailure, isNull);
      expect(error.toString(), contains('transactionFailure: none'));
    });
  });
}

LinuxSystemdUnitNames _names() {
  return LinuxSystemdUnitNames.forScheduleKey('task-42-reminder');
}

LinuxSystemdRenderedUnits _units(LinuxSystemdUnitNames names) {
  return LinuxSystemdRenderedUnits(
    serviceFileName: names.serviceFileName,
    timerFileName: names.timerFileName,
    serviceContents: '[Service]\n',
    timerContents: '[Timer]\n',
  );
}

mixin _RecordingTransactionLifecycle {
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  int applyCalls = 0;
  int finalizeCalls = 0;
  int rollbackCalls = 0;

  Future<void> applyLifecycle() async {
    if (state == LinuxSystemdUnitTransactionState.applied) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.pending) {
      throw StateError('Cannot apply from ${state.name}.');
    }

    applyCalls += 1;
    state = LinuxSystemdUnitTransactionState.applied;
  }

  Future<void> finalizeLifecycle() async {
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.applied) {
      throw StateError('Cannot finalize from ${state.name}.');
    }

    finalizeCalls += 1;
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  Future<void> rollbackLifecycle() async {
    if (state == LinuxSystemdUnitTransactionState.rolledBack) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.pending &&
        state != LinuxSystemdUnitTransactionState.applied) {
      throw StateError('Cannot rollback from ${state.name}.');
    }

    rollbackCalls += 1;
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _RecordingInstallTransaction
    with _RecordingTransactionLifecycle
    implements LinuxSystemdUnitInstallTransaction {
  _RecordingInstallTransaction(this.names);

  @override
  final LinuxSystemdUnitNames names;

  @override
  Future<void> apply() => applyLifecycle();

  @override
  Future<void> finalize() => finalizeLifecycle();

  @override
  Future<void> rollback() => rollbackLifecycle();
}

final class _RecordingRemoveTransaction
    with _RecordingTransactionLifecycle
    implements LinuxSystemdUnitRemoveTransaction {
  _RecordingRemoveTransaction(this.names);

  @override
  final LinuxSystemdUnitNames names;

  @override
  Future<void> apply() => applyLifecycle();

  @override
  Future<void> finalize() => finalizeLifecycle();

  @override
  Future<void> rollback() => rollbackLifecycle();
}

final class _RecordingUnitStore implements LinuxSystemdUnitStore {
  int beginInstallCalls = 0;
  int beginRemoveCalls = 0;
  int installCalls = 0;
  int removeCalls = 0;

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    beginInstallCalls += 1;
    return _RecordingInstallTransaction(
      LinuxSystemdUnitNames.parseBaseName(
        units.serviceFileName.substring(
          0,
          units.serviceFileName.length - '.service'.length,
        ),
      ),
    );
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    beginRemoveCalls += 1;
    return _RecordingRemoveTransaction(names);
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) async {
    installCalls += 1;
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    removeCalls += 1;
  }
}
