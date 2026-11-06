import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/data/task_template_codec.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_repository.dart';
import 'package:drift/drift.dart';

final class DriftTaskTemplateRepository implements TaskTemplateRepository {
  const DriftTaskTemplateRepository(
    this._database, {
    this._codec = const TaskTemplateCodec(),
  });

  final AppDatabase _database;
  final TaskTemplateCodec _codec;

  @override
  Stream<List<TaskTemplate>> watchAll() {
    return _database
        .select(_database.taskTemplateRows)
        .watch()
        .map(
          (rows) => _sorted(rows.map(_templateFromRow).toList(growable: false)),
        );
  }

  @override
  Future<List<TaskTemplate>> getAll() async {
    final rows = await _database.select(_database.taskTemplateRows).get();
    return _sorted(rows.map(_templateFromRow).toList(growable: false));
  }

  @override
  Future<TaskTemplate?> getById(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return null;
    final query = _database.select(_database.taskTemplateRows)
      ..where((row) => row.id.equals(normalized));
    final row = await query.getSingleOrNull();
    return row == null ? null : _templateFromRow(row);
  }

  @override
  Future<void> createCustom(TaskTemplate template) async {
    if (template.kind != TaskTemplateKind.custom) {
      throw const ValidationFailure(
        'فقط قالب سفارشی از مسیر ایجاد سفارشی قابل ذخیره است.',
      );
    }

    return _database.transaction(() async {
      final current = await _getKind(TaskTemplateKind.custom);
      final stored = _copy(template, displayOrder: current.length);
      await _database
          .into(_database.taskTemplateRows)
          .insert(_companionFromTemplate(stored));
    });
  }

  @override
  Future<void> updateCustom(TaskTemplate template) {
    if (template.kind != TaskTemplateKind.custom) {
      throw const ValidationFailure('قالب سیستمی قابل ویرایش مستقیم نیست.');
    }

    return _database.transaction(() async {
      final existing = await _requiredById(template.id);
      if (existing.kind != TaskTemplateKind.custom) {
        throw const ValidationFailure('قالب سیستمی قابل ویرایش مستقیم نیست.');
      }

      final stored = TaskTemplate(
        id: existing.id,
        kind: TaskTemplateKind.custom,
        templateName: template.templateName,
        initialTaskTitle: template.initialTaskTitle,
        description: template.description,
        priority: template.priority,
        estimatedDurationMinutes: template.estimatedDurationMinutes,
        reminderDefaults: template.reminderDefaults,
        recurrenceDefault: template.recurrenceDefault,
        hidden: template.hidden,
        displayOrder: existing.displayOrder,
        createdAtUtc: existing.createdAtUtc,
        updatedAtUtc: template.updatedAtUtc,
      );

      await (_database.update(_database.taskTemplateRows)
            ..where((row) => row.id.equals(existing.id)))
          .write(_companionFromTemplate(stored));
    });
  }

  @override
  Future<void> deleteCustom(String id) {
    return _database.transaction(() async {
      final existing = await _requiredById(id);
      if (existing.kind != TaskTemplateKind.custom) {
        throw const ValidationFailure('قالب سیستمی قابل حذف نیست.');
      }

      await (_database.delete(
        _database.taskTemplateRows,
      )..where((row) => row.id.equals(existing.id))).go();

      await _normalizeKindOrder(TaskTemplateKind.custom);
    });
  }

  @override
  Future<TaskTemplate> duplicateAsCustom({
    required String sourceId,
    required String newId,
    required DateTime savedAtUtc,
  }) {
    return _database.transaction(() async {
      final source = await _requiredById(sourceId);
      final customs = await _getKind(TaskTemplateKind.custom);

      final duplicate = TaskTemplate(
        id: newId,
        kind: TaskTemplateKind.custom,
        templateName: source.templateName,
        initialTaskTitle: source.initialTaskTitle,
        description: source.description,
        priority: source.priority,
        estimatedDurationMinutes: source.estimatedDurationMinutes,
        reminderDefaults: source.reminderDefaults,
        recurrenceDefault: source.recurrenceDefault,
        hidden: false,
        displayOrder: customs.length,
        createdAtUtc: savedAtUtc,
        updatedAtUtc: savedAtUtc,
      );

      await _database
          .into(_database.taskTemplateRows)
          .insert(_companionFromTemplate(duplicate));

      return duplicate;
    });
  }

