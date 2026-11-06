import 'dart:async';

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_board/task_board_operations.dart';
import 'package:borj/features/tasks/presentation/task_details/task_planning_labels.dart';
import 'package:flutter/material.dart';

final class TaskKanbanBoard extends StatelessWidget {
  const TaskKanbanBoard({
    required this.tasks,
    required this.allTasks,
    required this.busyTaskIds,
    required this.onMove,
    required this.onEdit,
    required this.onPriority,
    required this.onDelete,
    super.key,
  });

  /// Tasks visible after the current search projection.
  final List<TaskItem> tasks;

  /// Complete inventory used to translate visible drop slots to canonical
  /// repository positions.
  final List<TaskItem> allTasks;
  final Set<String> busyTaskIds;
  final Future<void> Function(TaskBoardMoveRequest request) onMove;
  final ValueChanged<TaskItem> onEdit;
  final ValueChanged<TaskItem> onPriority;
  final ValueChanged<TaskItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth < 700 ? 274.0 : 300.0;
        return Semantics(
          container: true,
          label: 'نمای کانبان کارها',
          child: SingleChildScrollView(
            key: const ValueKey<String>('task-kanban-horizontal-scroll'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final status in TaskStatus.values) ...<Widget>[
                  SizedBox(
                    width: columnWidth,
                    child: _KanbanColumn(
                      status: status,
                      tasks: _tasksFor(status),
                      allTasks: allTasks,
                      busyTaskIds: busyTaskIds,
                      onMove: onMove,
                      onEdit: onEdit,
                      onPriority: onPriority,
                      onDelete: onDelete,
                    ),
                  ),
                  if (status != TaskStatus.values.last)
                    const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<TaskItem> _tasksFor(TaskStatus status) {
    final result = tasks
        .where((task) => task.status == status)
        .toList(growable: false);
    result.sort((left, right) {
      final position = left.positionInStatus.compareTo(right.positionInStatus);
      if (position != 0) return position;
      return left.displayNumber.compareTo(right.displayNumber);
    });
    return result;
  }
}

final class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.allTasks,
    required this.busyTaskIds,
    required this.onMove,
    required this.onEdit,
    required this.onPriority,
    required this.onDelete,
  });

  final TaskStatus status;
  final List<TaskItem> tasks;
  final List<TaskItem> allTasks;
  final Set<String> busyTaskIds;
  final Future<void> Function(TaskBoardMoveRequest request) onMove;
  final ValueChanged<TaskItem> onEdit;
  final ValueChanged<TaskItem> onPriority;
  final ValueChanged<TaskItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final visual = _statusVisual(context, status);

    return OriginalGlass(
      radius: OriginalDesignTokens.glassRadius - 4,
      padding: const EdgeInsets.all(12),
      child: Column(
        key: ValueKey<String>('task-kanban-column-${status.storageValue}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: visual.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  visual.label,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(count: tasks.length, color: visual.color),
            ],
          ),
          const SizedBox(height: 11),
          _DropZone(
            status: status,
            keyPosition: 0,
            position: _canonicalDropPosition(0),
            onMove: onMove,
          ),
          if (tasks.isEmpty)
            _EmptyColumn(label: visual.emptyLabel)
          else
            for (var index = 0; index < tasks.length; index++) ...<Widget>[
              _KanbanCard(
                task: tasks[index],
                index: index,
                statusTasks: tasks,
                allTasks: allTasks,
                busy: busyTaskIds.contains(tasks[index].id),
                onMove: onMove,
                onEdit: onEdit,
                onPriority: onPriority,
                onDelete: onDelete,
              ),
              _DropZone(
                status: status,
                keyPosition: index + 1,
                position: _canonicalDropPosition(index + 1),
                onMove: onMove,
              ),
            ],
        ],
      ),
    );
  }

  int _canonicalDropPosition(int visiblePosition) {
    final complete =
        allTasks.where((task) => task.status == status).toList(growable: false)
          ..sort((left, right) {
            final position = left.positionInStatus.compareTo(
              right.positionInStatus,
            );
            if (position != 0) return position;
            return left.displayNumber.compareTo(right.displayNumber);
          });

    if (tasks.isEmpty) return complete.length;
    if (visiblePosition < tasks.length) {
      final targetId = tasks[visiblePosition].id;
      final index = complete.indexWhere((task) => task.id == targetId);
      return index < 0 ? complete.length : index;
    }

    final lastId = tasks.last.id;
    final lastIndex = complete.indexWhere((task) => task.id == lastId);
    return lastIndex < 0 ? complete.length : lastIndex + 1;
  }
}

final class _DropZone extends StatefulWidget {
  const _DropZone({
    required this.status,
    required this.keyPosition,
    required this.position,
    required this.onMove,
  });

