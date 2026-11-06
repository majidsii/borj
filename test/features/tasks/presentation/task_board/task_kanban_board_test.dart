import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_board/task_board_operations.dart';
import 'package:borj/features/tasks/presentation/task_board/task_kanban_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tasks = <TaskItem>[
    _task(
      id: 'planned',
      title: 'کار برنامه‌ریزی',
      status: TaskStatus.planned,
      position: 0,
    ),
    _task(
      id: 'working',
      title: 'کار در حال انجام',
      status: TaskStatus.inProgress,
      position: 0,
    ),
    _task(
      id: 'completed',
      title: 'کار انجام‌شده',
      status: TaskStatus.completed,
      position: 0,
    ),
    _task(
      id: 'canceled',
      title: 'کار لغوشده',
      status: TaskStatus.canceled,
      position: 0,
    ),
  ];

  Widget subject({
    double width = 1240,
    Future<void> Function(TaskBoardMoveRequest request)? onMove,
  }) {
    return MaterialApp(
      theme: OriginalTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: width,
            height: 760,
            child: TaskKanbanBoard(
              tasks: tasks,
              allTasks: tasks,
              busyTaskIds: const <String>{},
              onMove: onMove ?? (_) async {},
              onEdit: (_) {},
              onPriority: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
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
    await tester.pump();
  }

  testWidgets('renders four canonical columns including canceled tasks', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pump();

    for (final status in TaskStatus.values) {
      expect(
        find.byKey(
          ValueKey<String>('task-kanban-column-${status.storageValue}'),
        ),
        findsOneWidget,
      );
    }

    expect(find.text('برنامه‌ریزی‌شده'), findsOneWidget);
    expect(find.text('در حال انجام'), findsOneWidget);
    expect(find.text('انجام‌شده'), findsOneWidget);
    expect(find.text('لغوشده'), findsOneWidget);
    expect(find.text('کار برنامه‌ریزی'), findsOneWidget);
    expect(find.text('کار در حال انجام'), findsOneWidget);
    expect(find.text('کار انجام‌شده'), findsOneWidget);
    expect(find.text('کار لغوشده'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is LongPressDraggable),
      findsNWidgets(tasks.length),
    );
  });

  testWidgets('accessible next-status action emits a board move request', (
    tester,
  ) async {
    TaskBoardMoveRequest? captured;
    await tester.pumpWidget(
      subject(
        onMove: (request) async {
          captured = request;
        },
      ),
    );
    await tester.pump();

    await pressSemantic(tester, 'انتقال کار برنامه‌ریزی به وضعیت بعدی');

    expect(captured, isNotNull);
    expect(captured!.taskId, 'planned');
    expect(captured!.targetStatus, TaskStatus.inProgress);
    expect(captured!.targetPosition, 1);
  });

  testWidgets('reorder actions emit final same-column positions', (
    tester,
  ) async {
    final twoPlanned = <TaskItem>[
      _task(id: 'first', title: 'اول', status: TaskStatus.planned, position: 0),
      _task(
        id: 'second',
        title: 'دوم',
        status: TaskStatus.planned,
        position: 1,
      ),
    ];
    TaskBoardMoveRequest? captured;

    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 800,
              height: 700,
              child: TaskKanbanBoard(
                tasks: twoPlanned,
                allTasks: twoPlanned,
                busyTaskIds: const <String>{},
                onMove: (request) async {
                  captured = request;
                },
                onEdit: (_) {},
                onPriority: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await pressSemantic(tester, 'بالا بردن دوم');

    expect(captured, isNotNull);
    expect(captured!.taskId, 'second');
    expect(captured!.targetStatus, TaskStatus.planned);
    expect(captured!.targetPosition, 0);
  });

  testWidgets('filtered reorder maps to complete canonical positions', (
    tester,
  ) async {
    final complete = <TaskItem>[
      _task(
        id: 'hidden',
        title: 'مخفی',
        status: TaskStatus.planned,
        position: 0,
      ),
      _task(
        id: 'visible-a',
        title: 'نمایان اول',
        status: TaskStatus.planned,
        position: 1,
      ),
      _task(
        id: 'visible-b',
        title: 'نمایان دوم',
        status: TaskStatus.planned,
        position: 2,
      ),
    ];
    final visible = complete.sublist(1);
    TaskBoardMoveRequest? captured;

    await tester.pumpWidget(
      MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 800,
              height: 700,
              child: TaskKanbanBoard(
                tasks: visible,
                allTasks: complete,
                busyTaskIds: const <String>{},
                onMove: (request) async {
                  captured = request;
                },
                onEdit: (_) {},
                onPriority: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await pressSemantic(tester, 'پایین بردن نمایان اول');

    expect(captured, isNotNull);
    expect(captured!.taskId, 'visible-a');
    expect(captured!.targetStatus, TaskStatus.planned);
    expect(captured!.targetPosition, 2);
  });

  testWidgets('narrow board remains horizontally scrollable without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(subject(width: 390));
    await tester.pump();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey<String>('task-kanban-horizontal-scroll')),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
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
    displayNumber: position + 1,
    title: title,
    description: 'شرح $title',
    priority: 2,
    status: status,
    positionInStatus: position,
    estimatedDurationMinutes: 45,
    createdAtUtc: now,
    updatedAtUtc: now,
    completedAtUtc: status == TaskStatus.completed ? now : null,
    canceledAtUtc: status == TaskStatus.canceled ? now : null,
  );
}
