import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:drift/drift.dart';

final class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TaskItem>> watchAll() {
    return _database.select(_database.taskRows).watch().map((rows) {
      final items = rows.map(_taskFromRow).toList(growable: false)
        ..sort(_compareTasks);
      return items;
    });
  }

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    final query = _database.select(_database.taskRows)
      ..where((row) => row.status.equals(status.storageValue))
      ..orderBy(<OrderingTerm Function(TaskRows)>[
        (row) => OrderingTerm.asc(row.positionInStatus),
        (row) => OrderingTerm.asc(row.createdAtUtc),
        (row) => OrderingTerm.asc(row.id),
      ]);

    return query.watch().map(
      (rows) => rows.map(_taskFromRow).toList(growable: false),
    );
  }

  @override
  Future<TaskItem?> getById(String id) async {
    final row = await (_database.select(
      _database.taskRows,
    )..where((candidate) => candidate.id.equals(id))).getSingleOrNull();

    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<void> create(TaskItem task) {
    return _database.transaction(() async {
      final allocation = await _database
          .customSelect(
            '''
          SELECT
            COALESCE(MAX(display_number), 0) + 1 AS next_display_number,
            (
              SELECT COUNT(*)
              FROM tasks
              WHERE status = ?
            ) AS next_position
          FROM tasks
        ''',
            variables: <Variable<Object>>[
              Variable<String>(task.status.storageValue),
            ],
            readsFrom: {_database.taskRows},
          )
          .getSingle();

      final nextDisplayNumber = allocation.read<int>('next_display_number');
      final nextPosition = allocation.read<int>('next_position');

      await _database
          .into(_database.taskRows)
          .insert(
            _companionFromTask(
              task,
              displayNumber: nextDisplayNumber,
              positionInStatus: nextPosition,
            ),
          );
    });
  }

  @override
  Future<void> update(TaskItem task) async {
    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(task.id))).write(
      TaskRowsCompanion(
        title: Value<String>(task.title),
        description: Value<String?>(task.description),
        priority: Value<int>(task.priority),
        status: Value<String>(task.status.storageValue),
        positionInStatus: Value<int>(task.positionInStatus),
        startAtUtc: Value<DateTime?>(task.startAtUtc),
        dueAtUtc: Value<DateTime?>(task.dueAtUtc),
        estimatedDurationMinutes: Value<int?>(task.estimatedDurationMinutes),
        updatedAtUtc: Value<DateTime>(task.updatedAtUtc),
        completedAtUtc: Value<DateTime?>(task.completedAtUtc),
        canceledAtUtc: Value<DateTime?>(task.canceledAtUtc),
      ),
    );
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) {
    return _database.transaction(() async {
      final current = await (_database.select(
        _database.taskRows,
      )..where((row) => row.id.equals(id))).getSingleOrNull();

      if (current == null) {
        throw const ValidationFailure('کار موردنظر پیدا نشد.');
      }

      final sourceStatus = TaskStatus.parseStorage(current.status);
      final normalizedChangedAt = changedAtUtc.toUtc();

      if (sourceStatus == status) {
        final sameStatusRows = await _orderedRowsForStatus(status);
        final remainingIds = sameStatusRows
            .where((row) => row.id != id)
            .map((row) => row.id)
            .toList(growable: true);
        final clampedPosition = _clampPosition(
          targetPosition,
          remainingIds.length,
        );
        remainingIds.insert(clampedPosition, id);

        await _writePositionsWithTemporaryOffset(remainingIds);
        await _writeTransitionedTask(
          current: current,
          status: status,
          positionInStatus: clampedPosition,
          changedAtUtc: normalizedChangedAt,
        );
        return;
      }

      final sourceIds = (await _orderedRowsForStatus(sourceStatus))
          .where((row) => row.id != id)
          .map((row) => row.id)
          .toList(growable: false);
      final targetIds = (await _orderedRowsForStatus(
        status,
      )).map((row) => row.id).toList(growable: true);
      final clampedPosition = _clampPosition(targetPosition, targetIds.length);
      targetIds.insert(clampedPosition, id);

      await _writePositionsWithTemporaryOffset(sourceIds);
      await _writePositionsWithTemporaryOffset(targetIds);
      await _writeTransitionedTask(
        current: current,
        status: status,
        positionInStatus: clampedPosition,
        changedAtUtc: normalizedChangedAt,
      );
    });
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) {
    return _database.transaction(() async {
      final rows = await _orderedRowsForStatus(status);
      final currentIds = rows.map((row) => row.id).toList(growable: false);
      final suppliedIds = orderedIds.toSet();

      if (suppliedIds.length != orderedIds.length ||
          orderedIds.length != currentIds.length ||
          !suppliedIds.containsAll(currentIds)) {
        throw const ValidationFailure(
          'فهرست مرتب‌سازی کارها کامل و معتبر نیست.',
        );
      }

      await _writePositionsWithTemporaryOffset(orderedIds);
    });
  }

  @override
  Future<void> delete(String id) {
    return _database.transaction(() async {
      final current = await (_database.select(
        _database.taskRows,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (current == null) {
        return;
      }

      final status = TaskStatus.parseStorage(current.status);
      await (_database.delete(
        _database.taskRows,
      )..where((row) => row.id.equals(id))).go();

      final remainingIds = (await _orderedRowsForStatus(
        status,
      )).map((row) => row.id).toList(growable: false);
      await _writePositionsWithTemporaryOffset(remainingIds);
    });
  }

  @override
  Future<void> deleteCompleted() async {
    await (_database.delete(
          _database.taskRows,
        )..where((row) => row.status.equals(TaskStatus.completed.storageValue)))
        .go();
  }

  Future<List<TaskRow>> _orderedRowsForStatus(TaskStatus status) {
    final query = _database.select(_database.taskRows)
      ..where((row) => row.status.equals(status.storageValue))
      ..orderBy(<OrderingTerm Function(TaskRows)>[
        (row) => OrderingTerm.asc(row.positionInStatus),
        (row) => OrderingTerm.asc(row.createdAtUtc),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.get();
  }

  Future<void> _writePositionsWithTemporaryOffset(
    List<String> orderedIds,
  ) async {
    if (orderedIds.isEmpty) {
      return;
    }

    final temporaryOffset = 1000000 + orderedIds.length;
    for (var index = 0; index < orderedIds.length; index++) {
      await (_database.update(
        _database.taskRows,
      )..where((row) => row.id.equals(orderedIds[index]))).write(
        TaskRowsCompanion(
          positionInStatus: Value<int>(temporaryOffset + index),
        ),
      );
    }

    for (var index = 0; index < orderedIds.length; index++) {
      await (_database.update(_database.taskRows)
            ..where((row) => row.id.equals(orderedIds[index])))
          .write(TaskRowsCompanion(positionInStatus: Value<int>(index)));
    }
  }

  Future<void> _writeTransitionedTask({
    required TaskRow current,
    required TaskStatus status,
    required int positionInStatus,
    required DateTime changedAtUtc,
  }) async {
    final completedAtUtc = status == TaskStatus.completed ? changedAtUtc : null;
    final canceledAtUtc = status == TaskStatus.canceled ? changedAtUtc : null;

    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(current.id))).write(
      TaskRowsCompanion(
        status: Value<String>(status.storageValue),
        positionInStatus: Value<int>(positionInStatus),
        updatedAtUtc: Value<DateTime>(changedAtUtc),
        completedAtUtc: Value<DateTime?>(completedAtUtc),
        canceledAtUtc: Value<DateTime?>(canceledAtUtc),
      ),
    );
  }
}

TaskItem _taskFromRow(TaskRow row) {
  return TaskItem(
    id: row.id,
    displayNumber: row.displayNumber,
    title: row.title,
    description: row.description,
    priority: row.priority,
    status: TaskStatus.parseStorage(row.status),
    positionInStatus: row.positionInStatus,
    startAtUtc: row.startAtUtc?.toUtc(),
    dueAtUtc: row.dueAtUtc?.toUtc(),
    estimatedDurationMinutes: row.estimatedDurationMinutes,
    createdAtUtc: row.createdAtUtc.toUtc(),
    updatedAtUtc: row.updatedAtUtc.toUtc(),
    completedAtUtc: row.completedAtUtc?.toUtc(),
    canceledAtUtc: row.canceledAtUtc?.toUtc(),
  );
}

TaskRowsCompanion _companionFromTask(
  TaskItem task, {
  int? displayNumber,
  int? positionInStatus,
}) {
  return TaskRowsCompanion(
    id: Value<String>(task.id),
    displayNumber: Value<int>(displayNumber ?? task.displayNumber),
    title: Value<String>(task.title),
    description: Value<String?>(task.description),
    priority: Value<int>(task.priority),
    status: Value<String>(task.status.storageValue),
    positionInStatus: Value<int>(positionInStatus ?? task.positionInStatus),
    startAtUtc: Value<DateTime?>(task.startAtUtc),
    dueAtUtc: Value<DateTime?>(task.dueAtUtc),
    estimatedDurationMinutes: Value<int?>(task.estimatedDurationMinutes),
    createdAtUtc: Value<DateTime>(task.createdAtUtc),
    updatedAtUtc: Value<DateTime>(task.updatedAtUtc),
    completedAtUtc: Value<DateTime?>(task.completedAtUtc),
    canceledAtUtc: Value<DateTime?>(task.canceledAtUtc),
  );
}

int _compareTasks(TaskItem left, TaskItem right) {
  final statusOrder = left.status.index.compareTo(right.status.index);
  if (statusOrder != 0) {
    return statusOrder;
  }

  final positionOrder = left.positionInStatus.compareTo(right.positionInStatus);
  if (positionOrder != 0) {
    return positionOrder;
  }

  final createdAtOrder = left.createdAtUtc.compareTo(right.createdAtUtc);
  if (createdAtOrder != 0) {
    return createdAtOrder;
  }

  return left.id.compareTo(right.id);
}

int _clampPosition(int requested, int maximum) {
  if (requested < 0) {
    return 0;
  }
  if (requested > maximum) {
    return maximum;
  }
  return requested;
}
