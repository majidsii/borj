import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/tasks/application/task_list_query.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/legacy_task_flows.dart';
import 'package:borj/features/tasks/presentation/tasks_screen/task_deletion_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Option {
  clear,
  export,
  addDetails,
  pickTemplate,
  manageTemplates,
  calendar,
}

/// Opens the Tasks options sheet («گزینه‌ها»). The sort control applies at
/// once; every other entry closes the sheet and then runs its action with
/// [context], which must outlive the sheet.
Future<void> showTasksOptions(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final router = GoRouter.of(context);
  final choice = await showGlassSheet<_Option>(
    context,
    semanticLabel: 'گزینه‌ها',
    builder: (_) => const _OptionsSheet(),
  );
  if (choice == null) return;
  switch (choice) {
    case _Option.clear:
      final handle = await container
          .read(taskActionsProvider)
          .deleteCompleted();
      if (!context.mounted) {
        if (handle.tasks.isNotEmpty) commitDeletion(handle);
        return;
      }
      showDeletionUndoToast(
        context,
        handle,
        message:
            '${Money.toPersianDigits('${handle.tasks.length}')} '
            'کار انجام‌شده پاک شد',
      );
    case _Option.export:
      if (context.mounted) await exportTasks(context, container);
    case _Option.addDetails:
      if (context.mounted) await addTaskWithDetails(context, container);
    case _Option.pickTemplate:
      if (context.mounted) await openTemplatePicker(context, container);
    case _Option.manageTemplates:
      if (context.mounted) await openTemplateManager(context, container);
    case _Option.calendar:
      router.go('${AppRoutes.tasks}?view=calendar');
  }
}

class _OptionsSheet extends ConsumerWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(tasksSortProvider);
    final completed = ref
        .watch(visibleTaskItemsProvider)
        .maybeWhen(
          data: (tasks) =>
              tasks.where((t) => t.status == TaskStatus.completed).length,
          orElse: () => 0,
        );
    final clearLabel =
        'پاک کردن انجام‌شده‌ها (${Money.toPersianDigits('$completed')})';
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppText('گزینه‌ها', role: AppTextRole.title),
            const SizedBox(height: AppSpacing.s12),
            const AppText(
              'مرتب‌سازی',
              role: AppTextRole.footnote,
              tone: AppTextTone.secondary,
              weight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            GlassSegmented<TaskSort>(
              semanticLabel: 'مرتب‌سازی',
              selected: sort,
              onChanged: (v) => ref.read(tasksSortProvider.notifier).state = v,
              segments: const [
                GlassSegment(value: TaskSort.time, label: 'زمان'),
                GlassSegment(value: TaskSort.priority, label: 'اولویت'),
                GlassSegment(value: TaskSort.newest, label: 'جدیدترین'),
                GlassSegment(value: TaskSort.alphabetical, label: 'الفبا'),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            _Item(
              id: 'option-clear',
              icon: Icons.delete_sweep_outlined,
              label: clearLabel,
              enabled: completed > 0,
              onTap: () => GlassSheet.close(context, _Option.clear),
            ),
            _Item(
              id: 'option-export',
              icon: Icons.file_download_outlined,
              label: 'خروجی',
              onTap: () => GlassSheet.close(context, _Option.export),
            ),
            _Item(
              id: 'option-add-details',
              icon: Icons.tune_rounded,
              label: 'افزودن با جزئیات',
              onTap: () => GlassSheet.close(context, _Option.addDetails),
            ),
            _Item(
              id: 'option-template-pick',
              icon: Icons.copy_all_outlined,
              label: 'انتخاب قالب',
              onTap: () => GlassSheet.close(context, _Option.pickTemplate),
            ),
            _Item(
              id: 'option-template-manage',
              icon: Icons.edit_note_rounded,
              label: 'مدیریت قالب‌ها',
              onTap: () => GlassSheet.close(context, _Option.manageTemplates),
            ),
            _Item(
              id: 'option-calendar',
              icon: Icons.calendar_month_outlined,
              label: 'تقویم',
              onTap: () => GlassSheet.close(context, _Option.calendar),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: ValueKey(id),
      onPressed: enabled ? onTap : null,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          child: Row(
            children: [
              AppIcon(icon, tone: AppTextTone.secondary),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: AppText(label, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
