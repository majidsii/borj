import 'dart:developer' as developer;

import 'package:dashboard_shakhsi/core/database/database_connection.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class TaskRows extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  IntColumn get displayNumber => integer().unique()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer()();
  TextColumn get status => text()();
  IntColumn get positionInStatus => integer()();
  DateTimeColumn get startAtUtc => dateTime().nullable()();
  DateTimeColumn get dueAtUtc => dateTime().nullable()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get completedAtUtc => dateTime().nullable()();
  DateTimeColumn get canceledAtUtc => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (display_number > 0)',
    'CHECK (priority BETWEEN 0 AND 3)',
    "CHECK (status IN ('planned', 'inProgress', 'completed', 'canceled'))",
    'CHECK (position_in_status >= 0)',
    'CHECK (estimated_duration_minutes IS NULL '
        'OR estimated_duration_minutes > 0)',
    'CHECK (start_at_utc IS NULL OR due_at_utc IS NULL '
        'OR due_at_utc >= start_at_utc)',
    "CHECK ((status = 'completed' AND completed_at_utc IS NOT NULL "
        "AND canceled_at_utc IS NULL) OR "
        "(status = 'canceled' AND canceled_at_utc IS NOT NULL "
        "AND completed_at_utc IS NULL) OR "
        "(status IN ('planned', 'inProgress') "
        "AND completed_at_utc IS NULL AND canceled_at_utc IS NULL))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class FinanceTransactionRows extends Table {
  @override
  String get tableName => 'finance_transactions';

  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get amountMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(0))();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (type IN ('income', 'expense'))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class DebtRows extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get totalMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get archivedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class DebtPaymentRows extends Table {
  @override
  String get tableName => 'debt_payments';

  TextColumn get id => text()();
  TextColumn get debtId =>
      text().references(DebtRows, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinorUnits => integer()();
  DateTimeColumn get paidAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class InstallmentPlanRows extends Table {
  @override
  String get tableName => 'installment_plans';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get perInstallmentMinorUnits => integer()();
  IntColumn get installmentCount => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get archivedAtUtc => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (installment_count > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class InstallmentPaymentRows extends Table {
  @override
  String get tableName => 'installment_payments';

  TextColumn get id => text()();
  TextColumn get planId => text().references(
    InstallmentPlanRows,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get installmentNumber => integer()();
  IntColumn get amountMinorUnits => integer()();
  DateTimeColumn get paidAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{planId, installmentNumber},
  ];
}

class TaskReminderRuleRows extends Table {
  @override
  String get tableName => 'task_reminder_rules';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get trigger => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get privacyMode => text().withDefault(const Constant('full'))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (trigger IN ('atDue', 'fifteenMinutesBefore', 'oneHourBefore', 'oneDayBefore'))",
    "CHECK (privacy_mode IN ('full', 'private'))",
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{taskId, trigger},
  ];
}

class TaskRecurrenceRuleRows extends Table {
  @override
  String get tableName => 'task_recurrence_rules';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade).unique()();
  TextColumn get ruleJson => text()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(rule_json) > 2)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class TaskRecurrenceExceptionRows extends Table {
  @override
  String get tableName => 'task_recurrence_exceptions';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalLocalKey => text()();
  TextColumn get exceptionJson => text()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(original_local_key) >= 16)',
    'CHECK (length(exception_json) > 2)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{taskId, originalLocalKey},
  ];
}

class TaskOccurrenceCompletionRows extends Table {
  @override
  String get tableName => 'task_occurrence_completions';

  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalLocalKey => text()();
  DateTimeColumn get completedAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(original_local_key) >= 16)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    taskId,
    originalLocalKey,
  };
}

