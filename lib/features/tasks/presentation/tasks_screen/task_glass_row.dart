import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/today/presentation/today_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The time-or-date label of a task row or card. [localInstant] is a
/// task-zone wall clock in a `DateTime.utc` carrier. [showDate] gives «۱۴ آبان»;
/// otherwise the clock «۱۵:۰۰», or nothing at 23:59 (quick entry stores
/// «امروز/فردا» as 23:59: a date, not a time of day).
String? taskWhenLabel(DateTime? localInstant, {required bool showDate}) {
  final at = localInstant;
  if (at == null) return null;
  if (showDate) return PersianDateLabel.dayMonth(at);
  if (at.hour == 23 && at.minute == 59) return null;
  return formatClock(at);
}

/// Callbacks behind the row menu (long-press or secondary click).
final class TaskRowMenuActions {
  const TaskRowMenuActions({
    required this.onEdit,
    required this.onCyclePriority,
    required this.onToggleInProgress,
    required this.onToggleCanceled,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onCyclePriority;
  final VoidCallback onToggleInProgress;
  final VoidCallback onToggleCanceled;
  final VoidCallback onDelete;
}

const double _actionWidth = 58;
const double _actionsWidth = _actionWidth * 2;

/// A flat task row for a section panel (no glass of its own) with swipe
/// actions and a long-press menu. [showDate] shows the Jalali date instead of
/// the clock time (rows outside «امروز»). The row never shows toasts.
class TaskGlassRow extends StatefulWidget {
  TaskGlassRow({
    required this.entry,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
    required this.menu,
    this.divider = true,
    this.showDate = false,
    Key? key,
  }) : super(key: key ?? ValueKey('task-row-${entry.task.id}'));

  final TaskListEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final TaskRowMenuActions menu;
  final bool divider;
  final bool showDate;

  @override
  State<TaskGlassRow> createState() => _TaskGlassRowState();
}

class _TaskGlassRowState extends State<TaskGlassRow>
    with SingleTickerProviderStateMixin {
  /// 0 closed .. 1 fully open (actions revealed).
  late final AnimationController _open = AnimationController(vsync: this);
  bool _reduced = false;

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  bool get _isOpen => _open.value > 0;

  void _settle(bool open) {
    final target = open ? 1.0 : 0.0;
    if (_reduced) {
      _open.value = target;
      return;
    }
    _open.animateTo(
      target,
      duration: AppMotion.quick.duration,
      curve: AppMotion.quick.curve,
    );
  }

  void _drag(DragUpdateDetails d) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Toward the start side is positive.
    final toStart = rtl ? d.delta.dx : -d.delta.dx;
    _open.value = (_open.value + toStart / _actionsWidth).clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails d) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final v = rtl
        ? d.velocity.pixelsPerSecond.dx
        : -d.velocity.pixelsPerSecond.dx;
    if (v.abs() > 700) {
      _settle(v > 0); // a fling only opens or closes
    } else {
      _settle(_open.value > 0.5);
    }
  }

  void _run(VoidCallback action) {
    _settle(false);
    action();
  }