  final TaskStatus status;
  final int keyPosition;
  final int position;
  final Future<void> Function(TaskBoardMoveRequest request) onMove;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

final class _DropZoneState extends State<_DropZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return DragTarget<_TaskDragPayload>(
      onWillAcceptWithDetails: (details) {
        final payload = details.data;
        final target = _finalPosition(payload);
        return payload.sourceStatus != widget.status ||
            payload.sourcePosition != target;
      },
      onMove: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onLeave: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      onAcceptWithDetails: (details) {
        if (_hovered) setState(() => _hovered = false);
        unawaited(
          widget.onMove(
            TaskBoardMoveRequest(
              taskId: details.data.taskId,
              targetStatus: widget.status,
              targetPosition: _finalPosition(details.data),
            ),
          ),
        );
      },
      builder: (context, candidates, rejected) {
        final active = _hovered || candidates.isNotEmpty;
        return AnimatedContainer(
          key: ValueKey<String>(
            'task-kanban-drop-${widget.status.storageValue}-${widget.keyPosition}',
          ),
          duration: const Duration(milliseconds: 140),
          height: active ? 26 : 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: active ? Border.all(color: palette.accent) : null,
          ),
          alignment: Alignment.center,
          child: active
              ? Icon(Icons.add_rounded, size: 14, color: palette.accent)
              : null,
        );
      },
    );
  }

  int _finalPosition(_TaskDragPayload payload) {
    if (payload.sourceStatus != widget.status) return widget.position;
    if (payload.sourcePosition < widget.position) {
      return widget.position - 1;
    }
    return widget.position;
  }
}

final class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.index,
    required this.statusTasks,
    required this.allTasks,
    required this.busy,
    required this.onMove,
    required this.onEdit,
    required this.onPriority,
    required this.onDelete,
  });

  final TaskItem task;
  final int index;
  final List<TaskItem> statusTasks;
  final List<TaskItem> allTasks;
  final bool busy;
  final Future<void> Function(TaskBoardMoveRequest request) onMove;
  final ValueChanged<TaskItem> onEdit;
  final ValueChanged<TaskItem> onPriority;
  final ValueChanged<TaskItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final planningLabels = <String>[
      ?taskStartLabel(task),
      ?taskDueLabel(task),
      ?taskEstimatedDurationLabel(task),
    ];

    final card = OriginalFieldSurface(
      radius: OriginalDesignTokens.rowRadius,
      fill: palette.row,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DragHandle(task: task, busy: busy),
                const SizedBox(width: 8),
                _BoardTaskNumber(number: task.displayNumber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description case final description?) ...<Widget>[
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (planningLabels.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: <Widget>[
                  for (final label in planningLabels)
                    _BoardMetaChip(label: label),
                ],
              ),
            ],
            const SizedBox(height: 9),
            Row(
              children: <Widget>[
                _BoardIconAction(
                  semanticLabel: 'ویرایش ${task.title}',
                  icon: Icons.edit_outlined,
                  onPressed: busy ? null : () => onEdit(task),
                ),
                _BoardIconAction(
                  semanticLabel: 'تغییر اولویت ${task.title}',
                  icon: Icons.outlined_flag_rounded,
                  onPressed: busy ? null : () => onPriority(task),
                ),
                _BoardIconAction(
                  semanticLabel: 'حذف ${task.title}',
                  icon: Icons.delete_outline_rounded,
                  onPressed: busy ? null : () => onDelete(task),
                ),
                const Spacer(),
                _BoardIconAction(
                  semanticLabel: 'انتقال ${task.title} به وضعیت قبلی',
                  icon: Icons.chevron_right_rounded,
                  onPressed: busy || task.status == TaskStatus.planned
                      ? null
                      : _moveToPrevious,
                ),
                _BoardIconAction(
                  semanticLabel: 'بالا بردن ${task.title}',
                  icon: Icons.keyboard_arrow_up_rounded,
                  onPressed: busy || index == 0 ? null : _moveUp,
                ),
                _BoardIconAction(
                  semanticLabel: 'پایین بردن ${task.title}',
                  icon: Icons.keyboard_arrow_down_rounded,
                  onPressed: busy || index == statusTasks.length - 1
                      ? null
                      : _moveDown,
                ),
                _BoardIconAction(
                  semanticLabel: 'انتقال ${task.title} به وضعیت بعدی',
                  icon: Icons.chevron_left_rounded,
                  onPressed: busy || task.status == TaskStatus.canceled
                      ? null
                      : _moveToNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: busy ? .48 : 1,
      duration: const Duration(milliseconds: 160),
      child: card,
    );
  }

  void _moveUp() {
    final previousId = statusTasks[index - 1].id;
    final targetPosition = _completeStatusTasks.indexWhere(
      (item) => item.id == previousId,
    );
    if (targetPosition < 0) return;

    unawaited(
      onMove(
        TaskBoardMoveRequest(
          taskId: task.id,
          targetStatus: task.status,
          targetPosition: targetPosition,
        ),
      ),
    );
  }

  void _moveDown() {
    final nextId = statusTasks[index + 1].id;
    final targetPosition = _completeStatusTasks.indexWhere(
      (item) => item.id == nextId,
    );
    if (targetPosition < 0) return;

    unawaited(
      onMove(
        TaskBoardMoveRequest(
          taskId: task.id,
          targetStatus: task.status,
          targetPosition: targetPosition,
        ),
      ),
    );
  }

  List<TaskItem> get _completeStatusTasks {
    final result = allTasks
        .where((item) => item.status == task.status)
        .toList(growable: false);
    result.sort((left, right) {
      final position = left.positionInStatus.compareTo(right.positionInStatus);
      if (position != 0) return position;
      return left.displayNumber.compareTo(right.displayNumber);
    });
    return result;
  }

  void _moveToPrevious() {
    final statusIndex = TaskStatus.values.indexOf(task.status);
    if (statusIndex <= 0) return;
    final targetStatus = TaskStatus.values[statusIndex - 1];
    unawaited(
      onMove(
        TaskBoardMoveRequest(
          taskId: task.id,
          targetStatus: targetStatus,
          targetPosition: _countFor(targetStatus),
        ),
      ),
    );
  }

  void _moveToNext() {
    final statusIndex = TaskStatus.values.indexOf(task.status);
    if (statusIndex >= TaskStatus.values.length - 1) return;
    final targetStatus = TaskStatus.values[statusIndex + 1];
    unawaited(
      onMove(
        TaskBoardMoveRequest(
          taskId: task.id,
          targetStatus: targetStatus,
          targetPosition: _countFor(targetStatus),
        ),
      ),
    );
  }

  int _countFor(TaskStatus status) {
    return allTasks.where((item) => item.status == status).length;
  }
}

final class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.task, required this.busy});

  final TaskItem task;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final payload = _TaskDragPayload(
      taskId: task.id,
      sourceStatus: task.status,
      sourcePosition: task.positionInStatus,
    );
    final handle = Container(
      width: 24,
      height: 28,
      alignment: Alignment.center,
      child: Icon(Icons.drag_indicator_rounded, color: palette.faint, size: 18),
    );

    if (busy) return handle;

    return Semantics(
      label: 'گرفتن و جابه‌جایی ${task.title}',
      child: LongPressDraggable<_TaskDragPayload>(
        data: payload,
        feedback: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: 250,
            child: OriginalFieldSurface(
              radius: OriginalDesignTokens.rowRadius,
              fill: palette.row,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  task.title,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .25, child: handle),
        child: handle,
      ),
    );
  }
}

