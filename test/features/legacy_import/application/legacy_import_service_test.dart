import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/features/finance/data/drift_finance_repository.dart';
import 'package:borj/features/legacy_import/application/legacy_import_service.dart';
import 'package:borj/features/legacy_import/data/drift_legacy_import_ledger.dart';
import 'package:borj/features/legacy_import/data/legacy_v1_parser.dart';
import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

final class _FailingLedger implements LegacyImportLedger {
  _FailingLedger(this.inner, {required this.failOnCall});

  final LegacyImportLedger inner;
  final int failOnCall;
  int calls = 0;

  @override
  Future<Set<String>> importedIds(LegacyEntityType type) =>
      inner.importedIds(type);

  @override
  Future<bool> hasAnyRecords() => inner.hasAnyRecords();

  @override
  Future<void> record({
    required LegacyEntityType type,
    required LegacySourceKind sourceKind,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
  }) {
    calls += 1;
    if (calls == failOnCall) throw StateError('injected ledger failure');
    return inner.record(
      type: type,
      sourceKind: sourceKind,
      v1Id: v1Id,
      v2Id: v2Id,
      importedAtUtc: importedAtUtc,
      sourceSha256: sourceSha256,
    );
  }
}

Future<LegacySnapshot> _parse(String name) async => const LegacyV1Parser()
    .parseBytes(await File('test/fixtures/legacy_v1/$name').readAsBytes());

