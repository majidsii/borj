import 'dart:async';

import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_bundle.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_repository.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryTaskRepository repository;
  late _MemoryTaskReminderRepository reminderRepository;
  late _MemoryTaskRecurrenceRepository recurrenceRepository;
  late ProviderContainer container;

  setUp(() {
    repository = _MemoryTaskRepository();
    reminderRepository = _MemoryTaskReminderRepository();
    recurrenceRepository = _MemoryTaskRecurrenceRepository();
    container = ProviderContainer(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(repository),
        taskReminderRepositoryProvider.overrideWithValue(reminderRepository),
        taskRecurrenceRepositoryProvider.overrideWithValue(
          recurrenceRepository,
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 780, height: 900, child: TasksPanel()),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> flushUiAction(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  testWidgets('renders tasks streamed from the repository', (tester) async {
    final now = DateTime.utc(2026, 7, 26, 10);
    repository.seed(<TaskItem>[
      TaskItem(
        id: 'persisted-task',
        displayNumber: 1,
        title: 'تسک ذخیره‌شده',
        priority: 3,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    ]);

    await pumpSubject(tester);

    expect(find.text('تسک ذخیره‌شده'), findsOneWidget);
    expect(find.text('۱ کار باقی مانده · ۱ با اولویت بالا'), findsOneWidget);
    expect(find.text('۱ فعال · ۰ انجام‌شده'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('task-number-1')), findsOneWidget);
  });

  testWidgets('adding a task calls the repository', (tester) async {
    await pumpSubject(tester);

    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'تسک دائمی از رابط کاربری',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await flushUiAction(tester);

    expect(repository.items, hasLength(1));
    expect(repository.items.single.title, 'تسک دائمی از رابط کاربری');
    expect(repository.items.single.sortOrder, 0);
  });

  testWidgets('edit completion and delete actions call the repository', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 11);
    repository.seed(<TaskItem>[
      TaskItem(
        id: 'editable-task',
        displayNumber: 1,
        title: 'عنوان قبلی',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    ]);

    await pumpSubject(tester);

    await tester.tap(find.bySemanticsLabel('ویرایش کار'));
    await flushUiAction(tester);
    await tester.enterText(textFieldWithHint('ویرایش کار'), 'عنوان جدید');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await flushUiAction(tester);

    expect(repository.items.single.title, 'عنوان جدید');

    await tester.tap(find.bySemanticsLabel('علامت به عنوان انجام‌شده'));
    await flushUiAction(tester);

    expect(repository.items.single.isDone, isTrue);
    expect(repository.items.single.completedAtUtc, isNot(equals(null)));

    await tester.tap(find.bySemanticsLabel('حذف کار'));
    await tester.pump(const Duration(milliseconds: 300));
    await flushUiAction(tester);

    expect(repository.items, isEmpty);
  });

  testWidgets(
    'counts planned and in-progress as active and hides canceled tasks',
    (tester) async {
      final now = DateTime.utc(2026, 7, 26, 9);
      repository.seed(<TaskItem>[
        _task(
          id: 'planned',
          displayNumber: 1,
          title: 'برنامه‌ریزی‌شده',
          status: TaskStatus.planned,
          priority: 3,
          position: 0,
          now: now,
        ),
        _task(
          id: 'in-progress',
          displayNumber: 2,
          title: 'در حال انجام',
          status: TaskStatus.inProgress,
          position: 0,
          now: now.add(const Duration(minutes: 1)),
        ),
        _task(
          id: 'completed',
          displayNumber: 3,
          title: 'تکمیل‌شده',
          status: TaskStatus.completed,
          position: 0,
          now: now.add(const Duration(minutes: 2)),
        ),
        _task(
          id: 'canceled',
          displayNumber: 4,
          title: 'لغوشده و مخفی',
          status: TaskStatus.canceled,
          position: 0,
          now: now.add(const Duration(minutes: 3)),
        ),
      ]);

      await pumpSubject(tester);

      expect(find.text('برنامه‌ریزی‌شده'), findsOneWidget);
      expect(find.text('در حال انجام'), findsOneWidget);
      expect(find.text('تکمیل‌شده'), findsOneWidget);
      expect(find.text('لغوشده و مخفی'), findsNothing);
      expect(find.text('۲ فعال · ۱ انجام‌شده'), findsOneWidget);
      expect(find.text('۲ کار باقی مانده · ۱ با اولویت بالا'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('task-number-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('task-number-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('task-number-3')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('task-number-4')), findsNothing);
    },
  );

  testWidgets('add creates planned then moves it to position zero', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 10);
    repository.seed(<TaskItem>[
      _task(
        id: 'existing',
        displayNumber: 1,
        title: 'کار قبلی',
        status: TaskStatus.planned,
        position: 0,
        now: now,
      ),
    ]);

    await pumpSubject(tester);
    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'کار جدید در ابتدای ستون',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await flushUiAction(tester);

    expect(repository.createdTasks, hasLength(1));
    expect(repository.createdTasks.single.status, TaskStatus.planned);
    expect(repository.transitionCalls, hasLength(1));
    expect(repository.transitionCalls.single.status, TaskStatus.planned);
    expect(repository.transitionCalls.single.targetPosition, 0);

    final added = repository.items.singleWhere(
      (item) => item.title == 'کار جدید در ابتدای ستون',
    );
    final existing = repository.items.singleWhere(
      (item) => item.id == 'existing',
    );
    expect(added.positionInStatus, 0);
    expect(existing.positionInStatus, 1);
  });

  testWidgets('in-progress toggles to completed through transition', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 11);
    repository.seed(<TaskItem>[
      _task(
        id: 'working',
        displayNumber: 1,
        title: 'کار جاری',
        status: TaskStatus.inProgress,
        position: 0,
        now: now,
      ),
    ]);

    await pumpSubject(tester);
    await tester.tap(find.bySemanticsLabel('علامت به عنوان انجام‌شده'));
    await flushUiAction(tester);

    expect(repository.transitionCalls.single.status, TaskStatus.completed);
    expect(repository.transitionCalls.single.targetPosition, 0);
    expect(repository.items.single.status, TaskStatus.completed);
  });

  testWidgets('completed toggles back to planned through transition', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 12);
    repository.seed(<TaskItem>[
      _task(
        id: 'done',
        displayNumber: 1,
        title: 'کار تمام‌شده',
        status: TaskStatus.completed,
        position: 0,
        now: now,
      ),
    ]);

    await pumpSubject(tester);
    await tester.tap(find.bySemanticsLabel('علامت به عنوان انجام‌نشده'));
    await flushUiAction(tester);

    expect(repository.transitionCalls.single.status, TaskStatus.planned);
    expect(repository.transitionCalls.single.targetPosition, 0);
    expect(repository.items.single.status, TaskStatus.planned);
  });

  testWidgets('delete completed preserves canceled persisted tasks', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 13);
    repository.seed(<TaskItem>[
      _task(
        id: 'done',
        displayNumber: 1,
        title: 'قابل پاک‌سازی',
        status: TaskStatus.completed,
        position: 0,
        now: now,
      ),
      _task(
        id: 'canceled',
        displayNumber: 2,
        title: 'لغوشده باقی‌مانده',
        status: TaskStatus.canceled,
        position: 0,
        now: now.add(const Duration(minutes: 1)),
      ),
    ]);

    await pumpSubject(tester);
    await tester.tap(find.bySemanticsLabel('پاک کردن انجام‌شده‌ها'));
    await flushUiAction(tester);

    expect(repository.items, hasLength(1));
    expect(repository.items.single.status, TaskStatus.canceled);
    expect(find.text('قابل پاک‌سازی'), findsNothing);
    expect(find.text('لغوشده باقی‌مانده'), findsNothing);
    expect(find.text('هنوز کاری اضافه نکرده‌اید'), findsOneWidget);
  });

  testWidgets('remount reads the current repository state', (tester) async {
    await pumpSubject(tester);

    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'بعد از ساخت دوباره ویجت',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await flushUiAction(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpSubject(tester);

    expect(find.text('بعد از ساخت دوباره ویجت'), findsOneWidget);
  });
}

