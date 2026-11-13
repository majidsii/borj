import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_dialog.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as timezone;

enum _Day { today, tomorrow, none }

final class _QuickEntryResult {
  const _QuickEntryResult({
    required this.title,
    required this.priority,
    required this.day,
    required this.details,
  });

  final String title;
  final int priority;
  final _Day day;
  final bool details;
}

/// Opens the task quick-entry sheet. «ثبت» creates the task and shows an undo
/// toast; «ویرایش جزئیات» continues in the legacy details dialog.
Future<void> showTaskQuickEntry(BuildContext context, {Rect? origin}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await showGlassSheet<_QuickEntryResult>(
    context,
    origin: origin,
    semanticLabel: 'کار جدید',
    builder: (_) => const _QuickEntrySheet(),
  );
  if (result == null || !context.mounted) return;

  final due = await _dueFor(container, result.day);
  if (!context.mounted) return;
  if (result.details) {
    await _createWithDetails(context, container, result, due);
  } else {
    await _createQuick(context, container, result, due);
  }
}

/// 23:59 of the chosen LOCAL day in the task calendar zone, as UTC.
Future<DateTime?> _dueFor(ProviderContainer container, _Day day) async {
  if (day == _Day.none) return null;
  final zoneId = await container.read(taskCalendarTimeZoneProvider.future);
  final location = timezone.getLocation(zoneId);
  final wall =
      container.read(todayNowProvider).valueOrNull ??
      timezone.TZDateTime.from(
        container.read(appClockProvider).nowUtc(),
        location,
      );
  final offset = day == _Day.tomorrow ? 1 : 0;
  return timezone.TZDateTime(
    location,
    wall.year,
    wall.month,
    wall.day + offset,
    23,
    59,
  ).toUtc();
}

Future<void> _createQuick(
  BuildContext context,
  ProviderContainer container,
  _QuickEntryResult result,
  DateTime? due,
) async {
  final actions = container.read(taskActionsProvider);
  final id = await actions.createAndReturnId(
    title: result.title,
    priority: result.priority,
    dueAtUtc: due,
  );
  if (!context.mounted) return;
  showUndoToast(
    context,
    message: 'کار اضافه شد',
    onUndo: () => unawaited(_removeAdded(actions, id)),
  );
}

/// Undoing an add removes the task for good.
Future<void> _removeAdded(TaskActions actions, String id) async {
  final handle = await actions.delete(id);
  await handle?.commit();
}

/// Same calls as the legacy panel's `_addTaskWithDetails`.
Future<void> _createWithDetails(
  BuildContext context,
  ProviderContainer container,
  _QuickEntryResult result,
  DateTime? due,
) async {
  final clock = container.read(appClockProvider);
  final draft =
      TaskDetailsDraft.create(
          nowLocal: clock.nowLocal(),
          priority: result.priority,
        )
        ..title = result.title
        ..dueLocal = due?.toLocal();
  final saved = await showTaskDetailsEditorDialog(
    context: context,
    mode: TaskDetailsDialogMode.create,
    initialCreateDraft: draft,
    now: clock.nowLocal,
    nextId: const UuidV7IdGenerator().next,
  );
  if (saved == null) return;

  final repository = container.read(taskRepositoryProvider);
  await repository.create(saved.task);
  await repository.transition(
    id: saved.task.id,
    status: TaskStatus.planned,
    targetPosition: 0,
    changedAtUtc: saved.task.updatedAtUtc,
  );
  if (saved.reminderRules.isNotEmpty) {
    final persisted = await repository.getById(saved.task.id);
    if (persisted != null) {
      await container
          .read(taskReminderRulesServiceProvider)
          .replaceForTask(task: persisted, rules: saved.reminderRules);
    }
  }
  if (saved.recurrenceRule != null) {
    await container
        .read(taskRecurrenceServiceProvider)
        .replaceRule(taskId: saved.task.id, rule: saved.recurrenceRule!.rule);
  }
}

final class _QuickEntrySheet extends StatefulWidget {
  const _QuickEntrySheet();

  @override
  State<_QuickEntrySheet> createState() => _QuickEntrySheetState();
}

final class _QuickEntrySheetState extends State<_QuickEntrySheet> {
  final TextEditingController _title = TextEditingController();
  _Day _day = _Day.none;
  int _priority = 0;

  bool get _canSubmit => _title.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _finish({required bool details}) {
    if (!_canSubmit) return;
    GlassSheet.close(
      context,
      _QuickEntryResult(
        title: _title.text.trim(),
        priority: _priority,
        day: _day,
        details: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText('کار جدید', role: AppTextRole.title),
          const SizedBox(height: AppSpacing.s12),
          GlassTextField(
            controller: _title,
            label: 'عنوان کار',
            autofocus: true,
            onSubmitted: (_) => _finish(details: false),
          ),
          const SizedBox(height: AppSpacing.s12),
          const AppText(
            'زمان',
            role: AppTextRole.footnote,
            tone: AppTextTone.secondary,
            weight: FontWeight.w700,
          ),
          Wrap(
            spacing: AppSpacing.s8,
            children: [
              for (final (day, label) in const [
                (_Day.today, 'امروز'),
                (_Day.tomorrow, 'فردا'),
                (_Day.none, 'بدون تاریخ'),
              ])
                GlassChip(
                  label: label,
                  selected: _day == day,
                  onPressed: () => setState(() => _day = day),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          const AppText(
            'اولویت',
            role: AppTextRole.footnote,
            tone: AppTextTone.secondary,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 6),
          GlassSegmented<int>(
            semanticLabel: 'اولویت',
            selected: _priority,
            onChanged: (v) => setState(() => _priority = v),
            segments: const [
              GlassSegment(value: 0, label: 'بدون'),
              GlassSegment(value: 1, label: 'پایین'),
              GlassSegment(value: 2, label: 'متوسط'),
              GlassSegment(value: 3, label: 'بالا'),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            height: 54,
            child: GlassButton(
              label: 'ثبت',
              variant: GlassButtonVariant.tinted,
              onPressed: _canSubmit ? () => _finish(details: false) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          GlassButton(
            label: 'ویرایش جزئیات',
            onPressed: _canSubmit ? () => _finish(details: true) : null,
          ),
        ],
      ),
    );
  }
}
