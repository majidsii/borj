import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_duration_field.dart';
import 'package:borj/features/tasks/presentation/task_details/task_jalali_date_time_field.dart';
import 'package:borj/features/tasks/presentation/task_details/task_recurrence_field.dart';
import 'package:borj/features/tasks/presentation/task_details/task_reminder_rules_field.dart';
import 'package:borj/features/tasks/presentation/task_timer/task_timer_panel.dart';
import 'package:flutter/material.dart';

final class TaskDetailsForm extends StatefulWidget {
  const TaskDetailsForm({
    required this.initialDraft,
    required this.titleHint,
    required this.onSubmit,
    this.taskId,
    super.key,
  });

  final TaskDetailsDraft initialDraft;
  final String titleHint;
  final VoidCallback onSubmit;
  final String? taskId;

  @override
  TaskDetailsFormState createState() => TaskDetailsFormState();
}

final class TaskDetailsFormState extends State<TaskDetailsForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskDetailsDraft _draft;
  Map<TaskDetailsField, String> _errors = <TaskDetailsField, String>{};

  TaskDetailsDraft get draft => _draft;

  @override
  void initState() {
    super.initState();
    _draft = _copyDraft(widget.initialDraft);
    _titleController = TextEditingController(text: _draft.title);
    _descriptionController = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TaskDetailsDraft snapshot() {
    _draft.title = _titleController.text;
    _draft.description = _descriptionController.text;
    return _copyDraft(_draft);
  }

  bool validate() {
    _draft.title = _titleController.text;
    _draft.description = _descriptionController.text;
    final errors = _draft.validate();
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FieldLabel(label: 'عنوان'),
          const SizedBox(height: 7),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: Semantics(
              textField: true,
              label: 'عنوان کار',
              child: OriginalTextField(
                controller: _titleController,
                hintText: widget.titleHint,
                prefixIcon: Icons.task_alt_rounded,
                onChanged: (value) {
                  _draft.title = value;
                  _clearError(TaskDetailsField.title);
                },
                onSubmitted: (_) => widget.onSubmit(),
              ),
            ),
          ),
          if (_errors[TaskDetailsField.title] case final error?) ...<Widget>[
            const SizedBox(height: 6),
            _InlineError(
              key: const ValueKey<String>('task-title-error'),
              text: error,
            ),
          ],
          const SizedBox(height: 17),
          _FieldLabel(label: 'اولویت'),
          const SizedBox(height: 7),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: OriginalPills(
              items: const <String>['بدون اولویت', 'پایین', 'متوسط', 'بالا'],
              selected: _draft.priority,
              onSelected: (value) => setState(() => _draft.priority = value),
            ),
          ),
          const SizedBox(height: 17),
          _FieldLabel(label: 'توضیحات'),
          const SizedBox(height: 7),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: Semantics(
              textField: true,
              label: 'توضیحات کار',
              child: OriginalFieldSurface(
                radius: OriginalDesignTokens.fieldRadius,
                child: TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textDirection: TextDirection.rtl,
                  cursorColor: palette.accent,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14.5,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'جزئیات، خروجی مورد انتظار یا نکات مهم…',
                    hintStyle: TextStyle(
                      color: palette.faint,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (value) => _draft.description = value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: TaskJalaliDateTimeField(
              label: 'شروع',
              valueLocal: _draft.startLocal,
              errorText: _errors[TaskDetailsField.startAt],
              onChanged: (value) {
                setState(() => _draft.startLocal = value);
                _clearError(TaskDetailsField.startAt);
                _clearError(TaskDetailsField.dueAt);
                _clearError(TaskDetailsField.recurrence);
              },
            ),
          ),
          const SizedBox(height: 17),
          FocusTraversalOrder(
            order: const NumericFocusOrder(5),
            child: TaskJalaliDateTimeField(
              label: 'سررسید',
              valueLocal: _draft.dueLocal,
              errorText: _errors[TaskDetailsField.dueAt],
              onChanged: (value) {
                setState(() => _draft.dueLocal = value);
                _clearError(TaskDetailsField.dueAt);
                _clearError(TaskDetailsField.reminders);
                _clearError(TaskDetailsField.recurrence);
              },
            ),
          ),
          const SizedBox(height: 17),
          FocusTraversalOrder(
            order: const NumericFocusOrder(6),
            child: TaskReminderRulesField(
              dueLocal: _draft.dueLocal,
              items: _draft.reminders,
              errorText: _errors[TaskDetailsField.reminders],
              onChanged: (items) {
                setState(() {
                  _draft.reminders
                    ..clear()
                    ..addAll(items);
                });
                _clearError(TaskDetailsField.reminders);
              },
            ),
          ),
          const SizedBox(height: 17),
          FocusTraversalOrder(
            order: const NumericFocusOrder(7),
            child: TaskRecurrenceField(
              value: _draft.recurrence,
              anchorLocal: _draft.dueLocal ?? _draft.startLocal,
              errorText: _errors[TaskDetailsField.recurrence],
              onChanged: (value) {
                setState(() => _draft.recurrence = value);
                _clearError(TaskDetailsField.recurrence);
              },
            ),
          ),
          const SizedBox(height: 17),
          FocusTraversalOrder(
            order: const NumericFocusOrder(8),
            child: TaskDurationField(
              hours: _draft.estimatedHours,
              minutes: _draft.estimatedMinutes,
              errorText: _errors[TaskDetailsField.estimatedDuration],
              onHoursChanged: (value) {
                setState(() => _draft.estimatedHours = value);
                _clearError(TaskDetailsField.estimatedDuration);
              },
              onMinutesChanged: (value) {
                setState(() => _draft.estimatedMinutes = value);
                _clearError(TaskDetailsField.estimatedDuration);
              },
              onClear: () {
                setState(() {
                  _draft.estimatedHours = 0;
                  _draft.estimatedMinutes = 0;
                });
                _clearError(TaskDetailsField.estimatedDuration);
              },
            ),
          ),
          if (widget.taskId case final taskId?) ...<Widget>[
            const SizedBox(height: 17),
            TaskTimerPanel(
              key: const ValueKey<String>('task-details-timer-panel'),
              taskId: taskId,
            ),
          ],
        ],
      ),
    );
  }

  void _clearError(TaskDetailsField field) {
    if (!_errors.containsKey(field)) return;
    setState(() {
      final next = Map<TaskDetailsField, String>.from(_errors)..remove(field);
      _errors = next;
    });
  }
}

final class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: OriginalPalette.of(context).ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: OriginalPalette.of(context).expense,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

TaskDetailsDraft _copyDraft(TaskDetailsDraft source) {
  return TaskDetailsDraft(
    title: source.title,
    description: source.description,
    priority: source.priority,
    startLocal: source.startLocal,
    dueLocal: source.dueLocal,
    estimatedHours: source.estimatedHours,
    estimatedMinutes: source.estimatedMinutes,
    reminders: source.reminders.map((item) => item.copyWith()).toList(),
    recurrence: source.recurrence.copy(),
  );
}