  @override
  Future<void> setHidden({
    required String id,
    required bool hidden,
    required DateTime changedAtUtc,
  }) {
    return _database.transaction(() async {
      final existing = await _requiredById(id);
      final updated = _copy(
        existing,
        hidden: hidden,
        updatedAtUtc: changedAtUtc,
      );

      await (_database.update(_database.taskTemplateRows)
            ..where((row) => row.id.equals(existing.id)))
          .write(_companionFromTemplate(updated));
    });
  }

  @override
  Future<void> reorderKind({
    required TaskTemplateKind kind,
    required List<String> orderedIds,
    required DateTime changedAtUtc,
  }) {
    return _database.transaction(() async {
      final current = await _getKind(kind);
      final currentIds = current.map((item) => item.id).toList(growable: false);

      if (orderedIds.length != currentIds.length ||
          orderedIds.toSet().length != orderedIds.length ||
          orderedIds.toSet().difference(currentIds.toSet()).isNotEmpty ||
          currentIds.toSet().difference(orderedIds.toSet()).isNotEmpty) {
        throw const ValidationFailure(
          'فهرست مرتب‌سازی قالب‌ها ناقص، تکراری یا متعلق به گروه دیگری است.',
        );
      }

      await _writeOrder(
        orderedIds,
        changedAtUtc: changedAtUtc,
        touchUpdatedAt: true,
      );
    });
  }

  @override
  Future<void> reconcileSystemCatalog({
    required List<TaskTemplate> canonicalTemplates,
    required DateTime changedAtUtc,
  }) {
    _validateCanonical(canonicalTemplates);

    return _database.transaction(() async {
      final existing = await _getKind(TaskTemplateKind.system);
      final byKey = <String, TaskTemplate>{
        for (final item in existing) item.systemKey!: item,
      };
      var nextOrder = existing.length;

      for (final canonical in canonicalTemplates) {
        final key = canonical.systemKey!;
        final stored = byKey[key];

        if (stored == null) {
          final inserted = TaskTemplate(
            id: canonical.id,
            kind: TaskTemplateKind.system,
            systemKey: key,
            templateName: canonical.templateName,
            initialTaskTitle: canonical.initialTaskTitle,
            description: canonical.description,
            priority: canonical.priority,
            estimatedDurationMinutes: canonical.estimatedDurationMinutes,
            reminderDefaults: canonical.reminderDefaults,
            recurrenceDefault: canonical.recurrenceDefault,
            hidden: false,
            displayOrder: nextOrder++,
            createdAtUtc: changedAtUtc,
            updatedAtUtc: changedAtUtc,
          );
          await _database
              .into(_database.taskTemplateRows)
              .insert(_companionFromTemplate(inserted));
          continue;
        }

        final refreshed = TaskTemplate(
          id: stored.id,
          kind: TaskTemplateKind.system,
          systemKey: key,
          templateName: canonical.templateName,
          initialTaskTitle: canonical.initialTaskTitle,
          description: canonical.description,
          priority: canonical.priority,
          estimatedDurationMinutes: canonical.estimatedDurationMinutes,
          reminderDefaults: canonical.reminderDefaults,
          recurrenceDefault: canonical.recurrenceDefault,
          hidden: stored.hidden,
          displayOrder: stored.displayOrder,
          createdAtUtc: stored.createdAtUtc,
          updatedAtUtc: changedAtUtc,
        );

        await (_database.update(_database.taskTemplateRows)
              ..where((row) => row.id.equals(stored.id)))
            .write(_companionFromTemplate(refreshed));
      }
    });
  }

