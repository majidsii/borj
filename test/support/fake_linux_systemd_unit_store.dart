import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:borj/core/notifications/linux_systemd_unit_transaction.dart';

final class FakeLinuxSystemdUnitStore implements LinuxSystemdUnitStore {
  FakeLinuxSystemdUnitStore({List<String>? operations})
    : operations = operations ?? <String>[];

  final List<String> operations;
  final List<LinuxSystemdRenderedUnits> installUnits =
      <LinuxSystemdRenderedUnits>[];
  final List<LinuxSystemdUnitNames> removeNames = <LinuxSystemdUnitNames>[];

  @override
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  ) async {
    operations.add('unitStore.beginInstall');
    installUnits.add(units);

    final suffix = '.service';
    final baseName = units.serviceFileName.substring(
      0,
      units.serviceFileName.length - suffix.length,
    );

    return _FakeInstallTransaction(
      names: LinuxSystemdUnitNames.parseBaseName(baseName),
      operations: operations,
    );
  }

  @override
  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  ) async {
    operations.add('unitStore.beginRemove');
    removeNames.add(names);

    return _FakeRemoveTransaction(names: names, operations: operations);
  }

  @override
  Future<void> install(LinuxSystemdRenderedUnits units) async {
    final transaction = await beginInstall(units);
    await transaction.apply();
    await transaction.finalize();
  }

  @override
  Future<void> remove(LinuxSystemdUnitNames names) async {
    final transaction = await beginRemove(names);
    await transaction.apply();
    await transaction.finalize();
  }
}

final class _FakeInstallTransaction
    implements LinuxSystemdUnitInstallTransaction {
  _FakeInstallTransaction({required this.names, required this.operations});

  @override
  final LinuxSystemdUnitNames names;

  final List<String> operations;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    if (state == LinuxSystemdUnitTransactionState.applied) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.pending) {
      throw StateError('Invalid fake install apply state.');
    }

    operations.add('install.apply');
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.applied) {
      throw StateError('Invalid fake install finalize state.');
    }

    operations.add('install.finalize');
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    if (state == LinuxSystemdUnitTransactionState.rolledBack) {
      return;
    }
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      throw StateError('Cannot roll back finalized fake install.');
    }

    operations.add('install.rollback');
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}

final class _FakeRemoveTransaction
    implements LinuxSystemdUnitRemoveTransaction {
  _FakeRemoveTransaction({required this.names, required this.operations});

  @override
  final LinuxSystemdUnitNames names;

  final List<String> operations;

  @override
  LinuxSystemdUnitTransactionState state =
      LinuxSystemdUnitTransactionState.pending;

  @override
  Future<void> apply() async {
    if (state == LinuxSystemdUnitTransactionState.applied) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.pending) {
      throw StateError('Invalid fake remove apply state.');
    }

    operations.add('remove.apply');
    state = LinuxSystemdUnitTransactionState.applied;
  }

  @override
  Future<void> finalize() async {
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      return;
    }
    if (state != LinuxSystemdUnitTransactionState.applied) {
      throw StateError('Invalid fake remove finalize state.');
    }

    operations.add('remove.finalize');
    state = LinuxSystemdUnitTransactionState.finalized;
  }

  @override
  Future<void> rollback() async {
    if (state == LinuxSystemdUnitTransactionState.rolledBack) {
      return;
    }
    if (state == LinuxSystemdUnitTransactionState.finalized) {
      throw StateError('Cannot roll back finalized fake remove.');
    }

    operations.add('remove.rollback');
    state = LinuxSystemdUnitTransactionState.rolledBack;
  }
}
