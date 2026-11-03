import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_time_entry.dart';
import 'package:flutter/material.dart';

final class TaskManualTimeEntryDraft {
  const TaskManualTimeEntryDraft({required this.durationMinutes, this.note});

  final int durationMinutes;
  final String? note;
}

Future<TaskManualTimeEntryDraft?> showTaskManualTimeEntryDialog({
  required BuildContext context,
  TaskTimeEntry? initialEntry,
}) {
  final initialMinutes = initialEntry == null
      ? 30
      : (initialEntry.accumulatedSeconds / 60)
            .round()
            .clamp(1, 1000000)
            .toInt();
  return showDialog<TaskManualTimeEntryDraft>(
    context: context,
    builder: (context) => _TaskManualTimeEntryDialog(
      initialMinutes: initialMinutes,
      initialNote: initialEntry?.note,
    ),
  );
}

final class _TaskManualTimeEntryDialog extends StatefulWidget {
  const _TaskManualTimeEntryDialog({
    required this.initialMinutes,
    required this.initialNote,
  });

  final int initialMinutes;
  final String? initialNote;

  @override
  State<_TaskManualTimeEntryDialog> createState() =>
      _TaskManualTimeEntryDialogState();
}

final class _TaskManualTimeEntryDialogState
    extends State<_TaskManualTimeEntryDialog> {
  late final TextEditingController _durationController;
  late final TextEditingController _noteController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.initialMinutes.toString(),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: AppleLiquidGlass(
          role: AppleGlassRole.largeSurface,
          shape: const AppleGlassShape.rounded(OriginalDesignTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'ثبت دستی زمان',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                OriginalTextField(
                  key: const ValueKey<String>('manual-time-duration'),
                  controller: _durationController,
                  hintText: 'مدت به دقیقه',
                  prefixIcon: Icons.schedule_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                OriginalTextField(
                  key: const ValueKey<String>('manual-time-note'),
                  controller: _noteController,
                  hintText: 'یادداشت اختیاری',
                  prefixIcon: Icons.notes_rounded,
                ),
                if (_error case final error?) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    key: const ValueKey<String>('manual-time-error'),
                    style: TextStyle(
                      color: palette.expense,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OriginalGhostButton(
                      label: 'انصراف',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    OriginalPrimaryButton(
                      key: const ValueKey<String>('manual-time-save'),
                      label: 'ذخیره',
                      icon: Icons.check_rounded,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final minutes = int.tryParse(_durationController.text.trim());
    if (minutes == null || minutes <= 0) {
      setState(() => _error = 'مدت باید یک عدد بیشتر از صفر باشد.');
      return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      TaskManualTimeEntryDraft(
        durationMinutes: minutes,
        note: note.isEmpty ? null : note,
      ),
    );
  }
}