final class _TaskDragPayload {
  const _TaskDragPayload({
    required this.taskId,
    required this.sourceStatus,
    required this.sourcePosition,
  });

  final String taskId;
  final TaskStatus sourceStatus;
  final int sourcePosition;
}

final class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _fa(count),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final class _BoardTaskNumber extends StatelessWidget {
  const _BoardTaskNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Container(
      key: ValueKey<String>('kanban-task-number-$number'),
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.field,
        shape: BoxShape.circle,
        border: Border.all(color: palette.hair),
      ),
      child: Text(
        _fa(number),
        style: TextStyle(
          color: palette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final class _BoardMetaChip extends StatelessWidget {
  const _BoardMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.inner,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.hair),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      child: Text(
        label,
        style: TextStyle(
          color: palette.muted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _BoardIconAction extends StatelessWidget {
  const _BoardIconAction({
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return OriginalPressable(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      pressedScale: .9,
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 16, color: palette.muted),
      ),
    );
  }
}

final class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.faint,
          fontSize: 12.5,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.emptyLabel,
    required this.icon,
    required this.color,
    required this.soft,
  });

  final String label;
  final String emptyLabel;
  final IconData icon;
  final Color color;
  final Color soft;
}

_StatusVisual _statusVisual(BuildContext context, TaskStatus status) {
  final palette = OriginalPalette.of(context);
  return switch (status) {
    TaskStatus.planned => _StatusVisual(
      label: 'برنامه‌ریزی‌شده',
      emptyLabel: 'کاری برای برنامه‌ریزی وجود ندارد.',
      icon: Icons.event_note_rounded,
      color: palette.accent,
      soft: palette.accentSoft,
    ),
    TaskStatus.inProgress => _StatusVisual(
      label: 'در حال انجام',
      emptyLabel: 'کاری در حال انجام نیست.',
      icon: Icons.play_arrow_rounded,
      color: palette.amber,
      soft: palette.amberSoft,
    ),
    TaskStatus.completed => _StatusVisual(
      label: 'انجام‌شده',
      emptyLabel: 'کاری انجام نشده است.',
      icon: Icons.check_rounded,
      color: palette.income,
      soft: palette.incomeSoft,
    ),
    TaskStatus.canceled => _StatusVisual(
      label: 'لغوشده',
      emptyLabel: 'کاری لغو نشده است.',
      icon: Icons.block_rounded,
      color: palette.expense,
      soft: palette.expenseSoft,
    ),
  };
}

String _fa(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().split('').map((character) {
    final index = latin.indexOf(character);
    return index < 0 ? character : persian[index];
  }).join();
}
