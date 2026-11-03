// The private fields are set from named parameters, which initializing
// formals cannot express for private names.
// ignore_for_file: prefer_initializing_formals

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/drift_legacy_import_ledger.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_import_report.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/drift.dart';

/// Plans, previews and executes a v1 import against one [AppDatabase].
///
/// [execute] runs inside a single database transaction: any failure rolls
/// back every row (tasks, finance rows and ledger rows alike).
final class LegacyImportService {
  LegacyImportService({
    required AppDatabase database,
    required LegacyImportLedger ledger,
    required AppClock clock,
    required IdGenerator idGenerator,
  }) : _database = database,
       _ledger = ledger,
       _clock = clock,
       _ids = idGenerator,
       _finance = DriftFinanceRepository(database, idGenerator: idGenerator);

  final AppDatabase _database;
  final LegacyImportLedger _ledger;
  final AppClock _clock;
  final IdGenerator _ids;
  final DriftFinanceRepository _finance;

  Future<LegacyImportPreview> preview(LegacySnapshot snapshot) async {
    final plan = await _plan(snapshot, newId: (v1Id) => v1Id);
    return LegacyImportPreview(
      toImport: plan.counts,
      alreadyImported: plan.alreadyImported,
      skipped: <LegacySkippedRow>[...snapshot.skipped, ...plan.skipped],
      warnings: snapshot.warnings,
    );
  }