  void _showMenu() {
    final w = widget;
    final status = w.entry.task.status;
    final items = <(String, VoidCallback, bool)>[
      ('ویرایش', w.menu.onEdit, false),
      ('اولویت', w.menu.onCyclePriority, false),
      (
        status == TaskStatus.inProgress ? 'برنامه‌ریزی‌شده' : 'در حال انجام',
        w.menu.onToggleInProgress,
        false,
      ),
      (
        status == TaskStatus.canceled ? 'بازگردانی' : 'لغو کار',
        w.menu.onToggleCanceled,
        false,
      ),
      ('حذف', w.menu.onDelete, true),
    ];
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
    );
  }

  @override
  Widget build(BuildContext context) {
    _reduced = MotionScope.reducedOf(context);
    final colors = AppTheme.of(context).colors;
    final w = widget;
    final task = w.entry.task;
    final canceled = task.status == TaskStatus.canceled;
    final done = task.status == TaskStatus.completed || canceled;
    final checked = task.status == TaskStatus.completed;
    final when = taskWhenLabel(w.entry.localInstant, showDate: w.showDate);
    final (priorityLabel, priorityTone) = switch (task.priority) {
      1 => ('اولویت پایین', AppTextTone.secondary),
      2 => ('اولویت متوسط', AppTextTone.warn),
      3 => ('اولویت بالا', AppTextTone.danger),
      _ => (null, AppTextTone.secondary),
    };
    final hasSubline = canceled || when != null || priorityLabel != null;
    final label = [
      task.title,
      if (canceled) 'لغوشده',
      ?when,
      ?priorityLabel,
    ].join('، ');

    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: w.divider
            ? Border(top: BorderSide(color: colors.hairline, width: 0.5))
            : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: hasSubline ? 52 : 48),
        child: Row(
          children: [
            Semantics(
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'تکمیل'): w.onToggle,
                const CustomSemanticsAction(label: 'حذف'): w.onDelete,
                const CustomSemanticsAction(label: 'ویرایش'): w.onOpen,
              },
              child: RoundCheck(
                checked: checked,
                onChanged: (_) => w.onToggle(),
                semanticLabel: label,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: ExcludeSemantics(
                child: ExcludeFocus(
                  child: Pressable(
                    onPressed: () {
                      if (_isOpen) {
                        _settle(false);
                      } else {
                        w.onOpen();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            task.title,
                            maxLines: 2,
                            weight: FontWeight.w600,
                            tone: done
                                ? AppTextTone.tertiary
                                : AppTextTone.primary,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          if (hasSubline)
                            Wrap(
                              spacing: AppSpacing.s8,
                              children: [
                                if (canceled)
                                  const AppText(
                                    'لغوشده',
                                    role: AppTextRole.caption,
                                    tone: AppTextTone.secondary,
                                  ),
                                if (when != null)
                                  AppText(
                                    when,
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
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _drag,
      onHorizontalDragEnd: _dragEnd,
      onLongPress: _showMenu,
      onSecondaryTap: _showMenu,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _open,
          builder: (context, child) {
            final t = _open.value;
            final rtl = Directionality.of(context) == TextDirection.rtl;
            return Stack(
              children: [
                if (t > 0)
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: _actionsWidth * t,
                    child: ExcludeSemantics(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: AlignmentDirectional.centerEnd,
                          minWidth: _actionsWidth,
                          maxWidth: _actionsWidth,
                          child: Row(
                            children: [
                              _Action(
                                key: const ValueKey('swipe-complete'),
                                label: 'تکمیل',
                                color: colors.teal,
                                onTap: () => _run(w.onToggle),
                              ),
                              _Action(
                                key: const ValueKey('swipe-delete'),
                                label: 'حذف',
                                color: colors.danger,
                                onTap: () => _run(w.onDelete),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                _Shift(dx: (rtl ? 1 : -1) * _actionsWidth * t, child: child!),
              ],
            );
          },
          child: content,
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _actionWidth,
      child: Pressable(
        onPressed: onTap,
        child: ColoredBox(
          color: color,
          child: Center(
            child: AppText(
              label,
              role: AppTextRole.caption2,
              tone: AppTextTone.inverse,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out its child at the incoming constraints and paints and hit-tests it
/// shifted by [dx] (a layout offset, not a `Transform`).
class _Shift extends SingleChildRenderObjectWidget {
  const _Shift({required this.dx, required Widget super.child});

  final double dx;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderShift(dx);

  @override
  void updateRenderObject(BuildContext context, _RenderShift renderObject) {
    renderObject.dx = dx;
  }
}

class _RenderShift extends RenderShiftedBox {
  _RenderShift(this._dx) : super(null);

  double _dx;
  set dx(double v) {
    if (v == _dx) return;
    _dx = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(c.size);
    (c.parentData! as BoxParentData).offset = Offset(_dx, 0);
  }
}