TaskItem _task({
  required String id,
  required int displayNumber,
  required String title,
  required TaskStatus status,
  required int position,
  required DateTime now,
  int priority = 0,
}) {
  return TaskItem(
    id: id,
    displayNumber: displayNumber,
    title: title,
    priority: priority,
    status: status,
    positionInStatus: position,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}

final class _TransitionCall {
  const _TransitionCall({
    required this.id,
    required this.status,
    required this.targetPosition,
    required this.changedAtUtc,
  });

  final String id;
  final TaskStatus status;
  final int targetPosition;
  final DateTime changedAtUtc;
}

final class _MemoryTaskRepository implements TaskRepository {
  final StreamController<List<TaskItem>> _controller =
      StreamController<List<TaskItem>>.broadcast(sync: true);

  List<TaskItem> _items = <TaskItem>[];
  final List<TaskItem> createdTasks = <TaskItem>[];
  final List<_TransitionCall> transitionCalls = <_TransitionCall>[];

  List<TaskItem> get items => List<TaskItem>.unmodifiable(_items);

  void seed(List<TaskItem> items) {
    _items = List<TaskItem>.from(items);
  }

  void _emit() {
    _items.sort((left, right) {
      final statusOrder = left.status.index.compareTo(right.status.index);
      if (statusOrder != 0) return statusOrder;
      final positionOrder = left.positionInStatus.compareTo(
        right.positionInStatus,
      );
      if (positionOrder != 0) return positionOrder;
      return left.id.compareTo(right.id);
    });
    _controller.add(items);
  }

  @override
  Stream<List<TaskItem>> watchAll() async* {
    yield items;
    yield* _controller.stream;
  }

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) async* {
    List<TaskItem> matching(List<TaskItem> source) =>
        source.where((item) => item.status == status).toList(growable: false);

    yield matching(items);
    yield* _controller.stream.map(matching);
  }

  @override
  Future<TaskItem?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> create(TaskItem task) async {
    createdTasks.add(task);
    final nextDisplayNumber =
        _items.fold<int>(
          0,
          (highest, item) =>
              item.displayNumber > highest ? item.displayNumber : highest,
        ) +
        1;
    final nextPosition = _items
        .where((item) => item.status == task.status)
        .length;

    _items.add(
      TaskItem(
        id: task.id,
        displayNumber: nextDisplayNumber,
        title: task.title,
        priority: task.priority,
        status: task.status,
        positionInStatus: nextPosition,
        createdAtUtc: task.createdAtUtc,
        updatedAtUtc: task.updatedAtUtc,
        completedAtUtc: task.completedAtUtc,
        canceledAtUtc: task.canceledAtUtc,
      ),
    );
    _emit();
  }

  @override
  Future<void> update(TaskItem task) async {
    final index = _items.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _items[index] = task;
    _emit();
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    transitionCalls.add(
      _TransitionCall(
        id: id,
        status: status,
        targetPosition: targetPosition,
        changedAtUtc: changedAtUtc,
      ),
    );
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Task not found: $id');
    }

    final current = _items[index];
    final sourceStatus = current.status;
    final normalizedChangedAt = changedAtUtc.toUtc();
    final remaining = _items.where((item) => item.id != id).toList();

    List<TaskItem> ordered(TaskStatus candidate) {
      final result = remaining
          .where((item) => item.status == candidate)
          .toList(growable: true);
      result.sort(
        (left, right) =>
            left.positionInStatus.compareTo(right.positionInStatus),
      );
      return result;
    }

    TaskItem transitioned;
    switch (status) {
      case TaskStatus.completed:
        transitioned = current.copyWith(
          status: status,
          updatedAtUtc: normalizedChangedAt,
          completedAtUtc: normalizedChangedAt,
          clearCanceledAt: true,
        );
        break;
      case TaskStatus.canceled:
        transitioned = current.copyWith(
          status: status,
          updatedAtUtc: normalizedChangedAt,
          canceledAtUtc: normalizedChangedAt,
          clearCompletedAt: true,
        );
        break;
      case TaskStatus.planned:
      case TaskStatus.inProgress:
        transitioned = current.copyWith(
          status: status,
          updatedAtUtc: normalizedChangedAt,
          clearCompletedAt: true,
          clearCanceledAt: true,
        );
        break;
    }

    final targetItems = ordered(status);
    final clampedPosition = targetPosition < 0
        ? 0
        : targetPosition > targetItems.length
        ? targetItems.length
        : targetPosition;
    targetItems.insert(clampedPosition, transitioned);

    final normalizedTarget = <TaskItem>[
      for (final entry in targetItems.indexed)
        entry.$2.copyWith(positionInStatus: entry.$1),
    ];
    final normalizedSource = sourceStatus == status
        ? const <TaskItem>[]
        : <TaskItem>[
            for (final entry in ordered(sourceStatus).indexed)
              entry.$2.copyWith(positionInStatus: entry.$1),
          ];

    _items = <TaskItem>[
      ...remaining.where(
        (item) => item.status != status && item.status != sourceStatus,
      ),
      ...normalizedSource,
      ...normalizedTarget,
    ];
    _emit();
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) async {
    final current = _items
        .where((item) => item.status == status)
        .toList(growable: false);
    final currentIds = current.map((item) => item.id).toSet();
    final suppliedIds = orderedIds.toSet();

    if (suppliedIds.length != orderedIds.length ||
        orderedIds.length != current.length ||
        !suppliedIds.containsAll(currentIds)) {
      throw StateError('Invalid task reorder inventory.');
    }

    final byId = <String, TaskItem>{for (final item in current) item.id: item};
    final reordered = <TaskItem>[
      for (final entry in orderedIds.indexed)
        byId[entry.$2]!.copyWith(positionInStatus: entry.$1),
    ];

    _items = <TaskItem>[
      ..._items.where((item) => item.status != status),
      ...reordered,
    ];
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    final removed = await getById(id);
    if (removed == null) return;

    _items.removeWhere((item) => item.id == id);
    final remaining =
        _items
            .where((item) => item.status == removed.status)
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.positionInStatus.compareTo(right.positionInStatus),
          );
    final normalized = <TaskItem>[
      for (final entry in remaining.indexed)
        entry.$2.copyWith(positionInStatus: entry.$1),
    ];
    _items = <TaskItem>[
      ..._items.where((item) => item.status != removed.status),
      ...normalized,
    ];
    _emit();
  }

  @override
  Future<void> deleteCompleted() async {
    _items.removeWhere((item) => item.isDone);
    _emit();
  }

  Future<void> close() => _controller.close();
}

