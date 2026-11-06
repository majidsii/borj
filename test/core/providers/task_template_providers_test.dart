import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/task_template_mapper.dart';
import 'package:borj/features/tasks/data/drift_task_template_repository.dart';
import 'package:borj/features/tasks/data/task_template_synchronizer.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = openTestDatabase();
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'template providers use app database and startup syncs built-ins',
    () async {
      expect(
        container.read(taskTemplateRepositoryProvider),
        isA<DriftTaskTemplateRepository>(),
      );
      expect(
        container.read(taskTemplateMapperProvider),
        isA<TaskTemplateMapper>(),
      );
      expect(
        container.read(taskTemplateSynchronizerProvider),
        isA<TaskTemplateSynchronizer>(),
      );

      await container.read(taskTemplateStartupProvider.future);

      final items = await container
          .read(taskTemplateRepositoryProvider)
          .getAll();
      expect(items, hasLength(7));
      expect(
        items.where((item) => item.kind == TaskTemplateKind.system),
        hasLength(7),
      );

      final secondSyncAt = items
          .map((item) => item.updatedAtUtc)
          .reduce((left, right) => left.isAfter(right) ? left : right)
          .add(const Duration(seconds: 1));

      await container
          .read(taskTemplateSynchronizerProvider)
          .synchronize(nowUtc: secondSyncAt);

      final second = await container
          .read(taskTemplateRepositoryProvider)
          .getAll();
      expect(second, hasLength(7));
    },
  );
}
