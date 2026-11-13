import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _minColumnWidth = 260;
const double _columnGap = 12;

/// The desktop kanban: four flex columns (one content scope and one panel
/// each) with flat cards. Needs a bounded height. Below four minimum-width
/// columns the board scrolls horizontally.
///
/// Mouse drag moves a card between and within columns; a focused card moves
/// with the arrow keys (toward the next status column, up and down) and opens
/// with Enter. The widget never shows toasts: [onDelete] lets the screen
/// hide the task and offer undo.
/// Failed moves go to [onError] (default: reported to Flutter's error log).
class TaskKanbanDesktop extends StatefulWidget {
  const TaskKanbanDesktop({
    required this.tasks,
    required this.actions,
    required this.onOpen,
    required this.onDelete,
    required this.timeZoneId,
    this.onError,
    super.key,
  });

  final List<TaskItem> tasks;
  final TaskActions actions;
  final void Function(TaskItem task) onOpen;
  final void Function(TaskItem task) onDelete;

  /// Task calendar zone id, for the cards' date/time.
  final String timeZoneId;
  final void Function(Object error)? onError;

  @override
  State<TaskKanbanDesktop> createState() => _TaskKanbanDesktopState();
}

class _TaskKanbanDesktopState extends State<TaskKanbanDesktop> {
  final Map<String, FocusNode> _nodes = {};
  String? _refocusId;

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskKanbanDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = {for (final t in widget.tasks) t.id};
    final gone = _nodes.keys.where((id) => !ids.contains(id)).toList();
    for (final id in gone) {
      final node = _nodes.remove(id)!;
      // Disposed after the frame: its Focus widget is still mounted now.
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    final refocus = _refocusId;
    if (refocus != null && widget.tasks != oldWidget.tasks) {
      _refocusId = null;
      final node = _nodes[refocus];
      if (node != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && node.context != null) node.requestFocus();
        });
      }
    }
  }

  FocusNode _nodeOf(String id) =>
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'kanban-card-$id'));

  List<TaskItem> _column(TaskStatus status) {
    final list = widget.tasks.where((t) => t.status == status).toList()
      ..sort((a, b) {
        final p = a.positionInStatus.compareTo(b.positionInStatus);
        return p != 0 ? p : a.displayNumber.compareTo(b.displayNumber);
      });
    return list;
  }

  void _fail(Object error, StackTrace stack) {
    final handler = widget.onError;
    if (handler != null) {
      handler(error);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'task kanban',
      ),
    );
  }

  Future<void> _guard(Future<void> Function() op, {String? refocusId}) async {
    if (refocusId != null) _refocusId = refocusId;
    try {
      await op();
    } catch (error, stack) {
      if (_refocusId == refocusId) _refocusId = null;
      _fail(error, stack);
    }
  }

  void _move(
    TaskItem task,
    TaskStatus status,
    int position, {
    bool refocus = false,
  }) {
    unawaited(
      _guard(
        () => widget.actions.move(task.id, status, position),
        refocusId: refocus ? task.id : null,
      ),
    );
  }

  /// Moves [task] to the neighbouring status ([step] -1 or 1), keeping its
  /// index where possible.
  void _moveColumn(TaskItem task, int step, {bool refocus = false}) {
    final target = task.status.index + step;
    if (target < 0 || target >= TaskStatus.values.length) return;
    final status = TaskStatus.values[target];
    final index = _column(task.status).indexWhere((t) => t.id == task.id);
    final count = _column(status).length;
    _move(task, status, index < count ? index : count, refocus: refocus);
  }

  void _moveRow(TaskItem task, int step, {bool refocus = false}) {
    final list = _column(task.status);
    final index = list.indexWhere((t) => t.id == task.id);
    final target = index + step;
    if (index < 0 || target < 0 || target >= list.length) return;
    _move(task, task.status, target, refocus: refocus);
  }

  KeyEventResult _onKey(TaskItem task, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) widget.onOpen(task);
      return KeyEventResult.handled;
    }
    final toNext = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final toPrevious = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == toNext) {
      _moveColumn(task, 1, refocus: true);
    } else if (key == toPrevious) {
      _moveColumn(task, -1, refocus: true);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveRow(task, 1, refocus: true);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveRow(task, -1, refocus: true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _showMenu(BuildContext context, TaskItem task) {
    final list = _column(task.status);
    final index = list.indexWhere((t) => t.id == task.id);
    final hasPrevious = task.status.index > 0;
    final hasNext = task.status.index < TaskStatus.values.length - 1;
    final items = <(String, VoidCallback, bool)>[
      ('ویرایش', () => widget.onOpen(task), false),
      (
        'اولویت',
        () => unawaited(_guard(() => widget.actions.cyclePriority(task))),
        false,
      ),
      (
        task.status == TaskStatus.inProgress
            ? 'برنامه‌ریزی‌شده'
            : 'در حال انجام',
        () => unawaited(
          _guard(
            () => widget.actions.setStatus(
              task,
              task.status == TaskStatus.inProgress
                  ? TaskStatus.planned
                  : TaskStatus.inProgress,
            ),
          ),
        ),
        false,
      ),
      (
        task.status == TaskStatus.canceled ? 'بازگردانی' : 'لغو کار',
        () => unawaited(
          _guard(
            () => widget.actions.setStatus(
              task,
              task.status == TaskStatus.canceled
                  ? TaskStatus.planned
                  : TaskStatus.canceled,
            ),
          ),
        ),
        false,
      ),
      if (hasPrevious)
        ('انتقال به ستون قبلی', () => _moveColumn(task, -1), false),
      if (hasNext) ('انتقال به ستون بعدی', () => _moveColumn(task, 1), false),
      if (index > 0) ('بالا', () => _moveRow(task, -1), false),
      if (index >= 0 && index < list.length - 1)
        ('پایین', () => _moveRow(task, 1), false),
      ('حذف', () => widget.onDelete(task), true),
    ];
    unawaited(
      showGlassSheet<void>(
        context,
        semanticLabel: 'گزینه‌های کار',
        builder: (sheet) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                Pressable(
                  onPressed: () {
                    GlassSheet.close(sheet);
                    item.$2();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppText(
                          item.$1,
                          tone: item.$3
                              ? AppTextTone.danger
                              : AppTextTone.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const needed = 4 * _minColumnWidth + 3 * _columnGap;
        final scrolls = constraints.maxWidth < needed;
        final children = <Widget>[];
        for (final status in TaskStatus.values) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(width: _columnGap));
          }
          final column = _KanbanColumn(
            status: status,
            tasks: _column(status),
            timeZoneId: widget.timeZoneId,
            nodeOf: _nodeOf,
            onKey: _onKey,
            onOpen: widget.onOpen,
            onMove: _move,
            onMenu: _showMenu,
          );
          children.add(
            scrolls
                ? SizedBox(width: _minColumnWidth, child: column)
                : Expanded(child: column),
          );
        }
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
        if (!scrolls) return row;
        return SingleChildScrollView(
          key: const ValueKey('kanban-horizontal-scroll'),
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }
}

typedef _MoveFn =
    void Function(
      TaskItem task,
      TaskStatus status,
      int position, {
      bool refocus,
    });

({String title, String empty}) _labels(TaskStatus status) => switch (status) {
  TaskStatus.planned => (
    title: 'برنامه‌ریزی‌شده',
    empty: 'کاری برای برنامه‌ریزی وجود ندارد.',
  ),
  TaskStatus.inProgress => (
    title: 'در حال انجام',
    empty: 'کاری در حال انجام نیست.',
  ),
  TaskStatus.completed => (title: 'انجام‌شده', empty: 'کاری انجام نشده است.'),
  TaskStatus.canceled => (title: 'لغوشده', empty: 'کاری لغو نشده است.'),
};

Color _dotColor(AppColors c, TaskStatus status) => switch (status) {
  TaskStatus.planned => c.accent,
  TaskStatus.inProgress => c.warn,
  TaskStatus.completed => c.teal,
  TaskStatus.canceled => c.textSecondary,
};

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.timeZoneId,
    required this.nodeOf,
    required this.onKey,
    required this.onOpen,
    required this.onMove,
    required this.onMenu,
  });

  final TaskStatus status;
  final List<TaskItem> tasks;
  final String timeZoneId;
  final FocusNode Function(String id) nodeOf;
  final KeyEventResult Function(TaskItem task, KeyEvent event) onKey;
  final void Function(TaskItem task) onOpen;
  final _MoveFn onMove;
  final void Function(BuildContext context, TaskItem task) onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final labels = _labels(status);
    return GlassScope(
      kind: GlassLayerKind.content,
      child: AppGlass(
        role: GlassRole.panel,
        shape: const AppleGlassShape.rounded(AppRadii.card),
        child: KeyedSubtree(
          key: ValueKey('kanban-column-${status.name}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _dotColor(colors, status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: AppText(
                        labels.title,
                        role: AppTextRole.headline,
                        weight: FontWeight.w900,
                        maxLines: 1,
                      ),
                    ),
                    AppText(
                      Money.toPersianDigits('${tasks.length} کار'),
                      key: ValueKey('kanban-count-${status.name}'),
                      role: AppTextRole.caption,
                      tabular: true,
                      tone: AppTextTone.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Expanded(
                  child: DragTarget<TaskItem>(
                    onWillAcceptWithDetails: (d) =>
                        d.data.status != status ||
                        tasks.isEmpty ||
                        tasks.last.id != d.data.id,
                    onAcceptWithDetails: (d) =>
                        onMove(d.data, status, tasks.length),
                    builder: (context, candidates, rejected) {
                      if (tasks.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            child: AppText(
                              labels.empty,
                              role: AppTextRole.caption,
                              tone: AppTextTone.tertiary,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _CardSlot(
                            key: ValueKey('kanban-slot-${task.id}'),
                            task: task,
                            index: index,
                            when: taskWhenLabel(
                              taskListEntryOf(task, timeZoneId).localInstant,
                              showDate: true,
                            ),
                            focusNode: nodeOf(task.id),
                            onKey: onKey,
                            onOpen: onOpen,
                            onMove: onMove,
                            onMenu: onMenu,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSlot extends StatefulWidget {
  const _CardSlot({
    required this.task,
    required this.index,
    required this.when,
    required this.focusNode,
    required this.onKey,
    required this.onOpen,
    required this.onMove,
    required this.onMenu,
    super.key,
  });

  final TaskItem task;
  final int index;
  final String? when;
  final FocusNode focusNode;
  final KeyEventResult Function(TaskItem task, KeyEvent event) onKey;
  final void Function(TaskItem task) onOpen;
  final _MoveFn onMove;
  final void Function(BuildContext context, TaskItem task) onMenu;

  @override
  State<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<_CardSlot> {
  bool _dragging = false;

  void _setDragging(bool value) {
    if (mounted && _dragging != value) setState(() => _dragging = value);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final index = widget.index;
    final focusNode = widget.focusNode;
    final onKey = widget.onKey;
    final onOpen = widget.onOpen;
    final onMove = widget.onMove;
    final onMenu = widget.onMenu;
    final colors = AppTheme.of(context).colors;
    return DragTarget<TaskItem>(
      onWillAcceptWithDetails: (d) => d.data.id != task.id,
      onAcceptWithDetails: (d) => onMove(d.data, task.status, index),
      builder: (context, candidates, rejected) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (candidates.isNotEmpty)
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final body = _CardBody(
                  task: task,
                  when: widget.when,
                  onOpen: () => onOpen(task),
                  onMenu: () => onMenu(context, task),
                );
                return Focus(
                  focusNode: focusNode,
                  onKeyEvent: (_, event) => onKey(task, event),
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onSecondaryTap: () => onMenu(context, task),
                    child: ListenableBuilder(
                      listenable: focusNode,
                      builder: (context, child) => DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.inner),
                          border: focusNode.hasFocus
                              ? Border.all(color: colors.accent, width: 2)
                              : null,
                        ),
                        child: child,
                      ),
                      child: Draggable<TaskItem>(
                        data: task,
                        feedback: SizedBox(
                          width: constraints.maxWidth,
                          child: Material(
                            type: MaterialType.transparency,
                            child: _CardBody(task: task, when: widget.when),
                          ),
                        ),
                        onDragStarted: () => _setDragging(true),
                        onDragEnd: (_) => _setDragging(false),
                        // The child keeps its structure while dragging (a
                        // swapped child would dispose the pressed Pressable).
                        child: Opacity(
                          opacity: _dragging ? 0.35 : 1,
                          child: body,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.task,
    required this.when,
    this.onOpen,
    this.onMenu,
  });

  final TaskItem task;
  final String? when;
  final VoidCallback? onOpen;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final done =
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.canceled;
    final (priorityLabel, priorityTone) = switch (task.priority) {
      1 => ('اولویت پایین', AppTextTone.secondary),
      2 => ('اولویت متوسط', AppTextTone.warn),
      3 => ('اولویت بالا', AppTextTone.danger),
      _ => (null, AppTextTone.secondary),
    };
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            task.title,
            weight: FontWeight.w800,
            maxLines: 3,
            tone: done ? AppTextTone.tertiary : AppTextTone.primary,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
          if (when != null || priorityLabel != null)
            Wrap(
              spacing: AppSpacing.s8,
              children: [
                if (when != null)
                  AppText(
                    when!,
                    role: AppTextRole.caption,
                    tabular: true,
                    tone: AppTextTone.secondary,
                  ),
                if (priorityLabel != null)
                  AppText(
                    priorityLabel,
                    role: AppTextRole.caption,
                    tone: priorityTone,
                  ),
              ],
            ),
        ],
      ),
    );
    return GlassInner(
      shape: const AppleGlassShape.rounded(AppRadii.inner),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: onOpen == null
                  ? text
                  : ExcludeFocus(
                      child: Pressable(
                        onPressed: onOpen,
                        semanticLabel: [task.title, ?priorityLabel].join('، '),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: text,
                        ),
                      ),
                    ),
            ),
            if (onMenu != null)
              ExcludeFocus(
                child: Pressable(
                  key: ValueKey('kanban-menu-${task.title}'),
                  onPressed: onMenu,
                  semanticLabel: 'گزینه‌های کار',
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AppIcon(
                        Icons.more_horiz,
                        size: 20,
                        tone: AppTextTone.secondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