  @override
  Future<void> restoreSystemDefaults({
    required List<TaskTemplate> canonicalTemplates,
    required DateTime changedAtUtc,
  }) {
    _validateCanonical(canonicalTemplates);

    return _database.transaction(() async {
      final existing = await _getKind(TaskTemplateKind.system);
      final byKey = <String, TaskTemplate>{
        for (final item in existing) item.systemKey!: item,
      };
      final canonicalKeys = canonicalTemplates
          .map((item) => item.systemKey!)
          .toSet();
      final extras = existing
          .where((item) => !canonicalKeys.contains(item.systemKey))
          .toList(growable: false);

      await _moveToTemporaryOrder(existing.map((item) => item.id).toList());

      var order = 0;
      for (final canonical in canonicalTemplates) {
        final key = canonical.systemKey!;
        final stored = byKey[key];
        final restored = TaskTemplate(
          id: stored?.id ?? canonical.id,
          kind: TaskTemplateKind.system,
          systemKey: key,
          templateName: canonical.templateName,
          initialTaskTitle: canonical.initialTaskTitle,
          description: canonical.description,
          priority: canonical.priority,
          estimatedDurationMinutes: canonical.estimatedDurationMinutes,
          reminderDefaults: canonical.reminderDefaults,
          recurrenceDefault: canonical.recurrenceDefault,
          hidden: false,
          displayOrder: order++,
          createdAtUtc: stored?.createdAtUtc ?? changedAtUtc,
          updatedAtUtc: changedAtUtc,
        );

        if (stored == null) {
          await _database
              .into(_database.taskTemplateRows)
              .insert(_companionFromTemplate(restored));
        } else {
          await (_database.update(_database.taskTemplateRows)
                ..where((row) => row.id.equals(stored.id)))
              .write(_companionFromTemplate(restored));
        }
      }

      for (final extra in extras) {
        final restoredExtra = _copy(
          extra,
          displayOrder: order++,
          updatedAtUtc: changedAtUtc,
        );
        await (_database.update(_database.taskTemplateRows)
              ..where((row) => row.id.equals(extra.id)))
            .write(_companionFromTemplate(restoredExtra));
      }
    });
  }

  Future<TaskTemplate> _requiredById(String id) async {
    final result = await getById(id);
    if (result == null) {
      throw const ValidationFailure('قالب موردنظر پیدا نشد.');
    }
    return result;
  }

  Future<List<TaskTemplate>> _getKind(TaskTemplateKind kind) async {
    final query = _database.select(_database.taskTemplateRows)
      ..where((row) => row.templateKind.equals(kind.name));
    final rows = await query.get();
    final items = rows.map(_templateFromRow).toList(growable: false)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return items;
  }

  Future<void> _normalizeKindOrder(TaskTemplateKind kind) async {
    final items = await _getKind(kind);
    await _writeOrder(
      items.map((item) => item.id).toList(growable: false),
      changedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      touchUpdatedAt: false,
    );
  }

  Future<void> _writeOrder(
    List<String> orderedIds, {
    required DateTime changedAtUtc,
    required bool touchUpdatedAt,
  }) async {
    if (orderedIds.isEmpty) return;

    await _moveToTemporaryOrder(orderedIds);

    for (var index = 0; index < orderedIds.length; index++) {
      await (_database.update(
        _database.taskTemplateRows,
      )..where((row) => row.id.equals(orderedIds[index]))).write(
        TaskTemplateRowsCompanion(
          displayOrder: Value<int>(index),
          updatedAtUtc: touchUpdatedAt
              ? Value<DateTime>(changedAtUtc)
              : const Value<DateTime>.absent(),
        ),
      );
    }
  }

  Future<void> _moveToTemporaryOrder(List<String> ids) async {
    if (ids.isEmpty) return;

    final all = await getAll();
    final maxOrder = all.fold<int>(
      0,
      (value, item) => item.displayOrder > value ? item.displayOrder : value,
    );
    final base = maxOrder + ids.length + 1000;

    for (var index = 0; index < ids.length; index++) {
      await (_database.update(
        _database.taskTemplateRows,
      )..where((row) => row.id.equals(ids[index]))).write(
        TaskTemplateRowsCompanion(displayOrder: Value<int>(base + index)),
      );
    }
  }

