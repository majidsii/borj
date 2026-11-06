import 'dart:io';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/data/drift_finance_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

const String _seedSql = '''
INSERT INTO finance_transactions (id, type, title, category, amount_minor_units, currency_code, scale, occurred_at_utc, created_at_utc, updated_at_utc) VALUES
  ('tx-whole', 'income', 'A', 'c', 1500000000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-half-down', 'expense', 'B', 'c', 250000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-half-up', 'expense', 'C', 'c', 350000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-tiny', 'expense', 'D', 'c', 40000000, 'IRT', 8, 1780000000, 1780000000, 1780000000),
  ('tx-already-whole', 'expense', 'E', 'c', 777, 'IRT', 0, 1780000000, 1780000000, 1780000000);
INSERT INTO debts (id, title, total_minor_units, currency_code, scale, created_at_utc, updated_at_utc) VALUES
  ('debt-exact', 'D1', 1000000000000, 'IRT', 8, 1780000000, 1780000000),
  ('debt-rounding', 'D2', 250000000, 'IRT', 8, 1780000000, 1780000000);
INSERT INTO debt_payments (id, debt_id, amount_minor_units, paid_at_utc, created_at_utc) VALUES
  ('p1', 'debt-exact', 400000000000, 1780000000, 1780000000),
  ('p2', 'debt-exact', 600000000000, 1780000100, 1780000100),
  ('p3', 'debt-rounding', 150000000, 1780000000, 1780000000),
  ('p4', 'debt-rounding', 100000000, 1780000100, 1780000100);
INSERT INTO installment_plans (id, title, per_installment_minor_units, installment_count, currency_code, scale, created_at_utc, updated_at_utc) VALUES
  ('plan-1', 'P', 300000000000, 12, 'IRT', 8, 1780000000, 1780000000);
INSERT INTO installment_payments (id, plan_id, installment_number, amount_minor_units, paid_at_utc, created_at_utc) VALUES
  ('ip1', 'plan-1', 1, 300000000000, 1780000000, 1780000000),
  ('ip2', 'plan-1', 2, 300000000000, 1780000100, 1780000100);
''';

Future<File> _seedSchema8(Directory directory) async {
  final file = File('${directory.path}/dashboard.sqlite');
  final created = AppDatabase(NativeDatabase(file));
  await created.customSelect('SELECT 1').get();
  await created.close();

  final raw = sqlite3.open(file.path);
  try {
    raw.execute('DROP TABLE legacy_imports');
    raw.execute('PRAGMA user_version = 8');
    raw.execute(_seedSql);
  } finally {
    raw.close();
  }
  return file;
}

Future<void> _expectMigratedValues(AppDatabase database) async {
  final finance = DriftFinanceRepository(
    database,
    idGenerator: SequenceIdGenerator(prefix: 'check'),
  );

  final transactions = {
    for (final tx in await finance.watchTransactions().first) tx.id: tx,
  };
  expect(transactions['tx-whole']!.amount.minorUnits, 15000);
  expect(transactions['tx-half-down']!.amount.minorUnits, 2); // 2.5 -> even
  expect(transactions['tx-half-up']!.amount.minorUnits, 4); // 3.5 -> even
  expect(transactions['tx-tiny']!.amount.minorUnits, 1); // 0.4 clamped to 1
  expect(transactions['tx-already-whole']!.amount.minorUnits, 777);
  for (final tx in transactions.values) {
    expect(tx.amount.scale, Money.financeScale);
  }

  final debts = {for (final d in await finance.watchDebts().first) d.id: d};
  expect(debts['debt-exact']!.total.minorUnits, 10000);
  expect(debts['debt-exact']!.paid.minorUnits, 10000);
  expect(debts['debt-exact']!.settled, isTrue);
  // total 2.5 -> 2, payments 1.5 -> 2 and 1.0 -> 1 sum to 3: the total is
  // raised to 3 so Debt() stays valid.
  expect(debts['debt-rounding']!.total.minorUnits, 3);
  expect(debts['debt-rounding']!.paid.minorUnits, 3);

  final plans = await finance.watchInstallmentPlans().first;
  expect(plans.single.perInstallment.minorUnits, 3000);
  expect(plans.single.installmentCount, 12);
  expect(plans.single.paidCount, 2);
  expect(plans.single.perInstallment.scale, Money.financeScale);

  final leftovers = await database
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM finance_transactions WHERE scale != 0) + '
        '(SELECT COUNT(*) FROM debts WHERE scale != 0) + '
        '(SELECT COUNT(*) FROM installment_plans WHERE scale != 0) AS bad',
      )
      .getSingle();
  expect(leftovers.read<int>('bad'), 0);
}

void main() {
  test('finance scale is whole toman', () {
    expect(Money.financeScale, 0);
    expect(Money.zeroIRT.scale, 0);
  });

  test(
    'a fresh database is schema 9 and has the legacy_imports table',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      try {
        expect(database.schemaVersion, 9);
        final rows = await database
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name = 'legacy_imports'",
            )
            .get();
        expect(rows, hasLength(1));
      } finally {
        await database.close();
      }
    },
  );

  test('legacy_imports is unique on (entity_type, v1_id) only', () async {
    final database = AppDatabase(NativeDatabase.memory());
    try {
      final now = DateTime.utc(2026, 11, 4);
      Future<void> insert(String hash, String sourceKind) => database
          .into(database.legacyImportRows)
          .insert(
            LegacyImportRowsCompanion.insert(
              sourceKind: sourceKind,
              entityType: 'task',
              v1Id: 'v1-id',
              v2Id: 'v2-$hash',
              importedAtUtc: now,
              sourceSha256: hash,
            ),
          );

      await insert('hash-a', 'data_json');
      await expectLater(insert('hash-b', 'export'), throwsA(anything));
    } finally {
      await database.close();
    }
  });

  test('schema 8 to 9 rescales rows deterministically', () async {
    final directory = await Directory.systemTemp.createTemp('rdf-scale-');
    try {
      final file = await _seedSchema8(directory);

      final upgraded = AppDatabase(NativeDatabase(file));
      try {
        await _expectMigratedValues(upgraded);
        final version = await upgraded
            .customSelect('PRAGMA user_version')
            .get();
        expect(version.single.read<int>('user_version'), 9);
        final tables = await upgraded
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name = 'legacy_imports'",
            )
            .get();
        expect(tables, hasLength(1));
      } finally {
        await upgraded.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('migrated data survives a restart and is not rescaled twice', () async {
    final directory = await Directory.systemTemp.createTemp('rdf-restart-');
    try {
      final file = await _seedSchema8(directory);

      final first = AppDatabase(NativeDatabase(file));
      await _expectMigratedValues(first);
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      try {
        await _expectMigratedValues(second);
        final version = await second.customSelect('PRAGMA user_version').get();
        expect(version.single.read<int>('user_version'), 9);
      } finally {
        await second.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
