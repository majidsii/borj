// Task 2.2 Heavy UI RED
import 'dart:async';

import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
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
import 'package:borj/features/tasks/presentation/task_details/task_planning_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  Finder renderedText(String value) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == value,
    );
  }

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
    await Future<void>.delayed(Duration.zero);
    await repository.dispose();
  });

  Widget subject({double width = 780}) {
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

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Finder textFieldInsideSemantics(String label) {
    return find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byType(TextField),
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    int maxPumps = 20,
  }) async {
    for (var index = 0; index < maxPumps; index++) {
      if (condition()) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(condition(), isTrue, reason: 'UI did not reach expected state.');
  }

  Future<void> pressOriginal(WidgetTester tester, Finder finder) async {
    final direct = tester
        .widgetList<Widget>(finder)
        .whereType<OriginalPressable>()
        .toList(growable: false);

    OriginalPressable pressable;
    if (direct.length == 1) {
      pressable = direct.single;
    } else {
      final ancestor = find.ancestor(
        of: finder,
        matching: find.byType(OriginalPressable),
      );
      expect(ancestor, findsOneWidget);
      pressable = tester.widget<OriginalPressable>(ancestor);
    }

    expect(pressable.onPressed, isNotNull);
    pressable.onPressed!();
    await pumpUi(tester);
  }

  Future<void> pressBySemantics(WidgetTester tester, String label) {
    return pressOriginal(tester, find.bySemanticsLabel(label));
  }

  Future<void> pressPrimaryButton(WidgetTester tester, String label) async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is OriginalPrimaryButton && widget.label == label,
    );
    expect(finder, findsOneWidget);
    final button = tester.widget<OriginalPrimaryButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await pumpUi(tester);
  }

  testWidgets('add with details persists fields and renders metadata', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await pumpUi(tester);

    await pressBySemantics(tester, 'افزودن با جزئیات');

    await tester.enterText(textFieldWithHint('عنوان کار'), 'کار برنامه‌ریزی');
    await tester.enterText(
      textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      'شرح برنامه‌ریزی',
    );
    await tester.enterText(textFieldInsideSemantics('ساعت مدت تخمینی'), '1');
    await tester.enterText(textFieldInsideSemantics('دقیقه مدت تخمینی'), '30');
    await pressPrimaryButton(tester, 'افزودن کار');

    await pumpUntil(
      tester,
      () =>
          repository.items.length == 1 &&
          find
              .byWidgetPredicate(
                (widget) => widget is Text && widget.data == 'کار برنامه‌ریزی',
              )
              .evaluate()
              .isNotEmpty,
    );

    final task = repository.items.single;
    expect(task.title, 'کار برنامه‌ریزی');
    expect(task.description, 'شرح برنامه‌ریزی');
    expect(task.estimatedDurationMinutes, 90);
    expect(task.status, TaskStatus.planned);
    expect(task.positionInStatus, 0);
    expect(task.displayNumber, 1);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'کار برنامه‌ریزی',
      ),
      findsOneWidget,
    );
    expect(renderedText('شرح برنامه‌ریزی'), findsOneWidget);
    expect(renderedText('تخمین: ۱ ساعت و ۳۰ دقیقه'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('full edit clears optional fields and keeps workflow identity', (
    tester,
  ) async {
    final startLocal = Jalali(
      1405,
      5,
      13,
    ).toDateTime().copyWith(hour: 11, minute: 30);
    final task = TaskItem(
      id: 'edit-task',
      displayNumber: 1,
      title: 'کار موجود',
      description: 'شرح موجود',
      priority: 2,
      status: TaskStatus.inProgress,
      positionInStatus: 0,
      startAtUtc: startLocal.toUtc(),
      dueAtUtc: startLocal.copyWith(hour: 15, minute: 0).toUtc(),
      estimatedDurationMinutes: 90,
      createdAtUtc: DateTime.utc(2026, 8, 1, 8),
      updatedAtUtc: DateTime.utc(2026, 8, 1, 9),
    );
    repository.seed(<TaskItem>[task]);

    await tester.pumpWidget(subject());
    await pumpUi(tester);

    expect(find.text(taskStartLabel(task)!), findsOneWidget);
    expect(find.text(taskDueLabel(task)!), findsOneWidget);
    expect(find.text(taskEstimatedDurationLabel(task)!), findsOneWidget);

    await pressBySemantics(tester, 'ویرایش کار');

    await tester.enterText(
      textFieldWithHint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      '',
    );
    await pressBySemantics(tester, 'پاک کردن زمان شروع');
    await pressBySemantics(tester, 'پاک کردن زمان سررسید');
    await pressBySemantics(tester, 'پاک کردن مدت تخمینی');
    await pressPrimaryButton(tester, 'ذخیره تغییرات');

    await pumpUntil(tester, () {
      final updated = repository.itemById(task.id);
      return updated != null &&
          updated.description == null &&
          updated.startAtUtc == null &&
          updated.dueAtUtc == null &&
          updated.estimatedDurationMinutes == null;
    });

    final updated = repository.itemById(task.id);
    expect(updated, isNotNull);
    expect(updated!.id, task.id);
    expect(updated.displayNumber, task.displayNumber);
    expect(updated.createdAtUtc, task.createdAtUtc);
    expect(updated.status, task.status);
    expect(updated.positionInStatus, task.positionInStatus);
    expect(updated.description, isNull);
    expect(updated.startAtUtc, isNull);
    expect(updated.dueAtUtc, isNull);
    expect(updated.estimatedDurationMinutes, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'narrow panel keeps quick add and detailed action without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(subject(width: 390));
      await pumpUi(tester);

      expect(find.bySemanticsLabel('افزودن با جزئیات'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

final class _MemoryTaskRepository implements TaskRepository {
  final StreamController<List<TaskItem>> _controller =
      StreamController<List<TaskItem>>.broadcast(sync: true);

  List<TaskItem> _items = <TaskItem>[];

  List<TaskItem> get items => List<TaskItem>.unmodifiable(_items);

  TaskItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void seed(List<TaskItem> items) {
    _items = List<TaskItem>.from(items);
  }

  Future<void> dispose() => _controller.close();

  void _emit() {
    _items.sort((left, right) {
      final statusOrder = left.status.index.compareTo(right.status.index);
      if (statusOrder != 0) return statusOrder;
      final positionOrder = left.positionInStatus.compareTo(
        right.positionInStatus,
      );
      if (positionOrder != 0) return positionOrder;
      return left.displayNumber.compareTo(right.displayNumber);
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
    List<TaskItem> matching(List<TaskItem> source) {
      return source
          .where((item) => item.status == status)
          .toList(growable: false);
    }

    yield matching(items);
    yield* _controller.stream.map(matching);
  }

  @override
  Future<TaskItem?> getById(String id) async => itemById(id);

  @override
  Future<void> create(TaskItem task) async {
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
        description: task.description,
        priority: task.priority,
        status: task.status,
        positionInStatus: nextPosition,
        startAtUtc: task.startAtUtc,
        dueAtUtc: task.dueAtUtc,
        estimatedDurationMinutes: task.estimatedDurationMinutes,
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
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Task not found: $id');
    }

    final current = _items[index];
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

    _items[index] = transitioned;
    _emit();
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) async {
    for (var index = 0; index < orderedIds.length; index++) {
      final itemIndex = _items.indexWhere(
        (item) => item.id == orderedIds[index] && item.status == status,
      );
      if (itemIndex == -1) continue;
      _items[itemIndex] = _items[itemIndex].copyWith(positionInStatus: index);
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<void> deleteCompleted() async {
    _items.removeWhere((item) => item.status == TaskStatus.completed);
    _emit();
  }
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
