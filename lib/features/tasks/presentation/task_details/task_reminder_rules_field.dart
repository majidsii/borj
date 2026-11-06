import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_draft.dart';
import 'package:flutter/material.dart';

final class TaskReminderRulesField extends StatelessWidget {
  const TaskReminderRulesField({
    required this.dueLocal,
    required this.items,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final DateTime? dueLocal;
  final List<TaskReminderDraft> items;
  final ValueChanged<List<TaskReminderDraft>> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'یادآورها',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${items.where((item) => item.selected).length} فعال',
              key: const ValueKey<String>('task-reminder-active-count'),
              style: TextStyle(
                color: palette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        OriginalFieldSurface(
          radius: OriginalDesignTokens.fieldRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: <Widget>[
                for (final entry in items.indexed) ...<Widget>[
                  _ReminderRow(
                    draft: entry.$2,
                    dueAvailable: dueLocal != null,
                    onChanged: (value) {
                      final updated = List<TaskReminderDraft>.from(items);
                      updated[entry.$1] = value;
                      onChanged(List<TaskReminderDraft>.unmodifiable(updated));
                    },
                  ),
                  if (entry.$1 != items.length - 1)
                    Container(height: 1, color: palette.line),
                ],
              ],
            ),
          ),
        ),
        if (dueLocal == null) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            'یادآورها بر اساس زمان سررسید ساخته می‌شوند.',
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (errorText case final error?) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            error,
            key: const ValueKey<String>('task-reminders-error'),
            style: TextStyle(
              color: palette.expense,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

final class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.draft,
    required this.dueAvailable,
    required this.onChanged,
  });

  final TaskReminderDraft draft;
  final bool dueAvailable;
  final ValueChanged<TaskReminderDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final selected = draft.selected;
    final private = draft.privacyMode == NotificationPrivacyMode.private;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Semantics(
            label: 'یادآور ${draft.trigger.label}',
            toggled: selected,
            enabled: dueAvailable,
            child: Switch.adaptive(
              key: ValueKey<String>(
                'task-reminder-${draft.trigger.storageValue}',
              ),
              value: selected,
              onChanged: dueAvailable
                  ? (value) => onChanged(draft.copyWith(selected: value))
                  : null,
              activeTrackColor: palette.accent.withValues(alpha: .55),
              activeThumbColor: palette.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  draft.trigger.label,
                  style: TextStyle(
                    color: dueAvailable ? palette.ink : palette.faint,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected
                      ? private
                            ? 'متن اعلان خصوصی است'
                            : 'عنوان کار در اعلان نمایش داده می‌شود'
                      : 'غیرفعال',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            OriginalPressable(
              semanticLabel: private
                  ? 'نمایش جزئیات یادآور ${draft.trigger.label}'
                  : 'خصوصی کردن یادآور ${draft.trigger.label}',
              onPressed: () => onChanged(
                draft.copyWith(
                  privacyMode: private
                      ? NotificationPrivacyMode.full
                      : NotificationPrivacyMode.private,
                ),
              ),
              borderRadius: BorderRadius.circular(
                OriginalDesignTokens.pillRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      private
                          ? Icons.lock_outline_rounded
                          : Icons.visibility_outlined,
                      size: 16,
                      color: private ? palette.amber : palette.accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      private ? 'خصوصی' : 'کامل',
                      style: TextStyle(
                        color: private ? palette.amber : palette.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
