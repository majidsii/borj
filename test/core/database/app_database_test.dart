import 'package:borj/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version nine creates all persistence tables', () async {
    expect(database.schemaVersion, 9);

    final rows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      names,
      containsAll(<String>{
        'tasks',
        'finance_transactions',
        'debts',
        'debt_payments',
        'installment_plans',
        'installment_payments',
        'task_reminder_rules',
        'task_recurrence_rules',
        'task_recurrence_exceptions',
        'task_occurrence_completions',
        'task_time_entries',
        'notification_schedules',
        'legacy_imports',
      }),
    );
  });

  test('installment number is unique inside a plan', () async {
    final now = DateTime.utc(2026, 7, 26);
    await database
        .into(database.installmentPlanRows)
        .insert(
          InstallmentPlanRowsCompanion.insert(
            id: 'plan-1',
            title: 'قسط خودرو',
            perInstallmentMinorUnits: 100000000000000,
            installmentCount: 12,
            currencyCode: const Value('IRT'),
            scale: const Value(8),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );

    Future<int> insertPayment(String id) {
      return database
          .into(database.installmentPaymentRows)
          .insert(
            InstallmentPaymentRowsCompanion.insert(
              id: id,
              planId: 'plan-1',
              installmentNumber: 1,
              amountMinorUnits: 100000000000000,
              paidAtUtc: now,
              createdAtUtc: now,
            ),
          );
    }

    await insertPayment('payment-1');
    await expectLater(insertPayment('payment-2'), throwsA(isA<Exception>()));
  });

  test('deleting a debt cascades to its payments', () async {
    final now = DateTime.utc(2026, 7, 26);
    await database
        .into(database.debtRows)
        .insert(
          DebtRowsCompanion.insert(
            id: 'debt-1',
            title: 'قرض',
            totalMinorUnits: 500000000000000,
            currencyCode: const Value('IRT'),
            scale: const Value(8),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    await database
        .into(database.debtPaymentRows)
        .insert(
          DebtPaymentRowsCompanion.insert(
            id: 'debt-payment-1',
            debtId: 'debt-1',
            amountMinorUnits: 100000000000000,
            paidAtUtc: now,
            createdAtUtc: now,
          ),
        );

    await (database.delete(
      database.debtRows,
    )..where((row) => row.id.equals('debt-1'))).go();

    expect(await database.select(database.debtPaymentRows).get(), isEmpty);
  });

  test('foreign keys reject a payment without a parent', () async {
    final now = DateTime.utc(2026, 7, 26);

    await expectLater(
      database
          .into(database.debtPaymentRows)
          .insert(
            DebtPaymentRowsCompanion.insert(
              id: 'orphan-payment',
              debtId: 'missing-debt',
              amountMinorUnits: 100000000,
              paidAtUtc: now,
              createdAtUtc: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
