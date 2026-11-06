import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:borj/features/tasks/domain/task_time_repository.dart';
import 'package:drift/drift.dart';

final class DriftTaskTimeRepository implements TaskTimeRepository {
  const DriftTaskTimeRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TaskTimeEntry>> watchAll() {
    final query = _database.select(_database.taskTimeEntryRows)
      ..orderBy(<OrderingTerm Function(TaskTimeEntryRows)>[
        (row) => OrderingTerm.desc(row.startedAtUtc),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return query.watch().map(_mapRows);
  }

  @override
  Stream<List<TaskTimeEntry>> watchByTask(String taskId) {
    final query = _database.select(_database.taskTimeEntryRows)
      ..where((row) => row.taskId.equals(taskId))
      ..orderBy(<OrderingTerm Function(TaskTimeEntryRows)>[
        (row) => OrderingTerm.desc(row.startedAtUtc),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return query.watch().map(_mapRows);
  }

  @override
  Stream<TaskTimeEntry?> watchActive() {
    final query = _database.select(_database.taskTimeEntryRows)
      ..where((row) => row.activeSlot.equals(1));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _fromRow(row),
    );
  }

  @override
  Future<List<TaskTimeEntry>> getByTask(String taskId) async {
    final rows = await (_database.select(
      _database.taskTimeEntryRows,
    )..where((row) => row.taskId.equals(taskId))).get();
    final entries = _mapRows(rows);
    entries.sort((a, b) => b.startedAtUtc.compareTo(a.startedAtUtc));
    return entries;
  }

  @override
  Future<TaskTimeEntry?> getById(String id) async {
    final row = await (_database.select(
      _database.taskTimeEntryRows,
    )..where((candidate) => candidate.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<TaskTimeEntry?> getActive() async {
    final row = await (_database.select(
      _database.taskTimeEntryRows,
    )..where((candidate) => candidate.activeSlot.equals(1))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> insert(TaskTimeEntry entry) async {
    try {
      await _database
          .into(_database.taskTimeEntryRows)
          .insert(_companion(entry));
    } on Object catch (error) {
      throw PersistenceFailure(
        entry.isActive
            ? 'هم‌اکنون یک تایمر فعال وجود دارد.'
            : 'ثبت زمان ذخیره نشد.',
        cause: error,
      );
    }
  }

  @override
  Future<void> update(TaskTimeEntry entry) async {
    final affected = await (_database.update(
      _database.taskTimeEntryRows,
    )..where((row) => row.id.equals(entry.id))).write(_companion(entry));
    if (affected != 1) {
      throw const PersistenceFailure('ثبت زمان برای ویرایش پیدا نشد.');
    }
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(
      _database.taskTimeEntryRows,
    )..where((row) => row.id.equals(id))).go();
  }

  List<TaskTimeEntry> _mapRows(List<TaskTimeEntryRow> rows) {
    return rows.map(_fromRow).toList(growable: false);
  }

  TaskTimeEntry _fromRow(TaskTimeEntryRow row) {
    return TaskTimeEntry(
      id: row.id,
      taskId: row.taskId,
      source: TaskTimeEntrySource.parseStorage(row.source),
      state: TaskTimerState.parseStorage(row.state),
      startedAtUtc: row.startedAtUtc.toUtc(),
      lastResumedAtUtc: row.lastResumedAtUtc?.toUtc(),
      endedAtUtc: row.endedAtUtc?.toUtc(),
      accumulatedSeconds: row.accumulatedSeconds,
      activeSlot: row.activeSlot,
      note: row.note,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  TaskTimeEntryRowsCompanion _companion(TaskTimeEntry entry) {
    return TaskTimeEntryRowsCompanion(
      id: Value<String>(entry.id),
      taskId: Value<String>(entry.taskId),
      source: Value<String>(entry.source.storageValue),
      state: Value<String>(entry.state.storageValue),
      startedAtUtc: Value<DateTime>(entry.startedAtUtc),
      lastResumedAtUtc: Value<DateTime?>(entry.lastResumedAtUtc),
      endedAtUtc: Value<DateTime?>(entry.endedAtUtc),
      accumulatedSeconds: Value<int>(entry.accumulatedSeconds),
      activeSlot: Value<int?>(entry.activeSlot),
      note: Value<String?>(entry.note),
      createdAtUtc: Value<DateTime>(entry.createdAtUtc),
      updatedAtUtc: Value<DateTime>(entry.updatedAtUtc),
    );
  }
}
