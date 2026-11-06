import 'dart:async';

import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _BoardMemoryTaskRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _BoardMemoryTaskRepository(<TaskItem>[
      _task(
        id: 'planned',
        title: 'برنامه برد',
        status: TaskStatus.planned,
        position: 0,
      ),
      _task(
        id: 'working',
        title: 'اجرای برد',
        status: TaskStatus.inProgress,
        position: 0,
      ),
      _task(
        id: 'done',
        title: 'پایان برد',
        status: TaskStatus.completed,
        position: 0,
      ),
      _task(
        id: 'canceled',
        title: 'لغو برد',
        status: TaskStatus.canceled,
        position: 0,
      ),
    ]);
    container = ProviderContainer(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  Widget subject({double width = 900}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: width,
              height: 920,
              child: const TasksPanel(),
            ),
          ),
        ),
      ),
    );
  }

  Finder renderedText(String value) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == value,
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pressSemantic(WidgetTester tester, String label) async {
    final semantics = find.bySemanticsLabel(label);
    expect(semantics, findsOneWidget);
    final pressableFinder = find.ancestor(
      of: semantics,
      matching: find.byType(OriginalPressable),
    );
    expect(pressableFinder, findsOneWidget);
    final pressable = tester.widget<OriginalPressable>(pressableFinder);
    expect(pressable.onPressed, isNotNull);
    pressable.onPressed!();
    await pumpUi(tester);
  }

  testWidgets('list stays default and kanban reveals all four statuses', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await pumpUi(tester);

    expect(renderedText('برنامه برد'), findsOneWidget);
    expect(renderedText('اجرای برد'), findsOneWidget);
    expect(renderedText('پایان برد'), findsOneWidget);
    expect(renderedText('لغو برد'), findsNothing);
    expect(find.bySemanticsLabel('فهرست'), findsOneWidget);
    expect(find.bySemanticsLabel('کانبان'), findsOneWidget);

    await pressSemantic(tester, 'کانبان');

    expect(
      find.byKey(const ValueKey<String>('task-kanban-column-planned')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-kanban-column-inProgress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-kanban-column-completed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-kanban-column-canceled')),
      findsOneWidget,
    );
    expect(renderedText('لغو برد'), findsOneWidget);
  });

  testWidgets('kanban move action uses repository atomic transition', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await pumpUi(tester);
    await pressSemantic(tester, 'کانبان');

    await pressSemantic(tester, 'انتقال برنامه برد به وضعیت بعدی');

    expect(repository.transitionCalls, hasLength(1));
    expect(repository.transitionCalls.single.id, 'planned');
    expect(repository.transitionCalls.single.status, TaskStatus.inProgress);
    expect(repository.itemById('planned')!.status, TaskStatus.inProgress);
    expect(repository.itemById('planned')!.positionInStatus, 1);
  });

  testWidgets('switching back keeps quick add and detailed create available', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await pumpUi(tester);
    await pressSemantic(tester, 'کانبان');
    await pressSemantic(tester, 'فهرست');

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'یک کار جدید بنویسید…',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('افزودن با جزئیات'), findsOneWidget);
    expect(renderedText('لغو برد'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

TaskItem _task({
  required String id,
  required String title,
  required TaskStatus status,
  required int position,
}) {
  final now = DateTime.utc(2026, 8, 4, 8).add(Duration(minutes: position));
  return TaskItem(
    id: id,
    displayNumber: TaskStatus.values.indexOf(status) + 1,
    title: title,
    priority: 1,
    status: status,
    positionInStatus: position,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}

final class _BoardMemoryTaskRepository implements TaskRepository {
  _BoardMemoryTaskRepository(List<TaskItem> items)
    : _items = List<TaskItem>.from(items);

  final StreamController<List<TaskItem>> _controller =
      StreamController<List<TaskItem>>.broadcast(sync: true);
  final List<TaskItem> _items;
  final List<_TransitionCall> transitionCalls = <_TransitionCall>[];

  TaskItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> dispose() => _controller.close();

  void _normalizeAndEmit() {
    for (final status in TaskStatus.values) {
      final statusItems =
          _items.where((item) => item.status == status).toList(growable: false)
            ..sort(
              (left, right) =>
                  left.positionInStatus.compareTo(right.positionInStatus),
            );
      for (var index = 0; index < statusItems.length; index++) {
        final taskIndex = _items.indexWhere(
          (item) => item.id == statusItems[index].id,
        );
        _items[taskIndex] = statusItems[index].copyWith(
          positionInStatus: index,
        );
      }
    }
    _controller.add(List<TaskItem>.unmodifiable(_items));
  }

  @override
  Stream<List<TaskItem>> watchAll() async* {
    yield List<TaskItem>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    return watchAll().map(
      (items) =>
          items.where((item) => item.status == status).toList(growable: false),
    );
  }

  @override
  Future<TaskItem?> getById(String id) async => itemById(id);

  @override
  Future<void> create(TaskItem task) async {
    _items.add(task);
    _normalizeAndEmit();
  }

  @override
  Future<void> update(TaskItem task) async {
    final index = _items.indexWhere((item) => item.id == task.id);
    if (index >= 0) _items[index] = task;
    _normalizeAndEmit();
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Task not found: $id');

    final current = _items[index];
    _items.removeAt(index);

    final targetItems =
        _items.where((item) => item.status == status).toList(growable: false)
          ..sort(
            (left, right) =>
                left.positionInStatus.compareTo(right.positionInStatus),
          );
    final clamped = targetPosition.clamp(0, targetItems.length).toInt();
    final terminal = changedAtUtc.toUtc();

    late final TaskItem transitioned;
    switch (status) {
      case TaskStatus.completed:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: clamped,
          updatedAtUtc: terminal,
          completedAtUtc: terminal,
          clearCanceledAt: true,
        );
        break;
      case TaskStatus.canceled:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: clamped,
          updatedAtUtc: terminal,
          canceledAtUtc: terminal,
          clearCompletedAt: true,
        );
        break;
      case TaskStatus.planned:
      case TaskStatus.inProgress:
        transitioned = current.copyWith(
          status: status,
          positionInStatus: clamped,
          updatedAtUtc: terminal,
          clearCompletedAt: true,
          clearCanceledAt: true,
        );
        break;
    }

    _items.add(transitioned);
    transitionCalls.add(_TransitionCall(id: id, status: status));
    _normalizeAndEmit();
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) async {
    for (var index = 0; index < orderedIds.length; index++) {
      final taskIndex = _items.indexWhere(
        (item) => item.id == orderedIds[index],
      );
      if (taskIndex >= 0) {
        _items[taskIndex] = _items[taskIndex].copyWith(positionInStatus: index);
      }
    }
    _normalizeAndEmit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _normalizeAndEmit();
  }

  @override
  Future<void> deleteCompleted() async {
    _items.removeWhere((item) => item.status == TaskStatus.completed);
    _normalizeAndEmit();
  }
}

final class _TransitionCall {
  const _TransitionCall({required this.id, required this.status});

  final String id;
  final TaskStatus status;
}
