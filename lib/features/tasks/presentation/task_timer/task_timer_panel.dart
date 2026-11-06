import 'dart:async';

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_time_entry.dart';
import 'package:borj/features/tasks/presentation/task_timer/task_manual_time_entry_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TaskTimerPanel extends ConsumerStatefulWidget {
  const TaskTimerPanel({required this.taskId, super.key});

  final String taskId;

  @override
  ConsumerState<TaskTimerPanel> createState() => _TaskTimerPanelState();
}

final class _TaskTimerPanelState extends ConsumerState<TaskTimerPanel> {
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = ref.read(appClockProvider).nowUtc().toUtc();
    final entriesAsync = ref.watch(
      taskTimeEntriesByTaskProvider(widget.taskId),
    );
    final activeAsync = ref.watch(activeTaskTimerProvider);
    final entries = entriesAsync.asData?.value ?? const <TaskTimeEntry>[];
    final active = activeAsync.asData?.value;
    final ownActive = active?.taskId == widget.taskId ? active : null;
    final totalSeconds = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.elapsedSecondsAt(nowUtc),
    );
    final palette = OriginalPalette.of(context);

    return OriginalFieldSurface(
      radius: OriginalDesignTokens.fieldRadius,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.timer_outlined, color: palette.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'زمان ثبت‌شده',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(totalSeconds),
                  key: const ValueKey<String>('task-time-total'),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ownActive != null) ...<Widget>[
              Text(
                ownActive.isRunning ? 'در حال اجرا' : 'متوقف موقت',
                style: TextStyle(
                  color: ownActive.isRunning ? palette.accent : palette.amber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(ownActive.elapsedSecondsAt(nowUtc)),
                key: const ValueKey<String>('task-active-elapsed'),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else if (active != null) ...<Widget>[
              Text(
                'تایمر کار دیگری فعال است.',
                key: const ValueKey<String>('other-task-timer-active'),
                style: TextStyle(
                  color: palette.amber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (active == null)
                  OriginalPrimaryButton(
                    key: const ValueKey<String>('task-timer-start'),
                    label: 'شروع تایمر',
                    icon: Icons.play_arrow_rounded,
                    compact: true,
                    onPressed: _busy ? null : () => unawaited(_run(_start)),
                  ),
                if (ownActive?.isRunning ?? false)
                  OriginalGhostButton(
                    key: const ValueKey<String>('task-timer-pause'),
                    label: 'توقف موقت',
                    icon: Icons.pause_rounded,
                    onPressed: _busy ? null : () => unawaited(_run(_pause)),
                  ),
                if (ownActive?.isPaused ?? false)
                  OriginalPrimaryButton(
                    key: const ValueKey<String>('task-timer-resume'),
                    label: 'ادامه',
                    icon: Icons.play_arrow_rounded,
                    compact: true,
                    onPressed: _busy ? null : () => unawaited(_run(_resume)),
                  ),
                if (ownActive != null)
                  OriginalGhostButton(
                    key: const ValueKey<String>('task-timer-stop'),
                    label: 'پایان',
                    icon: Icons.stop_rounded,
                    onPressed: _busy ? null : () => unawaited(_run(_stop)),
                  ),
                OriginalGhostButton(
                  key: const ValueKey<String>('task-time-manual-add'),
                  label: 'ثبت دستی',
                  icon: Icons.add_alarm_rounded,
                  onPressed: _busy ? null : () => unawaited(_addManual()),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Container(height: 1, color: palette.line),
              const SizedBox(height: 8),
              for (final entry in entries.take(8))
                _TimeEntryRow(
                  entry: entry,
                  nowUtc: nowUtc,
                  onEdit: entry.isManual && entry.isStopped
                      ? () => unawaited(_editManual(entry))
                      : null,
                  onDelete: entry.isStopped
                      ? () => unawaited(_run(() => _delete(entry.id)))
                      : null,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    await ref.read(taskTimerServiceProvider).start(widget.taskId);
  }

  Future<void> _pause() async {
    await ref.read(taskTimerServiceProvider).pause();
  }

  Future<void> _resume() async {
    await ref.read(taskTimerServiceProvider).resume();
  }

  Future<void> _stop() async {
    await ref.read(taskTimerServiceProvider).stop();
  }

  Future<void> _delete(String id) {
    return ref.read(taskTimerServiceProvider).delete(id);
  }

  Future<void> _addManual() async {
    final draft = await showTaskManualTimeEntryDialog(context: context);
    if (!mounted || draft == null) return;
    await _run(() async {
      await ref
          .read(taskTimerServiceProvider)
          .addManualDuration(
            taskId: widget.taskId,
            durationMinutes: draft.durationMinutes,
            note: draft.note,
          );
    });
  }

  Future<void> _editManual(TaskTimeEntry entry) async {
    final draft = await showTaskManualTimeEntryDialog(
      context: context,
      initialEntry: entry,
    );
    if (!mounted || draft == null) return;
    await _run(() async {
      await ref
          .read(taskTimerServiceProvider)
          .updateManualDuration(
            id: entry.id,
            durationMinutes: draft.durationMinutes,
            note: draft.note,
          );
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } on AppFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class TaskTimeTotalBadge extends ConsumerWidget {
  const TaskTimeTotalBadge({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(taskTimeEntriesByTaskProvider(taskId))
        .asData
        ?.value;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(appClockProvider).nowUtc().toUtc();
    final total = entries.fold<int>(
      0,
      (sum, item) => sum + item.elapsedSecondsAt(now),
    );
    final palette = OriginalPalette.of(context);
    return Container(
      key: ValueKey<String>('task-time-badge-$taskId'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.inner,
        borderRadius: BorderRadius.circular(OriginalDesignTokens.pillRadius),
        border: Border.all(color: palette.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.timer_outlined, size: 12, color: palette.muted),
          const SizedBox(width: 4),
          Text(
            _formatCompactDuration(total),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final class TaskActiveTimerStrip extends ConsumerStatefulWidget {
  const TaskActiveTimerStrip({required this.tasks, super.key});

  final List<TaskItem> tasks;

  @override
  ConsumerState<TaskActiveTimerStrip> createState() =>
      _TaskActiveTimerStripState();
}

final class _TaskActiveTimerStripState
    extends ConsumerState<TaskActiveTimerStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = ref.read(appClockProvider).nowUtc().toUtc();
    final active = ref.watch(activeTaskTimerProvider).asData?.value;
    if (active == null) return const SizedBox.shrink();
    TaskItem? task;
    for (final candidate in widget.tasks) {
      if (candidate.id == active.taskId) {
        task = candidate;
        break;
      }
    }
    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OriginalFieldSurface(
        key: const ValueKey<String>('global-active-timer'),
        radius: OriginalDesignTokens.fieldRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(Icons.timer_rounded, color: palette.accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task?.title ?? 'تایمر فعال',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatDuration(active.elapsedSecondsAt(nowUtc)),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey<String>('global-timer-toggle'),
                tooltip: active.isRunning ? 'توقف موقت' : 'ادامه',
                onPressed: () {
                  final service = ref.read(taskTimerServiceProvider);
                  unawaited(() async {
                    if (active.isRunning) {
                      await service.pause();
                    } else {
                      await service.resume();
                    }
                  }());
                },
                icon: Icon(
                  active.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: palette.ink,
                ),
              ),
              IconButton(
                key: const ValueKey<String>('global-timer-stop'),
                tooltip: 'پایان تایمر',
                onPressed: () => unawaited(() async {
                  await ref.read(taskTimerServiceProvider).stop();
                }()),
                icon: Icon(Icons.stop_rounded, color: palette.expense),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TimeEntryRow extends StatelessWidget {
  const _TimeEntryRow({
    required this.entry,
    required this.nowUtc,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskTimeEntry entry;
  final DateTime nowUtc;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            entry.isManual
                ? Icons.edit_calendar_outlined
                : Icons.timer_outlined,
            size: 16,
            color: palette.muted,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              entry.note ?? (entry.isManual ? 'ثبت دستی' : 'تایمر'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatDuration(entry.elapsedSecondsAt(nowUtc)),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (onEdit != null)
            IconButton(
              key: ValueKey<String>('time-entry-edit-${entry.id}'),
              tooltip: 'ویرایش ثبت زمان',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 18, color: palette.muted),
            ),
          if (onDelete != null)
            IconButton(
              key: ValueKey<String>('time-entry-delete-${entry.id}'),
              tooltip: 'حذف ثبت زمان',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: palette.expense,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remaining = safe % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${remaining.toString().padLeft(2, '0')}';
}

String _formatCompactDuration(int seconds) {
  final duration = Duration(seconds: seconds < 0 ? 0 : seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}
