import 'package:borj/features/tasks/data/system_task_template_catalog.dart';
import 'package:borj/features/tasks/domain/task_template_repository.dart';

final class TaskTemplateSynchronizer {
  const TaskTemplateSynchronizer({
    required this.repository,
    required this.catalog,
  });

  final TaskTemplateRepository repository;
  final SystemTaskTemplateCatalog catalog;

  Future<void> synchronize({required DateTime nowUtc}) {
    return repository.reconcileSystemCatalog(
      canonicalTemplates: catalog.build(nowUtc: nowUtc),
      changedAtUtc: nowUtc,
    );
  }

  Future<void> restoreDefaults({required DateTime nowUtc}) {
    return repository.restoreSystemDefaults(
      canonicalTemplates: catalog.build(nowUtc: nowUtc),
      changedAtUtc: nowUtc,
    );
  }
}
