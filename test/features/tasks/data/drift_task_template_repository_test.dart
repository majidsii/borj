import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/data/drift_task_template_repository.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftTaskTemplateRepository repository;
  final baseTime = DateTime.utc(2026, 8, 8, 1);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftTaskTemplateRepository(database);
  });

  tearDown(() => database.close());

  TaskTemplate custom({
    required String id,
    String name = 'قالب سفارشی',
    int displayOrder = 99,
  }) {
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.custom,
      templateName: name,
      initialTaskTitle: 'کار …',
      priority: 1,
      estimatedDurationMinutes: 30,
      hidden: false,
      displayOrder: displayOrder,
      createdAtUtc: baseTime,
      updatedAtUtc: baseTime,
    );
  }

  TaskTemplate system({
    required String id,
    required String key,
    required int displayOrder,
  }) {
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.system,
      systemKey: key,
      templateName: 'سیستمی',
      initialTaskTitle: 'کار سیستمی …',
      priority: 2,
      estimatedDurationMinutes: 20,
      hidden: false,
      displayOrder: displayOrder,
      createdAtUtc: baseTime,
      updatedAtUtc: baseTime,
    );
  }

  test('creates custom templates at the end of custom ordering', () async {
    await repository.createCustom(custom(id: 'c1', displayOrder: 40));
    await repository.createCustom(custom(id: 'c2', displayOrder: 0));

    final items = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.custom)
        .toList();

    expect(items.map((item) => item.id), <String>['c1', 'c2']);
    expect(items.map((item) => item.displayOrder), <int>[0, 1]);
  });

  test('rejects system templates through custom create path', () async {
    await expectLater(
      repository.createCustom(
        system(id: 's1', key: 'meeting', displayOrder: 0),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(await repository.getAll(), isEmpty);
  });

  test('deletes custom templates and compacts custom order', () async {
    for (final id in <String>['c1', 'c2', 'c3']) {
      await repository.createCustom(custom(id: id));
    }

    await repository.deleteCustom('c2');

    final items = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.custom)
        .toList();

    expect(items.map((item) => item.id), <String>['c1', 'c3']);
    expect(items.map((item) => item.displayOrder), <int>[0, 1]);
  });

  test('duplicates system templates as independent custom rows', () async {
    await repository.reconcileSystemCatalog(
      canonicalTemplates: <TaskTemplate>[
        system(id: 's1', key: 'meeting', displayOrder: 0),
      ],
      changedAtUtc: baseTime,
    );

    final copy = await repository.duplicateAsCustom(
      sourceId: 's1',
      newId: 'copy-system',
      savedAtUtc: baseTime.add(const Duration(minutes: 1)),
    );

    expect(copy.kind, TaskTemplateKind.custom);
    expect(copy.systemKey, isNull);
    expect(copy.hidden, isFalse);
    expect(copy.displayOrder, 0);
  });

  test('hides and restores system templates', () async {
    await repository.reconcileSystemCatalog(
      canonicalTemplates: <TaskTemplate>[
        system(id: 's1', key: 'meeting', displayOrder: 0),
      ],
      changedAtUtc: baseTime,
    );

    await repository.setHidden(
      id: 's1',
      hidden: true,
      changedAtUtc: baseTime.add(const Duration(minutes: 1)),
    );
    expect((await repository.getById('s1'))!.hidden, isTrue);

    await repository.setHidden(
      id: 's1',
      hidden: false,
      changedAtUtc: baseTime.add(const Duration(minutes: 2)),
    );
    expect((await repository.getById('s1'))!.hidden, isFalse);
  });

  test('reorders one kind atomically', () async {
    for (final id in <String>['c1', 'c2', 'c3']) {
      await repository.createCustom(custom(id: id));
    }

    await repository.reorderKind(
      kind: TaskTemplateKind.custom,
      orderedIds: const <String>['c3', 'c1', 'c2'],
      changedAtUtc: baseTime.add(const Duration(hours: 1)),
    );

    final items = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.custom)
        .toList();

    expect(items.map((item) => item.id), <String>['c3', 'c1', 'c2']);
    expect(items.map((item) => item.displayOrder), <int>[0, 1, 2]);
  });

  test('invalid reorder inputs fail without partial writes', () async {
    for (final id in <String>['c1', 'c2', 'c3']) {
      await repository.createCustom(custom(id: id));
    }
    await repository.reconcileSystemCatalog(
      canonicalTemplates: <TaskTemplate>[
        system(id: 's1', key: 'one', displayOrder: 0),
      ],
      changedAtUtc: baseTime,
    );

    final before = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.custom)
        .map((item) => '${item.id}:${item.displayOrder}')
        .toList();

    for (final invalid in <List<String>>[
      <String>['c1', 'c2'],
      <String>['c1', 'c1', 'c3'],
      <String>['c1', 'c2', 's1'],
    ]) {
      await expectLater(
        repository.reorderKind(
          kind: TaskTemplateKind.custom,
          orderedIds: invalid,
          changedAtUtc: baseTime.add(const Duration(hours: 2)),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final after = (await repository.getAll())
          .where((item) => item.kind == TaskTemplateKind.custom)
          .map((item) => '${item.id}:${item.displayOrder}')
          .toList();

      expect(after, before);
    }
  });
}