class TaskTimeEntryRows extends Table {
  @override
  String get tableName => 'task_time_entries';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get source => text()();
  TextColumn get state => text()();
  DateTimeColumn get startedAtUtc => dateTime()();
  DateTimeColumn get lastResumedAtUtc => dateTime().nullable()();
  DateTimeColumn get endedAtUtc => dateTime().nullable()();
  IntColumn get accumulatedSeconds => integer()();
  IntColumn get activeSlot => integer().nullable().unique()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (source IN ('timer', 'manual'))",
    "CHECK (state IN ('running', 'paused', 'stopped'))",
    'CHECK (accumulated_seconds >= 0)',
    'CHECK (active_slot IS NULL OR active_slot = 1)',
    'CHECK (ended_at_utc IS NULL OR ended_at_utc > started_at_utc)',
    'CHECK (updated_at_utc >= created_at_utc)',
    "CHECK ((state = 'running' AND source = 'timer' "
        'AND last_resumed_at_utc IS NOT NULL AND ended_at_utc IS NULL '
        'AND active_slot = 1) OR '
        "(state = 'paused' AND source = 'timer' "
        'AND last_resumed_at_utc IS NULL AND ended_at_utc IS NULL '
        'AND active_slot = 1) OR '
        "(state = 'stopped' AND last_resumed_at_utc IS NULL "
        'AND ended_at_utc IS NOT NULL AND active_slot IS NULL '
        'AND accumulated_seconds > 0))',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class TaskTemplateRows extends Table {
  @override
  String get tableName => 'task_templates';

  TextColumn get id => text()();
  TextColumn get templateKind => text()();
  TextColumn get systemKey => text().nullable().unique()();
  TextColumn get templateName => text()();
  TextColumn get initialTaskTitle => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  TextColumn get reminderDefaultsJson => text()();
  TextColumn get recurrenceDefaultJson => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (template_kind IN ('system', 'custom'))",
    'CHECK (length(trim(template_name)) > 0)',
    "CHECK ((template_kind = 'system' AND system_key IS NOT NULL "
        'AND length(trim(system_key)) > 0) OR '
        "(template_kind = 'custom' AND system_key IS NULL))",
    'CHECK (priority BETWEEN 0 AND 3)',
    'CHECK (estimated_duration_minutes IS NULL '
        'OR estimated_duration_minutes > 0)',
    'CHECK (display_order >= 0)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{templateKind, displayOrder},
  ];
}

class LegacyImportRows extends Table {
  @override
  String get tableName => 'legacy_imports';

  TextColumn get sourceKind => text().named('source_kind')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get v1Id => text().named('v1_id')();
  TextColumn get v2Id => text().named('v2_id')();
  DateTimeColumn get importedAtUtc => dateTime()();
  TextColumn get sourceSha256 => text().named('source_sha256')();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (entity_type IN ('task', 'transaction', 'debt', 'installment'))",
    "CHECK (source_kind IN ('data_json', 'export'))",
    'CHECK (length(trim(v1_id)) > 0)',
    'CHECK (length(trim(v2_id)) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{entityType, v1Id};
}

class NotificationScheduleRows extends Table {
  @override
  String get tableName => 'notification_schedules';

