import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/recurrence/recurrence_calendar.dart';
import 'package:borj/core/recurrence/recurrence_frequency.dart';
import 'package:borj/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/core/recurrence/recurrence_weekday.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_draft.dart';
import 'package:flutter/material.dart';

Future<TaskTemplateDraft?> showTaskTemplateEditorDialog({
  required BuildContext context,
  required TaskTemplateDraft initialDraft,
}) {
  return showDialog<TaskTemplateDraft>(
    context: context,
    builder: (context) => _TaskTemplateEditorDialog(initialDraft: initialDraft),
  );
}

final class _TaskTemplateEditorDialog extends StatefulWidget {
  const _TaskTemplateEditorDialog({required this.initialDraft});

  final TaskTemplateDraft initialDraft;

  @override
  State<_TaskTemplateEditorDialog> createState() =>
      _TaskTemplateEditorDialogState();
}

final class _TaskTemplateEditorDialogState
    extends State<_TaskTemplateEditorDialog> {
  late final TaskTemplateDraft draft;
  late final TextEditingController nameController;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController hoursController;
  late final TextEditingController minutesController;
  String? error;

  @override
  void initState() {
    super.initState();
    draft = widget.initialDraft;
    nameController = TextEditingController(text: draft.templateName);
    titleController = TextEditingController(text: draft.initialTaskTitle);
    descriptionController = TextEditingController(text: draft.description);
    hoursController = TextEditingController(text: '${draft.estimatedHours}');
    minutesController = TextEditingController(
      text: '${draft.estimatedMinutes}',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    hoursController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  void _syncText() {
    draft.templateName = nameController.text;
    draft.initialTaskTitle = titleController.text;
    draft.description = descriptionController.text;
    draft.estimatedHours = int.tryParse(hoursController.text.trim()) ?? -1;
    draft.estimatedMinutes = int.tryParse(minutesController.text.trim()) ?? -1;
  }

  void _save() {
    _syncText();
    final validation = draft.validate();
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ویرایش قالب'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'نام قالب'),
              ),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان اولیه کار'),
              ),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'توضیحات'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: draft.priority,
                decoration: const InputDecoration(labelText: 'اولویت'),
                items: List<DropdownMenuItem<int>>.generate(
                  4,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text('$index'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) draft.priority = value;
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ساعت تخمینی',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دقیقه تخمینی',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'یادآورها',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ...TaskReminderTrigger.values.map((trigger) {
                TaskTemplateReminderDefault? existing;
                for (final item in draft.reminderDefaults) {
                  if (item.trigger == trigger) {
                    existing = item;
                    break;
                  }
                }
                final selected = existing != null;

                return Column(
                  children: <Widget>[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected,
                      title: Text(trigger.name),
                      onChanged: (value) {
                        setState(() {
                          draft.reminderDefaults.removeWhere(
                            (item) => item.trigger == trigger,
                          );
                          if (value == true) {
                            draft.reminderDefaults.add(
                              TaskTemplateReminderDefault(
                                trigger: trigger,
                                privacyMode:
                                    existing?.privacyMode ??
                                    NotificationPrivacyMode.full,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    if (selected)
                      DropdownButtonFormField<NotificationPrivacyMode>(
                        initialValue: existing.privacyMode,
                        decoration: const InputDecoration(
                          labelText: 'حریم خصوصی یادآور',
                        ),
                        items: NotificationPrivacyMode.values
                            .map(
                              (value) =>
                                  DropdownMenuItem<NotificationPrivacyMode>(
                                    value: value,
                                    child: Text(value.name),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            draft.reminderDefaults.removeWhere(
                              (item) => item.trigger == trigger,
                            );
                            draft.reminderDefaults.add(
                              TaskTemplateReminderDefault(
                                trigger: trigger,
                                privacyMode: value,
                              ),
                            );
                          });
                        },
                      ),
                  ],
                );
              }),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تکرار'),
                value: draft.recurrence.enabled,
                onChanged: (value) {
                  setState(() => draft.recurrence.enabled = value);
                },
              ),
              if (draft.recurrence.enabled) ...<Widget>[
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: draft.recurrence.frequency,
                  decoration: const InputDecoration(labelText: 'نوع تکرار'),
                  items: RecurrenceFrequency.values
                      .map(
                        (value) => DropdownMenuItem<RecurrenceFrequency>(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => draft.recurrence.frequency = value);
                    }
                  },
                ),
                TextFormField(
                  initialValue: '${draft.recurrence.interval}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'فاصله تکرار'),
                  onChanged: (value) {
                    draft.recurrence.interval = int.tryParse(value.trim()) ?? 0;
                  },
                ),
                DropdownButtonFormField<RecurrenceCalendar>(
                  initialValue: draft.recurrence.calendar,
                  decoration: const InputDecoration(labelText: 'تقویم'),
                  items: RecurrenceCalendar.values
                      .map(
                        (value) => DropdownMenuItem<RecurrenceCalendar>(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => draft.recurrence.calendar = value);
                    }
                  },
                ),
                DropdownButtonFormField<RecurrenceTimeZoneMode>(
                  initialValue: draft.recurrence.timeZoneMode,
                  decoration: const InputDecoration(labelText: 'منطقه زمانی'),
                  items: RecurrenceTimeZoneMode.values
                      .map(
                        (value) => DropdownMenuItem<RecurrenceTimeZoneMode>(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => draft.recurrence.timeZoneMode = value);
                    }
                  },
                ),
                if (draft.recurrence.timeZoneMode ==
                    RecurrenceTimeZoneMode.fixed)
                  TextFormField(
                    initialValue: draft.recurrence.fixedTimeZoneId,
                    decoration: const InputDecoration(
                      labelText: 'شناسه منطقه زمانی',
                    ),
                    onChanged: (value) {
                      draft.recurrence.fixedTimeZoneId = value;
                    },
                  ),
                if (draft.recurrence.frequency ==
                    RecurrenceFrequency.weekly) ...<Widget>[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'روزهای هفته',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: RecurrenceWeekday.values
                        .map((weekday) {
                          final selected = draft.recurrence.weeklyDays.contains(
                            weekday,
                          );
                          return FilterChip(
                            selected: selected,
                            label: Text(weekday.name),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  draft.recurrence.weeklyDays.add(weekday);
                                } else {
                                  draft.recurrence.weeklyDays.remove(weekday);
                                }
                              });
                            },
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
                if (draft.recurrence.frequency ==
                    RecurrenceFrequency.monthly) ...<Widget>[
                  TextFormField(
                    initialValue: draft.recurrence.monthlyDaysText,
                    decoration: const InputDecoration(
                      labelText: 'روزهای ماه',
                      hintText: 'مثال: 1, 15, 28',
                    ),
                    onChanged: (value) {
                      draft.recurrence.monthlyDaysText = value;
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: draft.recurrence.includeLastDay,
                    title: const Text('آخرین روز ماه'),
                    onChanged: (value) {
                      setState(
                        () => draft.recurrence.includeLastDay = value ?? false,
                      );
                    },
                  ),
                ],
                if (draft.recurrence.frequency == RecurrenceFrequency.yearly)
                  TextFormField(
                    initialValue: draft.recurrence.annualDatesText,
                    decoration: const InputDecoration(
                      labelText: 'تاریخ‌های سالانه',
                      hintText: 'مثال: 1/1, 12/29',
                    ),
                    onChanged: (value) {
                      draft.recurrence.annualDatesText = value;
                    },
                  ),
                DropdownButtonFormField<RecurrenceInvalidDatePolicy>(
                  initialValue: draft.recurrence.invalidDatePolicy,
                  decoration: const InputDecoration(
                    labelText: 'سیاست تاریخ نامعتبر',
                  ),
                  items: RecurrenceInvalidDatePolicy.values
                      .map(
                        (value) =>
                            DropdownMenuItem<RecurrenceInvalidDatePolicy>(
                              value: value,
                              child: Text(value.name),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      draft.recurrence.invalidDatePolicy = value;
                    }
                  },
                ),
                DropdownButtonFormField<TaskTemplateRecurrenceEndKind>(
                  initialValue: draft.recurrence.endKind,
                  decoration: const InputDecoration(labelText: 'پایان تکرار'),
                  items: TaskTemplateRecurrenceEndKind.values
                      .map(
                        (value) =>
                            DropdownMenuItem<TaskTemplateRecurrenceEndKind>(
                              value: value,
                              child: Text(value.name),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => draft.recurrence.endKind = value);
                    }
                  },
                ),
                if (draft.recurrence.endKind ==
                    TaskTemplateRecurrenceEndKind.afterCount)
                  TextFormField(
                    initialValue: '${draft.recurrence.afterCount}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'بعد از چند رخداد',
                    ),
                    onChanged: (value) {
                      draft.recurrence.afterCount =
                          int.tryParse(value.trim()) ?? 0;
                    },
                  ),
                if (draft.recurrence.endKind ==
                    TaskTemplateRecurrenceEndKind.daysAfterAnchor)
                  TextFormField(
                    initialValue: '${draft.recurrence.daysAfterAnchor}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'چند روز بعد از زمان مبنا',
                    ),
                    onChanged: (value) {
                      draft.recurrence.daysAfterAnchor =
                          int.tryParse(value.trim()) ?? 0;
                    },
                  ),
              ],
              if (error != null) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _save, child: const Text('ذخیره قالب')),
      ],
    );
  }
}