final class _MemoryTaskReminderRepository implements TaskReminderRepository {
  final Map<String, List<TaskReminderRule>> _items =
      <String, List<TaskReminderRule>>{};

  @override
  Stream<List<TaskReminderRule>> watchByTask(String taskId) {
    return Stream<List<TaskReminderRule>>.value(
      List<TaskReminderRule>.unmodifiable(
        _items[taskId] ?? const <TaskReminderRule>[],
      ),
    );
  }

  @override
  Future<List<TaskReminderRule>> getByTask(String taskId) async {
    return List<TaskReminderRule>.unmodifiable(
      _items[taskId] ?? const <TaskReminderRule>[],
    );
  }

  @override
  Future<void> replaceForTask(
    String taskId,
    List<TaskReminderRule> expected,
  ) async {
    _items[taskId] = List<TaskReminderRule>.from(expected);
  }

  @override
  Future<void> deleteByTask(String taskId) async {
    _items.remove(taskId);
  }
}

final class _MemoryTaskRecurrenceRepository
    implements TaskRecurrenceRepository {
  @override
  Stream<List<TaskRecurrenceRule>> watchRules() {
    return Stream<List<TaskRecurrenceRule>>.value(const <TaskRecurrenceRule>[]);
  }

  @override
  Stream<List<TaskRecurrenceException>> watchExceptions() {
    return Stream<List<TaskRecurrenceException>>.value(
      const <TaskRecurrenceException>[],
    );
  }

  @override
  Stream<List<TaskOccurrenceCompletion>> watchCompletions() {
    return Stream<List<TaskOccurrenceCompletion>>.value(
      const <TaskOccurrenceCompletion>[],
    );
  }

  @override
  Future<TaskRecurrenceBundle> getByTask(String taskId) async {
    return TaskRecurrenceBundle(taskId: taskId, rule: null);
  }

  @override
  Future<void> replaceRule({
    required String taskId,
    required TaskRecurrenceRule? rule,
  }) async {}

  @override
  Future<void> upsertException(TaskRecurrenceException exception) async {}

  @override
  Future<void> deleteException({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) async {}

  @override
  Future<void> setCompletion(TaskOccurrenceCompletion completion) async {}

  @override
  Future<void> clearCompletion({
    required String taskId,
    required RecurrenceLocalDateTime originalLocalDateTime,
  }) async {}

  @override
  Future<void> clearTask(String taskId) async {}
}