  void _validateCanonical(List<TaskTemplate> templates) {
    final keys = <String>{};
    for (final template in templates) {
      if (template.kind != TaskTemplateKind.system ||
          template.systemKey == null ||
          !keys.add(template.systemKey!)) {
        throw const ValidationFailure(
          'کاتالوگ قالب‌های سیستمی نامعتبر یا دارای کلید تکراری است.',
        );
      }
    }
  }

  List<TaskTemplate> _sorted(List<TaskTemplate> items) {
    final output = List<TaskTemplate>.from(items);
    output.sort((a, b) {
      final kindOrder = a.kind.index.compareTo(b.kind.index);
      if (kindOrder != 0) return kindOrder;
      final display = a.displayOrder.compareTo(b.displayOrder);
      if (display != 0) return display;
      return a.id.compareTo(b.id);
    });
    return List<TaskTemplate>.unmodifiable(output);
  }

  TaskTemplate _templateFromRow(TaskTemplateRow row) {
    return TaskTemplate(
      id: row.id,
      kind: _kindFromStorage(row.templateKind),
      systemKey: row.systemKey,
      templateName: row.templateName,
      initialTaskTitle: row.initialTaskTitle,
      description: row.description,
      priority: row.priority,
      estimatedDurationMinutes: row.estimatedDurationMinutes,
      reminderDefaults: _codec.decodeReminderDefaults(row.reminderDefaultsJson),
      recurrenceDefault: _codec.decodeRecurrenceDefault(
        row.recurrenceDefaultJson,
      ),
      hidden: row.hidden,
      displayOrder: row.displayOrder,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  TaskTemplateRowsCompanion _companionFromTemplate(TaskTemplate template) {
    return TaskTemplateRowsCompanion(
      id: Value<String>(template.id),
      templateKind: Value<String>(template.kind.name),
      systemKey: Value<String?>(template.systemKey),
      templateName: Value<String>(template.templateName),
      initialTaskTitle: Value<String>(template.initialTaskTitle),
      description: Value<String?>(template.description),
      priority: Value<int>(template.priority),
      estimatedDurationMinutes: Value<int?>(template.estimatedDurationMinutes),
      reminderDefaultsJson: Value<String>(
        _codec.encodeReminderDefaults(template.reminderDefaults),
      ),
      recurrenceDefaultJson: Value<String?>(
        _codec.encodeRecurrenceDefault(template.recurrenceDefault),
      ),
      hidden: Value<bool>(template.hidden),
      displayOrder: Value<int>(template.displayOrder),
      createdAtUtc: Value<DateTime>(template.createdAtUtc),
      updatedAtUtc: Value<DateTime>(template.updatedAtUtc),
    );
  }

  TaskTemplateKind _kindFromStorage(String value) {
    for (final kind in TaskTemplateKind.values) {
      if (kind.name == value) return kind;
    }
    throw StateError('Unknown stored task template kind: $value');
  }

  TaskTemplate _copy(
    TaskTemplate source, {
    int? displayOrder,
    bool? hidden,
    DateTime? updatedAtUtc,
  }) {
    return TaskTemplate(
      id: source.id,
      kind: source.kind,
      systemKey: source.systemKey,
      templateName: source.templateName,
      initialTaskTitle: source.initialTaskTitle,
      description: source.description,
      priority: source.priority,
      estimatedDurationMinutes: source.estimatedDurationMinutes,
      reminderDefaults: source.reminderDefaults,
      recurrenceDefault: source.recurrenceDefault,
      hidden: hidden ?? source.hidden,
      displayOrder: displayOrder ?? source.displayOrder,
      createdAtUtc: source.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? source.updatedAtUtc,
    );
  }
}
