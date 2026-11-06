import 'package:borj/features/tasks/domain/task_template.dart';

abstract interface class TaskTemplateRepository {
  Stream<List<TaskTemplate>> watchAll();
  Future<List<TaskTemplate>> getAll();
  Future<TaskTemplate?> getById(String id);
  Future<void> createCustom(TaskTemplate template);
  Future<void> updateCustom(TaskTemplate template);
  Future<void> deleteCustom(String id);

  Future<TaskTemplate> duplicateAsCustom({
    required String sourceId,
    required String newId,
    required DateTime savedAtUtc,
  });

  Future<void> setHidden({
    required String id,
    required bool hidden,
    required DateTime changedAtUtc,
  });

  Future<void> reorderKind({
    required TaskTemplateKind kind,
    required List<String> orderedIds,
    required DateTime changedAtUtc,
  });

  Future<void> reconcileSystemCatalog({
    required List<TaskTemplate> canonicalTemplates,
    required DateTime changedAtUtc,
  });

  Future<void> restoreSystemDefaults({
    required List<TaskTemplate> canonicalTemplates,
    required DateTime changedAtUtc,
  });
}