  Future<LegacyImportReport> execute(LegacySnapshot snapshot) async {
    final importedAt = _clock.nowUtc();
    try {
      return await _database.transaction(() async {
        final plan = await _plan(snapshot, newId: (_) => _ids.next());

        for (final entry in plan.tasks) {
          await _insertTask(entry.item);
          await _record(
            LegacyEntityType.task,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.transactions) {
          await _finance.addTransaction(entry.item);
          await _record(
            LegacyEntityType.transaction,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.debts) {
          await _finance.addDebt(entry.item);
          await _record(
            LegacyEntityType.debt,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }
        for (final entry in plan.installments) {
          await _finance.addInstallmentPlan(entry.item);
          await _record(
            LegacyEntityType.installment,
            entry.v1Id,
            entry.item.id,
            snapshot,
            importedAt,
          );
        }

        return LegacyImportReport(
          imported: plan.counts,
          alreadyImported: plan.alreadyImported,
          skipped: <LegacySkippedRow>[...snapshot.skipped, ...plan.skipped],
          warnings: snapshot.warnings,
        );
      });
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw ImportFailure(
        'ورود اطلاعات انجام نشد و هیچ تغییری ذخیره نشد.',
        cause: error,
      );
    }
  }

  Future<void> _record(
    LegacyEntityType type,
    String v1Id,
    String v2Id,
    LegacySnapshot snapshot,
    DateTime importedAt,
  ) {
    return _ledger.record(
      type: type,
      sourceKind: snapshot.sourceKind,
      v1Id: v1Id,
      v2Id: v2Id,
      importedAtUtc: importedAt,
      sourceSha256: snapshot.sourceSha256,
    );
  }

  /// Writes a task row directly. `DriftTaskRepository.create` would ignore
  /// the display number and position chosen by the planner.
  Future<void> _insertTask(TaskItem task) async {
    await _database
        .into(_database.taskRows)
        .insert(
          TaskRowsCompanion.insert(
            id: task.id,
            displayNumber: task.displayNumber,
            title: task.title,
            priority: task.priority,
            status: task.status.storageValue,
            positionInStatus: task.positionInStatus,
            createdAtUtc: task.createdAtUtc,
            updatedAtUtc: task.updatedAtUtc,
            completedAtUtc: Value<DateTime?>(task.completedAtUtc),
          ),
        );
  }

  // ---- planning (shared by preview and execute) ----

  Future<_ImportPlan> _plan(
    LegacySnapshot snapshot, {
    required String Function(String v1Id) newId,
  }) async {
    final plan = _ImportPlan();
    final fallback = snapshot.exportedAtUtc ?? _clock.nowUtc();

    await _planTasks(snapshot, plan, fallback, newId);

    final importedTransactions = await _ledger.importedIds(
      LegacyEntityType.transaction,
    );
    for (final tx in snapshot.transactions) {
      if (importedTransactions.contains(tx.v1Id)) {
        plan.markAlready(LegacyEntityType.transaction);
        continue;
      }
      try {
        final occurred = tx.occurredAtUtc ?? fallback;
        plan.transactions.add((
          v1Id: tx.v1Id,
          item: FinanceTransaction.create(
            id: newId(tx.v1Id),
            type: tx.isIncome
                ? FinanceTransactionType.income
                : FinanceTransactionType.expense,
            title: tx.title,
            category: tx.category,
            amount: _toman(tx.amountToman),
            occurredAtUtc: occurred,
            createdAtUtc: occurred,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.transaction, tx.v1Id);
      }
    }

    final importedDebts = await _ledger.importedIds(LegacyEntityType.debt);
    for (final debt in snapshot.debts) {
      if (importedDebts.contains(debt.v1Id)) {
        plan.markAlready(LegacyEntityType.debt);
        continue;
      }
      try {
        final created = debt.createdAtUtc ?? fallback;
        plan.debts.add((
          v1Id: debt.v1Id,
          item: Debt(
            id: newId(debt.v1Id),
            title: debt.title,
            total: _toman(debt.totalToman),
            paid: _toman(debt.paidToman),
            createdAtUtc: created,
            updatedAtUtc: created,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.debt, debt.v1Id);
      }
    }

    final importedInstallments = await _ledger.importedIds(
      LegacyEntityType.installment,
    );
    for (final installment in snapshot.installments) {
      if (importedInstallments.contains(installment.v1Id)) {
        plan.markAlready(LegacyEntityType.installment);
        continue;
      }
      try {
        final created = installment.createdAtUtc ?? fallback;
        plan.installments.add((
          v1Id: installment.v1Id,
          item: InstallmentPlan(
            id: newId(installment.v1Id),
            title: installment.title,
            perInstallment: _toman(installment.perToman),
            installmentCount: installment.count,
            paidCount: installment.paidCount,
            createdAtUtc: created,
            updatedAtUtc: created,
          ),
        ));
      } on ValidationFailure {
        plan.fail(LegacyEntityType.installment, installment.v1Id);
      }
    }

    return plan;
  }

  Future<void> _planTasks(
    LegacySnapshot snapshot,
    _ImportPlan plan,
    DateTime fallback,
    String Function(String v1Id) newId,
  ) async {
    final imported = await _ledger.importedIds(LegacyEntityType.task);
    final valid = <LegacyTask>[];
    for (final task in snapshot.tasks) {
      if (imported.contains(task.v1Id)) {
        plan.markAlready(LegacyEntityType.task);
        continue;
      }
      try {
        _buildTask(task, task.v1Id, 1, 0, fallback); // validation only
        valid.add(task);
      } on ValidationFailure {
        plan.fail(LegacyEntityType.task, task.v1Id);
      }
    }
    if (valid.isEmpty) return;

    DateTime createdOf(LegacyTask task) => task.createdAtUtc ?? fallback;

    // Display numbers: oldest first, continuing after the highest used one.
    final byAge = <LegacyTask>[...valid]
      ..sort((a, b) {
        final byDate = createdOf(a).compareTo(createdOf(b));
        return byDate != 0 ? byDate : a.v1Id.compareTo(b.v1Id);
      });
    final maxRow = await _database
        .customSelect(
          'SELECT COALESCE(MAX(display_number), 0) AS max_number FROM tasks',
          readsFrom: {_database.taskRows},
        )
        .getSingle();
    var nextNumber = maxRow.read<int>('max_number');
    final numbers = <String, int>{
      for (final task in byAge) task.v1Id: ++nextNumber,
    };

    // Positions: per status, after existing rows, in v1's visible order.
    final countRows = await _database
        .customSelect(
          'SELECT status, COUNT(*) AS total FROM tasks GROUP BY status',
          readsFrom: {_database.taskRows},
        )
        .get();
    final existing = <String, int>{
      for (final row in countRows)
        row.read<String>('status'): row.read<int>('total'),
    };

    for (final done in <bool>[false, true]) {
      final status = done ? TaskStatus.completed : TaskStatus.planned;
      final group = valid.where((task) => task.done == done).toList()
        ..sort((a, b) => _compareVisible(a, b, snapshot.taskSort, createdOf));
      var position = existing[status.storageValue] ?? 0;
      for (final task in group) {
        plan.tasks.add((
          v1Id: task.v1Id,
          item: _buildTask(
            task,
            newId(task.v1Id),
            numbers[task.v1Id]!,
            position++,
            fallback,
          ),
        ));
      }
    }
  }

  TaskItem _buildTask(
    LegacyTask task,
    String id,
    int displayNumber,
    int position,
    DateTime fallback,
  ) {
    final created = task.createdAtUtc ?? fallback;
    return TaskItem(
      id: id,
      displayNumber: displayNumber,
      title: task.title,
      priority: task.priority,
      status: task.done ? TaskStatus.completed : TaskStatus.planned,
      positionInStatus: position,
      createdAtUtc: created,
      updatedAtUtc: created,
      completedAtUtc: task.done ? created : null,
    );
  }

  /// v1's visible order inside one status. `alphabetical` falls back to a
  /// plain `String.compareTo` (v1 used JS `localeCompare("fa")`).
  int _compareVisible(
    LegacyTask a,
    LegacyTask b,
    LegacyTaskSort sort,
    DateTime Function(LegacyTask) createdOf,
  ) {
    int newest() {
      final byDate = createdOf(b).compareTo(createdOf(a));
      return byDate != 0 ? byDate : a.v1Id.compareTo(b.v1Id);
    }

    switch (sort) {
      case LegacyTaskSort.newest:
        return newest();
      case LegacyTaskSort.priority:
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : newest();
      case LegacyTaskSort.alphabetical:
        final byTitle = a.title.compareTo(b.title);
        return byTitle != 0 ? byTitle : newest();
    }
  }

  Money _toman(int value) => Money(
    minorUnits: value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}

final class _ImportPlan {
  final List<({String v1Id, TaskItem item})> tasks =
      <({String v1Id, TaskItem item})>[];
  final List<({String v1Id, FinanceTransaction item})> transactions =
      <({String v1Id, FinanceTransaction item})>[];
  final List<({String v1Id, Debt item})> debts = <({String v1Id, Debt item})>[];
  final List<({String v1Id, InstallmentPlan item})> installments =
      <({String v1Id, InstallmentPlan item})>[];
  final List<LegacySkippedRow> skipped = <LegacySkippedRow>[];
  final Map<LegacyEntityType, int> alreadyImported = <LegacyEntityType, int>{
    for (final type in LegacyEntityType.values) type: 0,
  };

  Map<LegacyEntityType, int> get counts => <LegacyEntityType, int>{
    LegacyEntityType.task: tasks.length,
    LegacyEntityType.transaction: transactions.length,
    LegacyEntityType.debt: debts.length,
    LegacyEntityType.installment: installments.length,
  };

  void markAlready(LegacyEntityType type) {
    alreadyImported[type] = (alreadyImported[type] ?? 0) + 1;
  }

  void fail(LegacyEntityType type, String v1Id) {
    skipped.add(
      LegacySkippedRow(
        entityType: type,
        v1Id: v1Id,
        reason: LegacySkipReason.failedValidation,
      ),
    );
  }
}
