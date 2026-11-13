import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:flutter/material.dart';

/// Cards per content scope (the renderer caps a layer at 16 shapes).
const int _scopeCards = 16;
const double _liftScale = 1.04;

/// The phone kanban: a status segmented bar, a column header and one column
/// per page. Long-press lifts a card: drop it on a segment to move it to the
/// end of that status, or on a card (or the empty part of the column) to
/// reorder. Every move is also in the card menu. The widget never shows
/// toasts: [onDelete] lets the screen hide the task and offer undo; failed
/// moves go to [onError] (default: reported to Flutter's error log).
class TaskKanbanPhone extends StatefulWidget {
  const TaskKanbanPhone({
    required this.tasks,
    required this.actions,
    required this.onOpen,
    required this.onDelete,
    required this.timeZoneId,
    this.onError,
    super.key,
  });

  /// Already searched.
  final List<TaskItem> tasks;
  final TaskActions actions;
  final void Function(TaskItem task) onOpen;
  final void Function(TaskItem task) onDelete;

  /// Task calendar zone id, for the cards' date.
  final String timeZoneId;
  final void Function(Object error)? onError;

  @override
  State<TaskKanbanPhone> createState() => _TaskKanbanPhoneState();
}

class _TaskKanbanPhoneState extends State<TaskKanbanPhone> {
  final PageController _pages = PageController();
  int _index = 0;
  bool _animating = false;
  bool _dragging = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<TaskItem> _column(TaskStatus status) {
    final list = widget.tasks.where((t) => t.status == status).toList()
      ..sort((a, b) {
        final p = a.positionInStatus.compareTo(b.positionInStatus);
        if (p != 0) return p;
        final c = a.createdAtUtc.compareTo(b.createdAtUtc);
        return c != 0 ? c : a.id.compareTo(b.id);
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
        library: 'phone kanban',
      ),
    );
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  void _move(TaskItem task, TaskStatus status, int position) {
    unawaited(_guard(() => widget.actions.move(task.id, status, position)));
  }

  void _moveColumn(TaskItem task, int step) {
    final target = task.status.index + step;
    if (target < 0 || target >= TaskStatus.values.length) return;
    final status = TaskStatus.values[target];
    _move(task, status, _column(status).length);
  }

  void _moveRow(TaskItem task, int step) {
    final list = _column(task.status);
    final index = list.indexWhere((t) => t.id == task.id);
    final target = index + step;
    if (index < 0 || target < 0 || target >= list.length) return;
    _move(task, task.status, target);
  }

  void _setDragging(bool value) {
    if (mounted && _dragging != value) setState(() => _dragging = value);
  }

  Future<void> _goTo(int index) async {
    if (index == _index && !_animating) return;
    setState(() => _index = index);
    if (MotionScope.reducedOf(context)) {
      _pages.jumpToPage(index);
      return;
    }
    _animating = true;
    try {
      await _pages.animateToPage(
        index,
        duration: AppMotion.quick.duration,
        curve: AppMotion.quick.curve,
      );
    } finally {
      _animating = false;
    }
  }

  void _showMenu(BuildContext context, TaskItem task) {
    final list = _column(task.status);
    final index = list.indexWhere((t) => t.id == task.id);
    final hasPrevious = task.status.index > 0;
    final hasNext = task.status.index < TaskStatus.values.length - 1;
    final inProgress = task.status == TaskStatus.inProgress;
    final canceled = task.status == TaskStatus.canceled;
    final items = <(String, VoidCallback, bool)>[
      ('ویرایش', () => widget.onOpen(task), false),
      (
        'اولویت',
        () => unawaited(_guard(() => widget.actions.cyclePriority(task))),
        false,
      ),
      (
        inProgress ? 'برنامه‌ریزی‌شده' : 'در حال انجام',
        () => unawaited(
          _guard(
            () => widget.actions.setStatus(
              task,
              inProgress ? TaskStatus.planned : TaskStatus.inProgress,
            ),
          ),
        ),
        false,
      ),
      (
        canceled ? 'بازگردانی' : 'لغو کار',
        () => unawaited(
          _guard(
            () => widget.actions.setStatus(
              task,
              canceled ? TaskStatus.planned : TaskStatus.canceled,
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
    final status = TaskStatus.values[_index];
    final count = _column(status).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBar(
          selected: _index,
          counts: [for (final s in TaskStatus.values) _column(s).length],
          onSelect: (i) => unawaited(_goTo(i)),
          onDrop: (task, s) => _move(task, s, _column(s).length),
        ),
        const SizedBox(height: AppSpacing.s12),
        _ColumnHeader(status: status, index: _index, count: count),
        const SizedBox(height: AppSpacing.s8),
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: TaskStatus.values.length,
                onPageChanged: (i) {
                  if (!_animating && i != _index) setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final s = TaskStatus.values[i];
                  final tasks = _column(s);
                  return _ColumnPage(
                    key: ValueKey('kanban-page-${s.name}'),
                    status: s,
                    tasks: tasks,
                    timeZoneId: widget.timeZoneId,
                    onOpen: widget.onOpen,
                    onMove: _move,
                    onMenu: _showMenu,
                    onDragging: _setDragging,
                  );
                },
              ),
              if (_dragging)
                const PositionedDirectional(
                  start: AppSpacing.s16,
                  end: AppSpacing.s16,
                  bottom: AppSpacing.s8,
                  child: IgnorePointer(child: _DropHint()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

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

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.selected,
    required this.counts,
    required this.onSelect,
    required this.onDrop,
  });

  final int selected;
  final List<int> counts;
  final void Function(int index) onSelect;
  final void Function(TaskItem task, TaskStatus status) onDrop;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        container: true,
        label: 'وضعیت کارها',
        child: AppGlass(
          role: GlassRole.row,
          shape: const AppleGlassShape.rounded(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (var i = 0; i < TaskStatus.values.length; i++)
                  Expanded(
                    child: DragTarget<TaskItem>(
                      key: ValueKey(
                        'kanban-status-${TaskStatus.values[i].name}',
                      ),
                      onAcceptWithDetails: (d) =>
                          onDrop(d.data, TaskStatus.values[i]),
                      builder: (context, candidates, rejected) {
                        final status = TaskStatus.values[i];
                        final label = _labels(status).title;
                        final isSelected = i == selected;
                        final hovered = candidates.isNotEmpty;
                        final number = Money.toPersianDigits('${counts[i]}');
                        final content = ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 50),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  number,
                                  role: AppTextRole.subheadline,
                                  weight: FontWeight.w900,
                                  tabular: true,
                                  maxLines: 1,
                                ),
                                AppText(
                                  label,
                                  role: AppTextRole.caption2,
                                  tone: isSelected
                                      ? AppTextTone.primary
                                      : AppTextTone.secondary,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                        return Pressable(
                          selected: isSelected,
                          semanticLabel: '$label، $number کار',
                          hoverRadius: BorderRadius.circular(AppRadii.inner),
                          onPressed: () => onSelect(i),
                          child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadii.inner,
                              ),
                              border: hovered
                                  ? Border.all(color: colors.accent, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? GlassInner(
                                    shape: const AppleGlassShape.rounded(
                                      AppRadii.inner,
                                    ),
                                    child: content,
                                  )
                                : content,
                          ),
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

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.status,
    required this.index,
    required this.count,
  });

  final TaskStatus status;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Row(
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
          Flexible(
            child: AppText(
              _labels(status).title,
              key: const ValueKey('kanban-column-title'),
              role: AppTextRole.headline,
              weight: FontWeight.w900,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppText(
            Money.toPersianDigits('$count کار'),
            role: AppTextRole.caption,
            tabular: true,
            tone: AppTextTone.secondary,
            maxLines: 1,
          ),
          const Spacer(),
          AppText(
            Money.toPersianDigits(
              'ستون ${index + 1} از ${TaskStatus.values.length}',
            ),
            key: const ValueKey('kanban-column-position'),
            role: AppTextRole.caption,
            tabular: true,
            tone: AppTextTone.secondary,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ColumnPage extends StatelessWidget {
  const _ColumnPage({
    required this.status,
    required this.tasks,
    required this.timeZoneId,
    required this.onOpen,
    required this.onMove,
    required this.onMenu,
    required this.onDragging,
    super.key,
  });

  final TaskStatus status;
  final List<TaskItem> tasks;
  final String timeZoneId;
  final void Function(TaskItem task) onOpen;
  final void Function(TaskItem task, TaskStatus status, int position) onMove;
  final void Function(BuildContext context, TaskItem task) onMenu;
  final void Function(bool dragging) onDragging;

  @override
  Widget build(BuildContext context) {
    final chunks = (tasks.length + _scopeCards - 1) ~/ _scopeCards;
    return DragTarget<TaskItem>(
      onAcceptWithDetails: (d) => onMove(d.data, status, tasks.length),
      builder: (context, candidates, rejected) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: AppText(
                _labels(status).empty,
                role: AppTextRole.callout,
                tone: AppTextTone.tertiary,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s4,
            AppSpacing.s16,
            AppSpacing.s24 * 3,
          ),
          itemCount: chunks,
          itemBuilder: (context, chunk) {
            final start = chunk * _scopeCards;
            final end = (start + _scopeCards).clamp(0, tasks.length);
            return GlassScope(
              kind: GlassLayerKind.content,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < end; i++)
                    _CardSlot(
                      key: ValueKey('kanban-slot-${tasks[i].id}'),
                      task: tasks[i],
                      index: i,
                      timeZoneId: timeZoneId,
                      onOpen: onOpen,
                      onMove: onMove,
                      onMenu: onMenu,
                      onDragging: onDragging,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CardSlot extends StatefulWidget {
  const _CardSlot({
    required this.task,
    required this.index,
    required this.timeZoneId,
    required this.onOpen,
    required this.onMove,
    required this.onMenu,
    required this.onDragging,
    super.key,
  });

  final TaskItem task;
  final int index;
  final String timeZoneId;
  final void Function(TaskItem task) onOpen;
  final void Function(TaskItem task, TaskStatus status, int position) onMove;
  final void Function(BuildContext context, TaskItem task) onMenu;
  final void Function(bool dragging) onDragging;

  @override
  State<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<_CardSlot> {
  bool _lifted = false;

  void _setLifted(bool value) {
    if (mounted && _lifted != value) setState(() => _lifted = value);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final task = w.task;
    final colors = AppTheme.of(context).colors;
    final when = taskWhenLabel(
      taskListEntryOf(task, w.timeZoneId).localInstant,
      showDate: true,
    );
    final reduced = MotionScope.reducedOf(context);
    return DragTarget<TaskItem>(
      onWillAcceptWithDetails: (d) => d.data.id != task.id,
      onAcceptWithDetails: (d) => w.onMove(d.data, task.status, w.index),
      builder: (context, candidates, rejected) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Column(
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
                  return LongPressDraggable<TaskItem>(
                    data: task,
                    onDragStarted: () {
                      _setLifted(true);
                      w.onDragging(true);
                    },
                    onDragEnd: (_) {
                      _setLifted(false);
                      w.onDragging(false);
                    },
                    // Moving glass costs a capture per frame: the lifted card
                    // is drawn with the fake material.
                    feedback: GlassPreferencesScope(
                      intensity: GlassPreferencesScope.of(context).intensity,
                      reduceTransparency: true,
                      child: SizedBox(
                        key: const ValueKey('kanban-drag-feedback'),
                        width: constraints.maxWidth,
                        child: Material(
                          type: MaterialType.transparency,
                          child: _Lift(
                            reduced: reduced,
                            child: _CardBody(task: task, when: when),
                          ),
                        ),
                      ),
                    ),
                    // Same structure while dragging; only the paint hides.
                    child: Visibility(
                      visible: !_lifted,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onSecondaryTap: () => w.onMenu(context, task),
                        child: _CardBody(
                          key: ValueKey('kanban-card-${task.id}'),
                          task: task,
                          when: when,
                          onOpen: () => w.onOpen(task),
                          onMenu: () => w.onMenu(context, task),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Lift extends StatelessWidget {
  const _Lift({required this.reduced, required this.child});

  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final lifted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.pressShadow,
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
    return reduced ? lifted : Transform.scale(scale: _liftScale, child: lifted);
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.task,
    required this.when,
    this.onOpen,
    this.onMenu,
    super.key,
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
            role: AppTextRole.subheadline,
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
    return AppGlass(
      role: GlassRole.row,
      shape: const AppleGlassShape.rounded(22),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: onOpen == null
                  ? text
                  : Pressable(
                      onPressed: onOpen,
                      semanticLabel: [task.title, ?priorityLabel].join('، '),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: text,
                      ),
                    ),
            ),
            if (onMenu != null)
              Pressable(
                key: ValueKey('kanban-menu-${task.id}'),
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
          ],
        ),
      ),
    );
  }
}

class _DropHint extends StatelessWidget {
  const _DropHint();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return CustomPaint(
      painter: _DashedPainter(colors.accent),
      child: const SizedBox(
        key: ValueKey('kanban-drop-hint'),
        height: 48,
        child: Center(
          child: AppText(
            'نگه دارید و بکشید تا به ستون دیگر بروید',
            role: AppTextRole.caption,
            weight: FontWeight.w700,
            tone: AppTextTone.link,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.inner),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}
