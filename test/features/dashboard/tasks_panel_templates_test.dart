import 'dart:async';

import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/tasks/data/drift_task_template_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late DriftTaskTemplateRepository templateRepository;
  late _MemoryTaskRepository taskRepository;

  setUp(() async {
    database = openTestDatabase();
    templateRepository = DriftTaskTemplateRepository(database);
    taskRepository = _MemoryTaskRepository();

    await templateRepository.createCustom(
      TaskTemplate(
        id: 'picker-template',
        kind: TaskTemplateKind.custom,
        templateName: 'قالب آماده',
        initialTaskTitle: 'عنوان از قالب',
        description: 'شرح از قالب',
        priority: 2,
        estimatedDurationMinutes: 40,
        hidden: false,
        displayOrder: 0,
        createdAtUtc: DateTime.utc(2026, 8, 8, 8),
        updatedAtUtc: DateTime.utc(2026, 8, 8, 8),
      ),
    );

    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await taskRepository.close();
    await database.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 820, height: 940, child: TasksPanel()),
          ),
        ),
      ),
    );
  }

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  Future<void> pressPrimary(WidgetTester tester, String label) async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is OriginalPrimaryButton && widget.label == label,
    );
    expect(finder, findsOneWidget);
    final button = tester.widget<OriginalPrimaryButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await pumpUi(tester);
  }

  testWidgets('picker opens task details and does not persist on selection', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await pumpUi(tester);

    expect(find.bySemanticsLabel('انتخاب قالب کار'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('انتخاب قالب کار'));
    await pumpUi(tester);
    expect(find.text('قالب آماده'), findsOneWidget);

    await tester.tap(find.text('قالب آماده'));
    await pumpUi(tester);

    // Selection alone must not persist a task.
    expect(taskRepository.items, isEmpty);

    final title = tester.widget<TextField>(textFieldWithHint('عنوان کار'));
    expect(title.controller!.text, 'عنوان از قالب');
    expect(find.text('افزودن کار با جزئیات'), findsOneWidget);

    await tester.tap(find.text('انصراف'));
    await pumpUi(tester);
    expect(taskRepository.items, isEmpty);

    await tester.tap(find.bySemanticsLabel('انتخاب قالب کار'));
    await pumpUi(tester);
    await tester.tap(find.text('قالب آماده'));
    await pumpUi(tester);
    await pressPrimary(tester, 'افزودن کار');

    expect(taskRepository.items, hasLength(1));
    final task = taskRepository.items.single;
    expect(task.title, 'عنوان از قالب');
    expect(task.description, 'شرح از قالب');
    expect(task.priority, 2);
    expect(task.estimatedDurationMinutes, 40);
  });

  testWidgets('edit save-as-template persists a new custom template', (
    tester,
  ) async {
    taskRepository.seed(
      TaskItem(
        id: 'source-task',
        displayNumber: 1,
        title: 'قالب از کار موجود',
        description: 'شرح منبع',
        priority: 3,
        status: TaskStatus.planned,
        positionInStatus: 0,
        estimatedDurationMinutes: 70,
        createdAtUtc: DateTime.utc(2026, 8, 7),
        updatedAtUtc: DateTime.utc(2026, 8, 7),
      ),
    );

    await tester.pumpWidget(subject());
    await pumpUi(tester);

    await tester.tap(find.bySemanticsLabel('ویرایش کار'));
    await pumpUi(tester);

    final saveTemplate = find.byWidgetPredicate(
      (widget) =>
          widget is OriginalGhostButton &&
          widget.label == 'ذخیره به‌عنوان قالب',
    );
    expect(saveTemplate, findsOneWidget);
    tester.widget<OriginalGhostButton>(saveTemplate).onPressed!();
    await pumpUi(tester);

    expect(find.text('نام قالب'), findsOneWidget);
    await tester.tap(find.text('ذخیره قالب'));
    await pumpUi(tester);

    final templates = await templateRepository.getAll();
    final custom = templates
        .where(
          (item) =>
              item.kind == TaskTemplateKind.custom &&
              item.id != 'picker-template',
        )
        .toList();

    expect(custom, hasLength(1));
    expect(custom.single.templateName, 'قالب از کار موجود');
    expect(custom.single.initialTaskTitle, 'قالب از کار موجود');
    expect(custom.single.description, 'شرح منبع');
    expect(custom.single.estimatedDurationMinutes, 70);

    // Save-as-template must not mutate the source task or close its editor.
    expect(taskRepository.items, hasLength(1));
    expect(taskRepository.items.single.title, 'قالب از کار موجود');
    expect(find.text('ویرایش کار'), findsWidgets);
  });
}

final class _MemoryTaskRepository implements TaskRepository {
  final List<TaskItem> items = <TaskItem>[];
  final StreamController<List<TaskItem>> _changes =
      StreamController<List<TaskItem>>.broadcast();

  void seed(TaskItem task) {
    items
      ..clear()
      ..add(task);
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(List<TaskItem>.unmodifiable(items));
    }
  }

  Future<void> close() => _changes.close();

  @override
  Stream<List<TaskItem>> watchAll() async* {
    yield List<TaskItem>.unmodifiable(items);
    yield* _changes.stream;
  }

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    return watchAll().map(
      (all) => all.where((item) => item.status == status).toList(),
    );
  }

  @override
  Future<TaskItem?> getById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> create(TaskItem task) async {
    items.add(task);
    _emit();
  }

  @override
  Future<void> update(TaskItem task) async {
    final index = items.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      throw StateError('Missing task ${task.id}');
    }
    items[index] = task;
    _emit();
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Task not found: $id');
    }

    final current = items[index];
    final normalizedChangedAt = changedAtUtc.toUtc();

    late final TaskItem transitioned;
    switch (status) {
      case TaskStatus.completed:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: targetPosition,
          updatedAtUtc: normalizedChangedAt,
          completedAtUtc: normalizedChangedAt,
          clearCanceledAt: true,
        );
        break;
      case TaskStatus.canceled:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: targetPosition,
          updatedAtUtc: normalizedChangedAt,
          canceledAtUtc: normalizedChangedAt,
          clearCompletedAt: true,
        );
        break;
      case TaskStatus.planned:
      case TaskStatus.inProgress:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: targetPosition,
          updatedAtUtc: normalizedChangedAt,
          clearCompletedAt: true,
          clearCanceledAt: true,
        );
        break;
    }

    items[index] = transitioned;
    _emit();
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<void> deleteCompleted() async {
    items.removeWhere((item) => item.status == TaskStatus.completed);
    _emit();
  }
}
