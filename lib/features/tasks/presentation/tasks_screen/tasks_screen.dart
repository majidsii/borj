import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/legacy_task_flows.dart';
import 'package:borj/features/tasks/presentation/task_calendar/task_calendar_board.dart';
import 'package:borj/features/tasks/presentation/task_timer/task_timer_panel.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_deletion_toast.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_glass_row.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_desktop.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_kanban_phone.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_list_view.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_smart_tiles.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/tasks_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _View { list, board, calendar }

_View _resolve(String view, WindowClass windowClass) => switch (view) {
  'list' => _View.list,
  'board' => _View.board,
  'calendar' => _View.calendar,
  _ => windowClass == WindowClass.compact ? _View.list : _View.board,
};

/// The Tasks screen (boards `PhoneTasks`, `PhoneKanban`, `MacTasks`).
/// [view] is the route's `view` query: `list`, `board` or `calendar`; any
/// other value picks the window class default (compact list, otherwise the
/// board). Padding comes from the shell insets, applied to the body only.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({required this.view, super.key});

  final String view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowClass = WindowClass.of(context);
    final compact = windowClass == WindowClass.compact;
    final current = _resolve(view, windowClass);
    final insets = MediaQuery.paddingOf(context);
    final side = compact ? 16.0 : 28.0;

    final listAsync = ref.watch(taskListViewProvider);
    final tasksAsync = ref.watch(visibleTaskItemsProvider);
    final zoneAsync = ref.watch(taskCalendarTimeZoneProvider);
    final query = ref.watch(tasksQueryProvider);
    final filter = ref.watch(tasksFilterProvider);
    final actions = ref.watch(taskActionsProvider);
    final container = ProviderScope.containerOf(context, listen: false);

    void guard(Future<void> operation) {
      unawaited(
        operation.catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'tasks screen',
            ),
          );
        }),
      );
    }

    void open(TaskItem task) => guard(editTask(context, container, task));
    void delete(TaskItem task) => unawaited(_delete(context, actions, task.id));

    final openCount = listAsync.valueOrNull?.activeCount;
    final header = compact
        ? LargeTitleHeader(
            key: const ValueKey('tasks-title'),
            title: 'کارها',
            subtitle: openCount == null ? null : _openLabel(openCount),
          )
        : _DesktopHeader(
            subtitle: openCount == null ? null : _openLabel(openCount),
          );

    final segmented = GlassSegmented<_View>(
      key: const ValueKey('tasks-view'),
      semanticLabel: 'نما',
      selected: current,
      onChanged: (v) => context.go('${AppRoutes.tasks}?view=${v.name}'),
      segments: const [
        GlassSegment(
          value: _View.list,
          label: 'فهرست',
          icon: Icons.view_list_rounded,
        ),
        GlassSegment(
          value: _View.board,
          label: 'کانبان',
          icon: Icons.view_kanban_outlined,
        ),
        GlassSegment(
          value: _View.calendar,
          label: 'تقویم',
          icon: Icons.calendar_month_outlined,
        ),
      ],
    );
    const search = _SearchField();

    final controls = compact
        ? <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(side, 12, side, 0),
              child: segmented,
            ),
            if (current != _View.calendar)
              Padding(
                padding: EdgeInsets.fromLTRB(side, 12, side, 0),
                child: search,
              ),
          ]
        : <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(side, 16, side, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final options = GlassButton(
                    key: const ValueKey('tasks-options'),
                    label: 'گزینه‌ها',
                    icon: Icons.more_horiz,
                    onPressed: () => unawaited(showTasksOptions(context)),
                  );
                  final showSearch = current != _View.calendar;
                  if (constraints.maxWidth < 700) {
                    // Medium windows: search drops to its own line.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: segmented),
                            const SizedBox(width: AppSpacing.s12),
                            options,
                          ],
                        ),
                        if (showSearch) ...[
                          const SizedBox(height: AppSpacing.s8),
                          search,
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      SizedBox(width: 300, child: segmented),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: showSearch ? search : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      options,
                    ],
                  );
                },
              ),
            ),
          ];

    final timer = TaskActiveTimerStrip(
      tasks: tasksAsync.valueOrNull ?? const <TaskItem>[],
    );
    final strip = Padding(
      padding: EdgeInsets.fromLTRB(side, 12, side, 0),
      child: timer,
    );

    Widget body;
    if (current == _View.calendar) {
      body = _Calendar(container: container);
    } else if (listAsync.hasError || tasksAsync.hasError) {
      body = const EmptyState(
        icon: Icons.error_outline,
        title: 'کارها بارگذاری نشد',
      );
    } else if (current == _View.list) {
      final data = listAsync.valueOrNull;
      if (data == null) {
        body = const SizedBox.shrink();
      } else {
        final list = TaskSectionList(
          view: data,
          filter: filter,
          query: query,
          callbacks: TaskRowCallbacks(
            onToggle: (t) => guard(actions.toggleDone(t)),
            onOpen: open,
            onDelete: delete,
            menuFor: (t) => _menuFor(t, actions, guard, open, delete),
          ),
        );
        final tiles = TaskSmartTiles(
          counts: data.counts,
          selected: filter,
          onSelected: (f) => ref.read(tasksFilterProvider.notifier).state = f,
        );
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 760 : 560),
                child: tiles,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: list,
              ),
            ),
          ],
        );
      }
    } else {
      final all = tasksAsync.valueOrNull;
      final zone = zoneAsync.valueOrNull;
      if (all == null || zone == null) {
        body = const SizedBox.shrink();
      } else {
        final tasks = [
          for (final t in all)
            if (taskMatches(t, query)) t,
        ];
        body = compact
            ? TaskKanbanPhone(
                tasks: tasks,
                actions: actions,
                onOpen: open,
                onDelete: delete,
                timeZoneId: zone,
              )
            : TaskKanbanDesktop(
                tasks: tasks,
                actions: actions,
                onOpen: open,
                onDelete: delete,
                timeZoneId: zone,
              );
      }
    }

    final scrolls = current != _View.board;
    if (scrolls) {
      return ListView(
        key: const ValueKey('tasks-page'),
        padding: insets,
        children: [
          header,
          ...controls,
          strip,
          Padding(
            padding: EdgeInsets.fromLTRB(side, 12, side, 28),
            child: body,
          ),
        ],
      );
    }
    return Padding(
      key: const ValueKey('tasks-page'),
      padding: insets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          ...controls,
          strip,
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, 12, side, compact ? 0 : 28),
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  static String _openLabel(int count) =>
      '${Money.toPersianDigits('$count')} کار باز';

  static TaskRowMenuActions _menuFor(
    TaskItem t,
    TaskActions actions,
    void Function(Future<void>) guard,
    void Function(TaskItem) open,
    void Function(TaskItem) delete,
  ) {
    return TaskRowMenuActions(
      onEdit: () => open(t),
      onCyclePriority: () => guard(actions.cyclePriority(t)),
      onToggleInProgress: () => guard(
        actions.setStatus(
          t,
          t.status == TaskStatus.inProgress
              ? TaskStatus.planned
              : TaskStatus.inProgress,
        ),
      ),
      onToggleCanceled: () => guard(
        actions.setStatus(
          t,
          t.status == TaskStatus.canceled
              ? TaskStatus.planned
              : TaskStatus.canceled,
        ),
      ),
      onDelete: () => delete(t),
    );
  }

  static Future<void> _delete(
    BuildContext context,
    TaskActions actions,
    String id,
  ) async {
    final handle = await actions.delete(id);
    if (!context.mounted) {
      if (handle != null && handle.tasks.isNotEmpty) commitDeletion(handle);
      return;
    }
    showDeletionUndoToast(context, handle, message: 'کار حذف شد');
  }
}