  TextColumn get scheduleId => text()();
  TextColumn get ownerType => text()();
  TextColumn get ownerId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get scheduledAtUtc => dateTime()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get privacyMode => text().withDefault(const Constant('full'))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (owner_type IN ("
        "'task', 'habit', 'routine', 'challenge', "
        "'installment', 'debt', 'recurringTransaction', 'dailySummary'"
        "))",
    "CHECK (privacy_mode IN ('full', 'private'))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{scheduleId};
}

@DriftDatabase(
  tables: <Type>[
    TaskRows,
    FinanceTransactionRows,
    DebtRows,
    DebtPaymentRows,
    InstallmentPlanRows,
    InstallmentPaymentRows,
    TaskReminderRuleRows,
    TaskRecurrenceRuleRows,
    TaskRecurrenceExceptionRows,
    TaskOccurrenceCompletionRows,
    TaskTimeEntryRows,
    TaskTemplateRows,
    NotificationScheduleRows,
    LegacyImportRows,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDashboardDatabase());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(notificationScheduleRows);
      }
      if (from < 3) {
        await customStatement('ALTER TABLE tasks RENAME TO tasks_v2_legacy');
        await migrator.createTable(taskRows);
        await customStatement('''
          INSERT INTO tasks (
            id,
            display_number,
            title,
            priority,
            status,
            position_in_status,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          )
          SELECT
            id,
            ROW_NUMBER() OVER (
              ORDER BY created_at_utc ASC, id ASC
            ) AS display_number,
            title,
            priority,
            CASE
              WHEN is_done = 1 THEN 'completed'
              ELSE 'planned'
            END AS status,
            ROW_NUMBER() OVER (
              PARTITION BY is_done
              ORDER BY sort_order ASC, created_at_utc ASC, id ASC
            ) - 1 AS position_in_status,
            created_at_utc,
            updated_at_utc,
            CASE
              WHEN is_done = 1
                THEN COALESCE(completed_at_utc, updated_at_utc)
              ELSE NULL
            END AS completed_at_utc,
            NULL AS canceled_at_utc
          FROM tasks_v2_legacy
        ''');
        await customStatement('DROP TABLE tasks_v2_legacy');
      }
      if (from >= 3 && from < 4) {
        await customStatement('ALTER TABLE tasks RENAME TO tasks_v3_legacy');
        await migrator.createTable(taskRows);
        await customStatement('''
          INSERT INTO tasks (
            id,
            display_number,
            title,
            description,
            priority,
            status,
            position_in_status,
            start_at_utc,
            due_at_utc,
            estimated_duration_minutes,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          )
          SELECT
            id,
            display_number,
            title,
            NULL AS description,
            priority,
            status,
            position_in_status,
            NULL AS start_at_utc,
            NULL AS due_at_utc,
            NULL AS estimated_duration_minutes,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          FROM tasks_v3_legacy
        ''');
        await customStatement('DROP TABLE tasks_v3_legacy');
      }
      if (from < 5) {
        await migrator.createTable(taskReminderRuleRows);
      }
      if (from < 6) {
        await migrator.createTable(taskRecurrenceRuleRows);
        await migrator.createTable(taskRecurrenceExceptionRows);
        await migrator.createTable(taskOccurrenceCompletionRows);
      }
      if (from < 7) {
        await migrator.createTable(taskTimeEntryRows);
      }
      if (from < 8) {
        await migrator.createTable(taskTemplateRows);
      }
      if (from < 9) {
        await _migrateToWholeTomanAndLegacyImports(migrator);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static const String _legacyUnit = '100000000';
  static const String _legacyHalf = '50000000';

  /// Integer-only round-half-even of `column / 1e8`, clamping a positive
  /// value that would round to 0 up to 1 (the domain rejects 0 amounts).
  static String _roundToWholeUnits(String column) {
    final whole = '($column / $_legacyUnit)';
    final remainder = '($column % $_legacyUnit)';
    final rounded =
        '($whole + CASE WHEN $remainder > $_legacyHalf '
        'OR ($remainder = $_legacyHalf AND $whole % 2 = 1) '
        'THEN 1 ELSE 0 END)';
    return 'CASE WHEN $column > 0 THEN MAX(1, $rounded) ELSE 0 END';
  }

  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT 1 AS present FROM sqlite_master "
      "WHERE type = 'table' AND name = ?",
      variables: <Variable<Object>>[Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _logRoundedRows(
    String table,
    String column,
    String where,
  ) async {
    final rows = await customSelect(
      'SELECT id FROM $table WHERE $where AND $column % $_legacyUnit != 0',
    ).get();
    for (final row in rows) {
      developer.log(
        'schema 9 rounded $table row ${row.read<String>('id')} to whole toman',
        name: 'dashboard_shakhsi.migration',
      );
    }
  }

  /// Schema 8 -> 9, one step: rescale every scale-8 money row to scale 0 and
  /// create `legacy_imports`. Tables are checked for existence because older
  /// test fixtures seed partial schemas.
  Future<void> _migrateToWholeTomanAndLegacyImports(Migrator migrator) async {
    if (await _tableExists('finance_transactions')) {
      await _logRoundedRows(
        'finance_transactions',
        'amount_minor_units',
        'scale = 8',
      );
      await customStatement(
        'UPDATE finance_transactions SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }

    final hasDebts = await _tableExists('debts');
    final hasDebtPayments = await _tableExists('debt_payments');
    if (hasDebts && hasDebtPayments) {
      // Children first: they are selected through the parent's scale.
      await _logRoundedRows(
        'debt_payments',
        'amount_minor_units',
        'debt_id IN (SELECT id FROM debts WHERE scale = 8)',
      );
      await customStatement(
        'UPDATE debt_payments SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')} '
        'WHERE debt_id IN (SELECT id FROM debts WHERE scale = 8)',
      );
    }
    if (hasDebts) {
      await _logRoundedRows('debts', 'total_minor_units', 'scale = 8');
      await customStatement(
        'UPDATE debts SET '
        'total_minor_units = ${_roundToWholeUnits('total_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }
    if (hasDebts && hasDebtPayments) {
      // Rounding payments and totals separately can leave paid > total.
      // Raise the total to the payment sum so Debt() never throws.
      await customStatement('''
        UPDATE debts SET total_minor_units = (
          SELECT COALESCE(SUM(p.amount_minor_units), 0)
          FROM debt_payments p WHERE p.debt_id = debts.id
        )
        WHERE (
          SELECT COALESCE(SUM(p.amount_minor_units), 0)
          FROM debt_payments p WHERE p.debt_id = debts.id
        ) > total_minor_units
      ''');
    }

    final hasPlans = await _tableExists('installment_plans');
    if (hasPlans && await _tableExists('installment_payments')) {
      await _logRoundedRows(
        'installment_payments',
        'amount_minor_units',
        'plan_id IN (SELECT id FROM installment_plans WHERE scale = 8)',
      );
      await customStatement(
        'UPDATE installment_payments SET '
        'amount_minor_units = ${_roundToWholeUnits('amount_minor_units')} '
        'WHERE plan_id IN '
        '(SELECT id FROM installment_plans WHERE scale = 8)',
      );
    }
    if (hasPlans) {
      await _logRoundedRows(
        'installment_plans',
        'per_installment_minor_units',
        'scale = 8',
      );
      await customStatement(
        'UPDATE installment_plans SET per_installment_minor_units = '
        '${_roundToWholeUnits('per_installment_minor_units')}, '
        'scale = 0 WHERE scale = 8',
      );
    }

    await migrator.createTable(legacyImportRows);
  }
}
