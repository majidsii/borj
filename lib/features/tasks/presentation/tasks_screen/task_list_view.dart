import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:flutter/material.dart';

/// Per-task callbacks of the list. Plain callbacks: the list never calls the
/// task actions and never shows toasts; the screen wires those.
final class TaskRowCallbacks {
  const TaskRowCallbacks({
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
    required this.menuFor,
  });

  final ValueChanged<TaskItem> onToggle;
  final ValueChanged<TaskItem> onOpen;
  final ValueChanged<TaskItem> onDelete;

  /// The long-press menu callbacks of one task.
  final TaskRowMenuActions Function(TaskItem task) menuFor;
}

/// Rows per panel: a content scope holds at most 16 shapes.
const int _rowsPerPanel = 15;

/// Section headers and glass panels of the Tasks list, or the empty state.
/// Sits in a page's content group: it adds one scope per panel but no
/// backdrop group of its own. [query] is the active search text (empty when
/// none) and only selects the empty state.
class TaskSectionList extends StatefulWidget {
  const TaskSectionList({
    required this.view,
    required this.filter,
    required this.callbacks,
    this.query = '',
    super.key,
  });

  final TaskListView view;
  final TaskSmartFilter filter;
  final TaskRowCallbacks callbacks;
  final String query;

  @override
  State<TaskSectionList> createState() => _TaskSectionListState();
}

class _TaskSectionListState extends State<TaskSectionList> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (w.view.sections.isEmpty) return _empty(w);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in w.view.sections)
          if (section.kind != TaskSectionKind.done || _showDone)
            ..._sectionWidgets(section)
          else
            _ShowDone(
              count: section.entries.length,
              onTap: () => setState(() => _showDone = true),
            ),
      ],
    );
  }

  List<Widget> _sectionWidgets(TaskSection section) {
    final kind = section.kind;
    final chunks = <List<TaskListEntry>>[
      for (var i = 0; i < section.entries.length; i += _rowsPerPanel)
        section.entries.sublist(
          i,
          i + _rowsPerPanel > section.entries.length
              ? section.entries.length
              : i + _rowsPerPanel,
        ),
    ];
    return [
      _Header(kind: kind),
      for (final chunk in chunks)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: GlassScope(
            kind: GlassLayerKind.content,
            child: AppGlass(
              role: GlassRole.panel,
              shape: const AppleGlassShape.rounded(AppRadii.cardLarge),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < chunk.length; i++)
                      _row(chunk[i], kind, divider: i > 0),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _row(TaskListEntry e, TaskSectionKind kind, {required bool divider}) {
    final c = widget.callbacks;
    final task = e.task;
    return TaskGlassRow(
      entry: e,
      divider: divider,
      showDate: kind != TaskSectionKind.today,
      onToggle: () => c.onToggle(task),
      onOpen: () => c.onOpen(task),
      onDelete: () => c.onDelete(task),
      menu: c.menuFor(task),
    );
  }

  Widget _empty(TaskSectionList w) {
    if (w.query.trim().isNotEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'چیزی پیدا نشد',
        message: 'عبارت دیگری را جست‌وجو کنید.',
      );
    }
    return switch (w.filter) {
      TaskSmartFilter.today => const EmptyState(
        icon: Icons.today_rounded,
        title: 'امروز کاری نداری',
      ),
      TaskSmartFilter.overdue => const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'کار عقب‌افتاده‌ای نداری',
      ),
      TaskSmartFilter.timed => const EmptyState(
        icon: Icons.schedule_rounded,
        title: 'کار زمان‌داری نداری',
      ),
      TaskSmartFilter.all => const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'هنوز کاری اضافه نکرده‌اید',
        message: 'با دکمهٔ «کار جدید» اولین کارت را بنویس.',
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.kind});

  final TaskSectionKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        6,
      ),
      child: Semantics(
        header: true,
        child: AppText(
          kind.title,
          role: AppTextRole.caption,
          weight: FontWeight.w700,
          tone: kind == TaskSectionKind.overdue
              ? AppTextTone.danger
              : AppTextTone.secondary,
        ),
      ),
    );
  }
}

class _ShowDone extends StatelessWidget {
  const _ShowDone({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Pressable(
        key: const ValueKey('tasks-show-done'),
        onPressed: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: AppText(
              'نمایش انجام‌شده‌ها (${Money.toPersianDigits('$count')})',
              role: AppTextRole.subheadline,
              tone: AppTextTone.link,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