/// The desktop header chip (board `MacTasks`): clear glass like Today's date
/// chip, with `secondaryStrong` / `primary` text (Part B Decision 6).
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 22, 28, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GlassScope(
          kind: GlassLayerKind.clear,
          child: AppGlass(
            key: const ValueKey('tasks-header-chip'),
            role: GlassRole.clear,
            shape: const AppleGlassShape.rounded(26),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    AppText(
                      subtitle!,
                      role: AppTextRole.subheadline,
                      weight: FontWeight.w600,
                      tone: AppTextTone.secondaryStrong,
                    ),
                  const AppText(
                    'همهٔ کارها',
                    key: ValueKey('tasks-title'),
                    role: AppTextRole.largeTitle,
                    weight: FontWeight.w900,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The search field; keeps the text in [tasksQueryProvider] so list and
/// kanban share it and it survives view switches.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(tasksQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      key: const ValueKey('tasks-search'),
      controller: _controller,
      hint: 'جست‌وجو در کارها…',
      onChanged: (v) => ref.read(tasksQueryProvider.notifier).state = v,
    );
  }
}

/// The legacy calendar board, wired as the legacy panel wired it.
class _Calendar extends ConsumerWidget {
  const _Calendar({required this.container});

  final ProviderContainer container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskItemsProvider);
    final rules = ref.watch(taskRecurrenceRulesProvider);
    final exceptions = ref.watch(taskRecurrenceExceptionsProvider);
    final completions = ref.watch(taskOccurrenceCompletionsProvider);
    final zone = ref.watch(taskCalendarTimeZoneProvider);
    if (!rules.hasValue ||
        !exceptions.hasValue ||
        !completions.hasValue ||
        !zone.hasValue) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return TaskCalendarBoard(
      tasks: tasks.valueOrNull ?? const <TaskItem>[],
      rules: rules.requireValue,
      exceptions: exceptions.requireValue,
      completions: completions.requireValue,
      floatingTimeZoneId: zone.requireValue,
      now: ref.read(appClockProvider).nowLocal,
      onToggleCompleted: (o) => toggleOccurrenceCompleted(container, o),
      onSkip: (o) => skipOccurrence(container, o),
      onCancel: (o) => cancelOccurrence(container, o),
      onRestore: (o) => restoreOccurrence(container, o),
      onMove: (o, to) => moveOccurrence(container, o, to),
    );
  }
}
