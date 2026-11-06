import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_repository.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';
import 'package:drift/drift.dart';

final class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository(
    this._database, {
    this._idGenerator = const UuidV7IdGenerator(),
  });

  final AppDatabase _database;
  final IdGenerator _idGenerator;

  @override
  Stream<List<FinanceTransaction>> watchTransactions() {
    final query = _database.select(_database.financeTransactionRows)
      ..orderBy(<OrderingTerm Function(FinanceTransactionRows)>[
        (row) => OrderingTerm.desc(row.occurredAtUtc),
        (row) => OrderingTerm.desc(row.createdAtUtc),
        (row) => OrderingTerm.desc(row.id),
      ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => FinanceTransaction.create(
              id: row.id,
              type: _transactionType(row.type),
              title: row.title,
              category: row.category,
              amount: _money(
                minorUnits: row.amountMinorUnits,
                currencyCode: row.currencyCode,
                scale: row.scale,
              ),
              occurredAtUtc: row.occurredAtUtc.toUtc(),
              createdAtUtc: row.createdAtUtc.toUtc(),
              updatedAtUtc: row.updatedAtUtc.toUtc(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<List<Debt>> watchDebts() {
    final query =
        _database.select(_database.debtRows).join(<Join>[
            leftOuterJoin(
              _database.debtPaymentRows,
              _database.debtPaymentRows.debtId.equalsExp(_database.debtRows.id),
            ),
          ])
          ..where(_database.debtRows.archivedAtUtc.isNull())
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_database.debtRows.createdAtUtc),
            OrderingTerm.desc(_database.debtRows.id),
            OrderingTerm.asc(_database.debtPaymentRows.createdAtUtc),
          ]);

    return query.watch().map(_mapDebtJoinRows);
  }

  @override
  Stream<List<InstallmentPlan>> watchInstallmentPlans() {
    final query =
        _database.select(_database.installmentPlanRows).join(<Join>[
            leftOuterJoin(
              _database.installmentPaymentRows,
              _database.installmentPaymentRows.planId.equalsExp(
                _database.installmentPlanRows.id,
              ),
            ),
          ])
          ..where(_database.installmentPlanRows.archivedAtUtc.isNull())
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_database.installmentPlanRows.createdAtUtc),
            OrderingTerm.desc(_database.installmentPlanRows.id),
            OrderingTerm.asc(
              _database.installmentPaymentRows.installmentNumber,
            ),
          ]);

    return query.watch().map(_mapInstallmentJoinRows);
  }

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {
    await _database
        .into(_database.financeTransactionRows)
        .insert(
          FinanceTransactionRowsCompanion(
            id: Value<String>(transaction.id),
            type: Value<String>(transaction.type.name),
            title: Value<String>(transaction.title),
            category: Value<String>(transaction.category),
            amountMinorUnits: Value<int>(transaction.amount.minorUnits),
            currencyCode: Value<String>(transaction.amount.currencyCode),
            scale: Value<int>(transaction.amount.scale),
            occurredAtUtc: Value<DateTime>(transaction.occurredAtUtc),
            createdAtUtc: Value<DateTime>(transaction.createdAtUtc),
            updatedAtUtc: Value<DateTime>(transaction.updatedAtUtc),
          ),
        );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_database.delete(
      _database.financeTransactionRows,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> addDebt(Debt debt) {
    return _database.transaction(() async {
      await _database
          .into(_database.debtRows)
          .insert(
            DebtRowsCompanion(
              id: Value<String>(debt.id),
              title: Value<String>(debt.title),
              totalMinorUnits: Value<int>(debt.total.minorUnits),
              currencyCode: Value<String>(debt.total.currencyCode),
              scale: Value<int>(debt.total.scale),
              createdAtUtc: Value<DateTime>(debt.createdAtUtc),
              updatedAtUtc: Value<DateTime>(debt.updatedAtUtc),
            ),
          );

      if (debt.paid.isPositive) {
        await _insertDebtPayment(
          debtId: debt.id,
          amountMinorUnits: debt.paid.minorUnits,
          paidAtUtc: debt.updatedAtUtc,
        );
      }
    });
  }

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
  }) {
    validateExactPositiveMoney(amount);
    final paidAtUtc = paidAt.toUtc();

    return _database.transaction(() async {
      final debtRow =
          await (_database.select(_database.debtRows)..where(
                (row) => row.id.equals(debtId) & row.archivedAtUtc.isNull(),
              ))
              .getSingleOrNull();

      if (debtRow == null) {
        throw const ValidationFailure('بدهی پیدا نشد.');
      }

      final paymentRows = await (_database.select(
        _database.debtPaymentRows,
      )..where((row) => row.debtId.equals(debtId))).get();
      final paidMinorUnits = paymentRows.fold<int>(
        0,
        (sum, row) => Money.checkedAdd(sum, row.amountMinorUnits),
      );
      final remainingMinorUnits = Money.checkedSubtract(
        debtRow.totalMinorUnits,
        paidMinorUnits,
      );

      if (amount.minorUnits > remainingMinorUnits) {
        throw const ValidationFailure('مبلغ پرداخت از مانده بدهی بیشتر است.');
      }

      await _insertDebtPayment(
        debtId: debtId,
        amountMinorUnits: amount.minorUnits,
        paidAtUtc: paidAtUtc,
      );

      await (_database.update(_database.debtRows)
            ..where((row) => row.id.equals(debtId)))
          .write(DebtRowsCompanion(updatedAtUtc: Value<DateTime>(paidAtUtc)));
    });
  }

  @override
  Future<void> deleteDebt(String id) async {
    await (_database.delete(
      _database.debtRows,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> addInstallmentPlan(InstallmentPlan plan) {
    return _database.transaction(() async {
      await _database
          .into(_database.installmentPlanRows)
          .insert(
            InstallmentPlanRowsCompanion(
              id: Value<String>(plan.id),
              title: Value<String>(plan.title),
              perInstallmentMinorUnits: Value<int>(
                plan.perInstallment.minorUnits,
              ),
              installmentCount: Value<int>(plan.installmentCount),
              currencyCode: Value<String>(plan.perInstallment.currencyCode),
              scale: Value<int>(plan.perInstallment.scale),
              createdAtUtc: Value<DateTime>(plan.createdAtUtc),
              updatedAtUtc: Value<DateTime>(plan.updatedAtUtc),
            ),
          );

      for (
        var installmentNumber = 1;
        installmentNumber <= plan.paidCount;
        installmentNumber++
      ) {
        await _insertInstallmentPayment(
          planId: plan.id,
          installmentNumber: installmentNumber,
          amountMinorUnits: plan.perInstallment.minorUnits,
          paidAtUtc: plan.updatedAtUtc,
        );
      }
    });
  }

  @override
  Future<void> payNextInstallment({
    required String planId,
    required DateTime paidAt,
  }) {
    final paidAtUtc = paidAt.toUtc();

    return _database.transaction(() async {
      final planRow =
          await (_database.select(_database.installmentPlanRows)..where(
                (row) => row.id.equals(planId) & row.archivedAtUtc.isNull(),
              ))
              .getSingleOrNull();

      if (planRow == null) {
        throw const ValidationFailure('برنامه اقساط پیدا نشد.');
      }

      final paymentRows =
          await (_database.select(_database.installmentPaymentRows)
                ..where((row) => row.planId.equals(planId))
                ..orderBy(<OrderingTerm Function(InstallmentPaymentRows)>[
                  (row) => OrderingTerm.asc(row.installmentNumber),
                ]))
              .get();
      final nextNumber = paymentRows.length + 1;

      if (nextNumber > planRow.installmentCount) {
        throw const ValidationFailure('همه اقساط این برنامه پرداخت شده‌اند.');
      }

      await _insertInstallmentPayment(
        planId: planId,
        installmentNumber: nextNumber,
        amountMinorUnits: planRow.perInstallmentMinorUnits,
        paidAtUtc: paidAtUtc,
      );

      await (_database.update(
        _database.installmentPlanRows,
      )..where((row) => row.id.equals(planId))).write(
        InstallmentPlanRowsCompanion(updatedAtUtc: Value<DateTime>(paidAtUtc)),
      );
    });
  }

  @override
  Future<void> deleteInstallmentPlan(String id) async {
    await (_database.delete(
      _database.installmentPlanRows,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> _insertDebtPayment({
    required String debtId,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
  }) async {
    await _database
        .into(_database.debtPaymentRows)
        .insert(
          DebtPaymentRowsCompanion(
            id: Value<String>(_idGenerator.next()),
            debtId: Value<String>(debtId),
            amountMinorUnits: Value<int>(amountMinorUnits),
            paidAtUtc: Value<DateTime>(paidAtUtc),
            createdAtUtc: Value<DateTime>(paidAtUtc),
          ),
        );
  }

  Future<void> _insertInstallmentPayment({
    required String planId,
    required int installmentNumber,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
  }) async {
    await _database
        .into(_database.installmentPaymentRows)
        .insert(
          InstallmentPaymentRowsCompanion(
            id: Value<String>(_idGenerator.next()),
            planId: Value<String>(planId),
            installmentNumber: Value<int>(installmentNumber),
            amountMinorUnits: Value<int>(amountMinorUnits),
            paidAtUtc: Value<DateTime>(paidAtUtc),
            createdAtUtc: Value<DateTime>(paidAtUtc),
          ),
        );
  }

  List<Debt> _mapDebtJoinRows(List<TypedResult> rows) {
    final aggregates = <String, _DebtAggregate>{};

    for (final result in rows) {
      final debtRow = result.readTable(_database.debtRows);
      final paymentRow = result.readTableOrNull(_database.debtPaymentRows);
      final aggregate = aggregates.putIfAbsent(
        debtRow.id,
        () => _DebtAggregate(debtRow),
      );
      if (paymentRow != null) {
        aggregate.paidMinorUnits = Money.checkedAdd(
          aggregate.paidMinorUnits,
          paymentRow.amountMinorUnits,
        );
      }
    }

    return aggregates.values
        .map(
          (aggregate) => Debt(
            id: aggregate.row.id,
            title: aggregate.row.title,
            total: _money(
              minorUnits: aggregate.row.totalMinorUnits,
              currencyCode: aggregate.row.currencyCode,
              scale: aggregate.row.scale,
            ),
            paid: _money(
              minorUnits: aggregate.paidMinorUnits,
              currencyCode: aggregate.row.currencyCode,
              scale: aggregate.row.scale,
            ),
            createdAtUtc: aggregate.row.createdAtUtc.toUtc(),
            updatedAtUtc: aggregate.row.updatedAtUtc.toUtc(),
          ),
        )
        .toList(growable: false);
  }

  List<InstallmentPlan> _mapInstallmentJoinRows(List<TypedResult> rows) {
    final aggregates = <String, _InstallmentAggregate>{};

    for (final result in rows) {
      final planRow = result.readTable(_database.installmentPlanRows);
      final paymentRow = result.readTableOrNull(
        _database.installmentPaymentRows,
      );
      final aggregate = aggregates.putIfAbsent(
        planRow.id,
        () => _InstallmentAggregate(planRow),
      );
      if (paymentRow != null) {
        aggregate.paidCount += 1;
      }
    }

    return aggregates.values
        .map(
          (aggregate) => InstallmentPlan(
            id: aggregate.row.id,
            title: aggregate.row.title,
            perInstallment: _money(
              minorUnits: aggregate.row.perInstallmentMinorUnits,
              currencyCode: aggregate.row.currencyCode,
              scale: aggregate.row.scale,
            ),
            installmentCount: aggregate.row.installmentCount,
            paidCount: aggregate.paidCount,
            createdAtUtc: aggregate.row.createdAtUtc.toUtc(),
            updatedAtUtc: aggregate.row.updatedAtUtc.toUtc(),
          ),
        )
        .toList(growable: false);
  }
}

final class _DebtAggregate {
  _DebtAggregate(this.row);

  final DebtRow row;
  int paidMinorUnits = 0;
}

final class _InstallmentAggregate {
  _InstallmentAggregate(this.row);

  final InstallmentPlanRow row;
  int paidCount = 0;
}

FinanceTransactionType _transactionType(String value) {
  return switch (value) {
    'income' => FinanceTransactionType.income,
    'expense' => FinanceTransactionType.expense,
    _ => throw const PersistenceFailure('نوع تراکنش ذخیره‌شده نامعتبر است.'),
  };
}

Money _money({
  required int minorUnits,
  required String currencyCode,
  required int scale,
}) {
  return Money(
    minorUnits: minorUnits,
    currencyCode: currencyCode,
    scale: scale,
  );
}