void main() {
  final now = DateTime.utc(2026, 11, 4, 10);
  late AppDatabase database;
  late LegacySnapshot snapshot;

  setUpAll(() async {
    snapshot = await _parse('data_v1_2_desktop.json');
  });

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  LegacyImportService buildService({LegacyImportLedger? ledger}) {
    return LegacyImportService(
      database: database,
      ledger: ledger ?? DriftLegacyImportLedger(database),
      clock: FixedAppClock(utcValue: now, localValue: now),
      idGenerator: SequenceIdGenerator(prefix: 'v2'),
    );
  }

  Future<int> count(String table) async {
    final row = await database
        .customSelect('SELECT COUNT(*) AS total FROM $table')
        .getSingle();
    return row.read<int>('total');
  }

  Future<Map<String, TaskRow>> tasksByTitle() async {
    final rows = await database.select(database.taskRows).get();
    return {for (final row in rows) row.title: row};
  }

  Future<void> expectContiguousPositions() async {
    final rows = await database.select(database.taskRows).get();
    final byStatus = <String, List<int>>{};
    for (final row in rows) {
      byStatus.putIfAbsent(row.status, () => <int>[]).add(row.positionInStatus);
    }
    for (final entry in byStatus.entries) {
      final positions = entry.value..sort();
      expect(
        positions,
        List<int>.generate(positions.length, (i) => i),
        reason: 'positions for ${entry.key} must be contiguous 0..n-1',
      );
    }
    final numbers = rows.map((r) => r.displayNumber).toSet();
    expect(numbers, hasLength(rows.length));
  }

  test('preview counts rows and writes nothing', () async {
    final service = buildService();

    final preview = await service.preview(snapshot);

    expect(preview.toImport, <LegacyEntityType, int>{
      LegacyEntityType.task: 4,
      LegacyEntityType.transaction: 2,
      LegacyEntityType.debt: 1,
      LegacyEntityType.installment: 1,
    });
    expect(preview.totalToImport, 8);
    expect(preview.alreadyImported.values.every((n) => n == 0), isTrue);
    expect(preview.skipped, isEmpty);
    expect(await count('tasks'), 0);
    expect(await count('legacy_imports'), 0);
  });

  test('execute imports everything with v1 order, numbers and dates', () async {
    final service = buildService();

    final report = await service.execute(snapshot);

    expect(report.imported, <LegacyEntityType, int>{
      LegacyEntityType.task: 4,
      LegacyEntityType.transaction: 2,
      LegacyEntityType.debt: 1,
      LegacyEntityType.installment: 1,
    });
    expect(report.totalImported, 8);

    final tasks = await tasksByTitle();
    // display_number: oldest created first.
    expect(tasks['ورزش']!.displayNumber, 1);
    expect(tasks['تماس با بانک']!.displayNumber, 2);
    expect(tasks['قبض برق']!.displayNumber, 3);
    expect(tasks['خرید نان']!.displayNumber, 4);
    // positions follow v1's visible order (sort "new" = created desc).
    expect(tasks['خرید نان']!.status, 'planned');
    expect(tasks['خرید نان']!.positionInStatus, 0);
    expect(tasks['تماس با بانک']!.positionInStatus, 1);
    expect(tasks['قبض برق']!.status, 'completed');
    expect(tasks['قبض برق']!.positionInStatus, 0);
    expect(tasks['ورزش']!.positionInStatus, 1);
    // done tasks complete at their created time.
    expect(tasks['قبض برق']!.completedAtUtc, tasks['قبض برق']!.createdAtUtc);
    expect(tasks['ورزش']!.completedAtUtc, tasks['ورزش']!.createdAtUtc);
    expect(tasks['خرید نان']!.completedAtUtc, isNull);
    expect(tasks['خرید نان']!.priority, 3);
    expect(
      tasks['خرید نان']!.createdAtUtc.millisecondsSinceEpoch ~/ 1000,
      1730640000,
    );
    await expectContiguousPositions();

    final finance = DriftFinanceRepository(database);
    final transactions = await finance.watchTransactions().first;
    expect(transactions, hasLength(2));
    expect(transactions.map((t) => t.amount.minorUnits).toSet(), <int>{
      2000000,
      25000000,
    });
    expect(transactions.every((t) => t.amount.scale == 0), isTrue);
    // payments are NOT mirrored into finance_transactions.
    expect(await count('finance_transactions'), 2);

    final debt = (await finance.watchDebts().first).single;
    expect(debt.total.minorUnits, 10000000);
    expect(debt.paid.minorUnits, 2000000);
    expect(debt.createdAtUtc.millisecondsSinceEpoch ~/ 1000, 1730000000);
    expect(await count('debt_payments'), 1);

    final plan = (await finance.watchInstallmentPlans().first).single;
    expect(plan.perInstallment.minorUnits, 3500000);
    expect(plan.installmentCount, 12);
    expect(plan.paidCount, 4);
    expect(await count('installment_payments'), 4);

    expect(await count('legacy_imports'), 8);
    final hashes = await database
        .customSelect('SELECT DISTINCT source_sha256 AS h FROM legacy_imports')
        .get();
    expect(hashes.single.read<String>('h'), snapshot.sourceSha256);
  });

  test('re-running is idempotent and imports only new v1 records', () async {
    final service = buildService();
    await service.execute(snapshot);

    final again = await service.execute(snapshot);
    expect(again.totalImported, 0);
    expect(again.alreadyImported[LegacyEntityType.task], 4);
    expect(again.alreadyImported[LegacyEntityType.transaction], 2);
    expect(await count('tasks'), 4);
    expect(await count('finance_transactions'), 2);
    expect(await count('legacy_imports'), 8);

    final extended = LegacySnapshot(
      sourceKind: snapshot.sourceKind,
      sourceSha256: 'changed-file-hash',
      taskSort: snapshot.taskSort,
      tasks: <LegacyTask>[
        ...snapshot.tasks,
        LegacyTask(
          v1Id: 'added-later',
          title: 'کار جدید',
          done: false,
          priority: 1,
          createdAtUtc: DateTime.utc(2024, 12, 1),
        ),
      ],
      transactions: snapshot.transactions,
      debts: snapshot.debts,
      installments: snapshot.installments,
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );
    final preview = await service.preview(extended);
    expect(preview.toImport[LegacyEntityType.task], 1);
    expect(preview.alreadyImported[LegacyEntityType.task], 4);

    final third = await service.execute(extended);
    expect(third.imported[LegacyEntityType.task], 1);
    final tasks = await tasksByTitle();
    expect(tasks['کار جدید']!.displayNumber, 5);
    expect(tasks['کار جدید']!.positionInStatus, 2);
    await expectContiguousPositions();
  });

  test('importing into a database that already has v2 tasks', () async {
    final tasks = DriftTaskRepository(database);
    for (final id in <String>['existing-1', 'existing-2']) {
      await tasks.create(
        TaskItem(
          id: id,
          displayNumber: 99,
          title: 'موجود $id',
          priority: 0,
          status: TaskStatus.planned,
          positionInStatus: 99,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      );
    }

    await buildService().execute(snapshot);

    final byTitle = await tasksByTitle();
    expect(byTitle['موجود existing-1']!.displayNumber, 1);
    expect(byTitle['موجود existing-2']!.displayNumber, 2);
    expect(byTitle['ورزش']!.displayNumber, 3);
    expect(byTitle['تماس با بانک']!.displayNumber, 4);
    expect(byTitle['قبض برق']!.displayNumber, 5);
    expect(byTitle['خرید نان']!.displayNumber, 6);
    // planned: 2 existing rows keep 0 and 1; imported rows follow.
    expect(byTitle['موجود existing-1']!.positionInStatus, 0);
    expect(byTitle['خرید نان']!.positionInStatus, 2);
    expect(byTitle['تماس با بانک']!.positionInStatus, 3);
    expect(byTitle['قبض برق']!.positionInStatus, 0);
    expect(byTitle['ورزش']!.positionInStatus, 1);
    await expectContiguousPositions();
  });

  test('one failure rolls back every row', () async {
    final service = buildService(
      ledger: _FailingLedger(DriftLegacyImportLedger(database), failOnCall: 5),
    );

    await expectLater(service.execute(snapshot), throwsA(isA<ImportFailure>()));

    for (final table in <String>[
      'tasks',
      'finance_transactions',
      'debts',
      'debt_payments',
      'installment_plans',
      'installment_payments',
      'legacy_imports',
    ]) {
      expect(await count(table), 0, reason: '$table must be rolled back');
    }
  });

  test('a row that fails domain validation is skipped, not fatal', () async {
    final bad = LegacySnapshot(
      sourceKind: LegacySourceKind.dataJson,
      sourceSha256: 'hash',
      taskSort: LegacyTaskSort.newest,
      tasks: const <LegacyTask>[],
      transactions: <LegacyTransaction>[
        LegacyTransaction(
          v1Id: 'tx-bad',
          title: '   ',
          category: 'سایر',
          isIncome: false,
          amountToman: 5,
          occurredAtUtc: now,
        ),
        LegacyTransaction(
          v1Id: 'tx-ok',
          title: 'خوب',
          category: 'سایر',
          isIncome: true,
          amountToman: 7,
          occurredAtUtc: now,
        ),
      ],
      debts: const <LegacyDebt>[],
      installments: const <LegacyInstallment>[],
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );
    final service = buildService();

    final preview = await service.preview(bad);
    expect(preview.toImport[LegacyEntityType.transaction], 1);
    expect(preview.skipped.single.reason, LegacySkipReason.failedValidation);

    final report = await service.execute(bad);
    expect(report.imported[LegacyEntityType.transaction], 1);
    expect(report.skipped.single.v1Id, 'tx-bad');
    expect(await count('finance_transactions'), 1);
  });

  test('the edge-case file imports without aborting', () async {
    final edge = await _parse('data_edge_cases.json');

    final report = await buildService().execute(edge);

    expect(report.imported[LegacyEntityType.task], 1);
    expect(report.imported[LegacyEntityType.transaction], 3);
    expect(report.imported[LegacyEntityType.debt], 1);
    expect(report.imported[LegacyEntityType.installment], 2);
    expect(report.skipped, hasLength(8));
    expect(await count('debt_payments'), 1);
    expect(await count('installment_payments'), 4);
  });
}
