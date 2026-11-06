import 'package:borj/core/database/app_database.dart';
import 'package:borj/features/tasks/data/drift_task_template_repository.dart';
import 'package:borj/features/tasks/data/system_task_template_catalog.dart';
import 'package:borj/features/tasks/data/task_template_synchronizer.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftTaskTemplateRepository repository;
  late TaskTemplateSynchronizer synchronizer;
  final now = DateTime.utc(2026, 8, 8, 3);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftTaskTemplateRepository(database);
    synchronizer = TaskTemplateSynchronizer(
      repository: repository,
      catalog: const SystemTaskTemplateCatalog(),
    );
  });

  tearDown(() => database.close());

  test('first sync inserts built-ins and second sync is idempotent', () async {
    await synchronizer.synchronize(nowUtc: now);

    final first = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    expect(first, hasLength(7));

    await synchronizer.synchronize(nowUtc: now.add(const Duration(hours: 1)));

    final second = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    expect(second, hasLength(7));
    expect(second.map((item) => item.id), first.map((item) => item.id));
  });

  test('normal sync preserves hidden state and user system ordering', () async {
    await synchronizer.synchronize(nowUtc: now);

    final systems = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    final meeting = systems.singleWhere((item) => item.systemKey == 'meeting');

    await repository.setHidden(
      id: meeting.id,
      hidden: true,
      changedAtUtc: now.add(const Duration(minutes: 1)),
    );

    final reversedIds = systems.reversed.map((item) => item.id).toList();
    await repository.reorderKind(
      kind: TaskTemplateKind.system,
      orderedIds: reversedIds,
      changedAtUtc: now.add(const Duration(minutes: 2)),
    );

    await synchronizer.synchronize(nowUtc: now.add(const Duration(hours: 1)));

    final after = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    expect(after.map((item) => item.id), reversedIds);
    expect(
      after.singleWhere((item) => item.systemKey == 'meeting').hidden,
      isTrue,
    );
  });

  test('restore defaults restores system visibility and order', () async {
    await synchronizer.synchronize(nowUtc: now);

    final systems = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    await repository.setHidden(
      id: systems.first.id,
      hidden: true,
      changedAtUtc: now.add(const Duration(minutes: 1)),
    );

    await repository.reorderKind(
      kind: TaskTemplateKind.system,
      orderedIds: systems.reversed.map((item) => item.id).toList(),
      changedAtUtc: now.add(const Duration(minutes: 2)),
    );

    await synchronizer.restoreDefaults(
      nowUtc: now.add(const Duration(hours: 1)),
    );

    final after = (await repository.getAll())
        .where((item) => item.kind == TaskTemplateKind.system)
        .toList();

    expect(after.map((item) => item.systemKey), <String?>[
      'meeting',
      'follow_up',
      'deep_work',
      'daily_work',
      'payment_due',
      'call_message',
      'personal_errand',
    ]);
    expect(after.every((item) => item.hidden == false), isTrue);
  });
}
