import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/features/tasks/presentation/task_details/task_planning_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final class TaskDurationField extends StatefulWidget {
  const TaskDurationField({
    required this.hours,
    required this.minutes,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onClear,
    super.key,
    this.errorText,
  });

  final int hours;
  final int minutes;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onClear;
  final String? errorText;

  @override
  State<TaskDurationField> createState() => _TaskDurationFieldState();
}

final class _TaskDurationFieldState extends State<TaskDurationField> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: _valueText(widget.hours));
    _minutesController = TextEditingController(
      text: _valueText(widget.minutes),
    );
  }

  @override
  void didUpdateWidget(covariant TaskDurationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hours != widget.hours) {
      _syncController(_hoursController, widget.hours);
    }
    if (oldWidget.minutes != widget.minutes) {
      _syncController(_minutesController, widget.minutes);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final hasValue = widget.hours != 0 || widget.minutes != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'مدت تخمینی',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: hasValue ? 1 : .42,
              duration: const Duration(milliseconds: 180),
              child: OriginalPressable(
                semanticLabel: 'پاک کردن مدت تخمینی',
                onPressed: hasValue ? widget.onClear : null,
                borderRadius: BorderRadius.circular(
                  OriginalDesignTokens.pillRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  child: Text(
                    'پاک کردن',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _DurationInput(
              key: const ValueKey<String>('task-duration-hours'),
              semanticLabel: 'ساعت مدت تخمینی',
              label: 'ساعت',
              controller: _hoursController,
              onChanged: widget.onHoursChanged,
            ),
            _DurationInput(
              key: const ValueKey<String>('task-duration-minutes'),
              semanticLabel: 'دقیقه مدت تخمینی',
              label: 'دقیقه',
              controller: _minutesController,
              onChanged: widget.onMinutesChanged,
            ),
          ],
        ),
        if (widget.errorText case final error?) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            error,
            key: const ValueKey<String>('task-duration-error'),
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

  void _syncController(TextEditingController controller, int value) {
    final text = _valueText(value);
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static String _valueText(int value) => value == 0 ? '' : value.toString();
}

final class _DurationInput extends StatelessWidget {
  const _DurationInput({
    required this.semanticLabel,
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String semanticLabel;
  final String label;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      child: Semantics(
        textField: true,
        label: semanticLabel,
        child: OriginalTextField(
          controller: controller,
          hintText: label,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          suffix: Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  color: OriginalPalette.of(context).muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
        ),
      ),
    );
  }
}

String taskDurationSummary(int hours, int minutes) {
  if (hours == 0 && minutes == 0) return 'تنظیم نشده';
  if (hours == 0) return '${taskPersianDigits(minutes)} دقیقه';
  if (minutes == 0) return '${taskPersianDigits(hours)} ساعت';
  return '${taskPersianDigits(hours)} ساعت و '
      '${taskPersianDigits(minutes)} دقیقه';
}
