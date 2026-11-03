enum LegacyEntityType {
  task,
  transaction,
  debt,
  installment;

  String get storageValue => name;
}

enum LegacySourceKind {
  dataJson('data_json'),
  export('export');

  const LegacySourceKind(this.storageValue);

  final String storageValue;
}

/// v1's visible task order preference (`tasklist:prefs:v1`.sort).
enum LegacyTaskSort { newest, priority, alphabetical }

enum LegacySkipReason {
  notAnObject,
  emptyTitle,
  duplicateId,
  invalidAmount,
  invalidCount,
  totalOverflow,
  failedValidation,
}

enum LegacyWarningCode {
  tasksUnreadable,
  financeUnreadable,
  unknownTransactionType,
  paidClamped,
  paidCountClamped,
}

final class LegacySkippedRow {
  const LegacySkippedRow({
    required this.entityType,
    required this.v1Id,
    required this.reason,
  });

  final LegacyEntityType entityType;
  final String? v1Id;
  final LegacySkipReason reason;
}

final class LegacyWarning {
  const LegacyWarning({required this.code, this.entityType, this.v1Id});

  final LegacyWarningCode code;
  final LegacyEntityType? entityType;
  final String? v1Id;
}

final class LegacyTask {
  const LegacyTask({
    required this.v1Id,
    required this.title,
    required this.done,
    required this.priority,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final bool done;
  final int priority;
  final DateTime? createdAtUtc;
}

final class LegacyTransaction {
  const LegacyTransaction({
    required this.v1Id,
    required this.title,
    required this.category,
    required this.isIncome,
    required this.amountToman,
    this.occurredAtUtc,
  });

  final String v1Id;
  final String title;
  final String category;
  final bool isIncome;
  final int amountToman;
  final DateTime? occurredAtUtc;
}

final class LegacyDebt {
  const LegacyDebt({
    required this.v1Id,
    required this.title,
    required this.totalToman,
    required this.paidToman,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final int totalToman;
  final int paidToman;
  final DateTime? createdAtUtc;
}

final class LegacyInstallment {
  const LegacyInstallment({
    required this.v1Id,
    required this.title,
    required this.perToman,
    required this.count,
    required this.paidCount,
    this.createdAtUtc,
  });

  final String v1Id;
  final String title;
  final int perToman;
  final int count;
  final int paidCount;
  final DateTime? createdAtUtc;
}

final class LegacySnapshot {
  const LegacySnapshot({
    required this.sourceKind,
    required this.sourceSha256,
    required this.taskSort,
    required this.tasks,
    required this.transactions,
    required this.debts,
    required this.installments,
    required this.skipped,
    required this.warnings,
    this.exportedAtUtc,
  });

  final LegacySourceKind sourceKind;
  final String sourceSha256;
  final LegacyTaskSort taskSort;
  final DateTime? exportedAtUtc;
  final List<LegacyTask> tasks;
  final List<LegacyTransaction> transactions;
  final List<LegacyDebt> debts;
  final List<LegacyInstallment> installments;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  bool get isEmpty =>
      tasks.isEmpty &&
      transactions.isEmpty &&
      debts.isEmpty &&
      installments.isEmpty;
}
