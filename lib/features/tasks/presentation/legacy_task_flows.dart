import 'dart:async';

import 'package:borj/core/ids/id_generator.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_dialog.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_draft.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_editor_dialog.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_manager_dialog.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The legacy Tasks panel's dialog flows, moved out of the panel so the panel
// and the redesigned Tasks screen share them until the panel is removed. They
// make the same repository and service calls as the panel did. Each takes the
// [ProviderContainer] (not a `WidgetRef`) so a flow can outlive the widget
// that started it, for example the options sheet that closes before the
// dialog opens.

const IdGenerator _ids = UuidV7IdGenerator();

DateTime _nowUtc(ProviderContainer container) =>
    container.read(appClockProvider).nowUtc().toUtc();

/// Creates a task through the legacy details dialog (create mode).
Future<void> addTaskWithDetails(
  BuildContext context,
  ProviderContainer container, {
  TaskDetailsDraft? initialDraft,
}) async {
  final result = await showTaskDetailsEditorDialog(
    context: context,
    mode: TaskDetailsDialogMode.create,
    initialCreateDraft: initialDraft,
    now: container.read(appClockProvider).nowLocal,
    nextId: _ids.next,
  );
  if (!context.mounted || result == null) return;

  final repository = container.read(taskRepositoryProvider);
  await repository.create(result.task);
  await repository.transition(
    id: result.task.id,
    status: TaskStatus.planned,
    targetPosition: 0,
    changedAtUtc: result.task.updatedAtUtc,
  );
  if (result.reminderRules.isNotEmpty) {
    final persisted = await repository.getById(result.task.id);
    if (persisted != null) {
      await container
          .read(taskReminderRulesServiceProvider)
          .replaceForTask(task: persisted, rules: result.reminderRules);
    }
  }
  if (result.recurrenceRule != null) {
    await container
        .read(taskRecurrenceServiceProvider)
        .replaceRule(taskId: result.task.id, rule: result.recurrenceRule!.rule);
  }
}

/// The legacy template picker; a chosen template continues in
/// [addTaskWithDetails], «مدیریت» opens [openTemplateManager].
Future<void> openTemplatePicker(
  BuildContext context,
  ProviderContainer container,
) async {
  final templates = await container
      .read(taskTemplateRepositoryProvider)
      .getAll();
  if (!context.mounted) return;

  var manageRequested = false;
  final selected = await showDialog<TaskTemplate>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('انتخاب قالب'),
      content: SizedBox(
        width: 620,
        child: TaskTemplatePicker(
          templates: templates,
          onSelected: (template) => Navigator.of(dialogContext).pop(template),
          onManage: () {
            manageRequested = true;
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    ),
  );

  if (!context.mounted) return;
  if (manageRequested) {
    await openTemplateManager(context, container);
    return;
  }
  if (selected == null) return;

  final draft = container
      .read(taskTemplateMapperProvider)
      .toTaskDetailsDraft(selected);
  await addTaskWithDetails(context, container, initialDraft: draft);
}

/// The legacy template manager dialog.
Future<void> openTemplateManager(
  BuildContext context,
  ProviderContainer container,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 760),
        child: Consumer(
          builder: (_, dialogRef, _) {
            final templatesAsync = dialogRef.watch(taskTemplatesProvider);
            return templatesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('بارگذاری قالب‌ها انجام نشد.'),
              ),
              data: (templates) => TaskTemplateManagerDialog(
                templates: templates,
                onCreate: () =>
                    unawaited(_createCustomTemplate(context, container)),
                onEdit: (template) => unawaited(
                  _editCustomTemplate(context, container, template),
                ),
                onDelete: (template) => container
                    .read(taskTemplateRepositoryProvider)
                    .deleteCustom(template.id),
                onDuplicate: (template) async {
                  await container
                      .read(taskTemplateRepositoryProvider)
                      .duplicateAsCustom(
                        sourceId: template.id,
                        newId: _ids.next(),
                        savedAtUtc: _nowUtc(container),
                      );
                },
                onSetHidden: (template, hidden) => container
                    .read(taskTemplateRepositoryProvider)
                    .setHidden(
                      id: template.id,
                      hidden: hidden,
                      changedAtUtc: _nowUtc(container),
                    ),
                onReorder: (kind, orderedIds) => container
                    .read(taskTemplateRepositoryProvider)
                    .reorderKind(
                      kind: kind,
                      orderedIds: orderedIds,
                      changedAtUtc: _nowUtc(container),
                    ),
                onRestoreSystemDefaults: () => container
                    .read(taskTemplateSynchronizerProvider)
                    .restoreDefaults(nowUtc: _nowUtc(container)),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _createCustomTemplate(
  BuildContext context,
  ProviderContainer container,
) async {
  final draft = await showTaskTemplateEditorDialog(
    context: context,
    initialDraft: TaskTemplateDraft.create(),
  );
  if (!context.mounted || draft == null) return;

  final template = draft.buildCustom(
    id: _ids.next(),
    displayOrder: 0,
    savedAtUtc: _nowUtc(container),
  );
  await container.read(taskTemplateRepositoryProvider).createCustom(template);
}

Future<void> _editCustomTemplate(
  BuildContext context,
  ProviderContainer container,
  TaskTemplate template,
) async {
  final draft = await showTaskTemplateEditorDialog(
    context: context,
    initialDraft: TaskTemplateDraft.fromTemplate(template),
  );
  if (!context.mounted || draft == null) return;

  final now = _nowUtc(container);
  final built = draft.buildCustom(
    id: template.id,
    displayOrder: template.displayOrder,
    savedAtUtc: now,
  );
  final updated = TaskTemplate(
    id: template.id,
    kind: TaskTemplateKind.custom,
    templateName: built.templateName,
    initialTaskTitle: built.initialTaskTitle,
    description: built.description,
    priority: built.priority,
    estimatedDurationMinutes: built.estimatedDurationMinutes,
    reminderDefaults: built.reminderDefaults,
    recurrenceDefault: built.recurrenceDefault,
    hidden: template.hidden,
    displayOrder: template.displayOrder,
    createdAtUtc: template.createdAtUtc,
    updatedAtUtc: now,
  );
  await container.read(taskTemplateRepositoryProvider).updateCustom(updated);
}

Future<void> _saveTaskDraftAsTemplate(
  BuildContext context,
  ProviderContainer container,
  TaskDetailsDraft source,
) async {
  final repository = container.read(taskTemplateRepositoryProvider);
  final existing = await repository.getAll();
  final customCount = existing
      .where((item) => item.kind == TaskTemplateKind.custom)
      .length;
  final now = _nowUtc(container);
  final id = _ids.next();
  final defaultName = source.title.trim().isEmpty
      ? 'قالب کار'
      : source.title.trim();

  final provisional = container
      .read(taskTemplateMapperProvider)
      .toCustomTemplate(
        source: source,
        id: id,
        templateName: defaultName,
        displayOrder: customCount,
        savedAtUtc: now,
      );

  if (!context.mounted) return;
  final edited = await showTaskTemplateEditorDialog(
    context: context,
    initialDraft: TaskTemplateDraft.fromTemplate(provisional),
  );
  if (!context.mounted || edited == null) return;

  await repository.createCustom(
    edited.buildCustom(
      id: id,
      displayOrder: customCount,
      savedAtUtc: _nowUtc(container),
    ),
  );
}

/// The legacy edit dialog and its saves (task, reminders, recurrence).
Future<void> editTask(
  BuildContext context,
  ProviderContainer container,
  TaskItem task,
) async {
  final initialReminderRules = await container
      .read(taskReminderRepositoryProvider)
      .getByTask(task.id);
  final initialRecurrence = await container
      .read(taskRecurrenceRepositoryProvider)
      .getByTask(task.id);
  if (!context.mounted) return;

  final result = await showTaskDetailsEditorDialog(
    context: context,
    mode: TaskDetailsDialogMode.edit,
    initialTask: task,
    initialReminderRules: initialReminderRules,
    initialRecurrenceRule: initialRecurrence.rule,
    onSaveAsTemplate: (draft) =>
        _saveTaskDraftAsTemplate(context, container, draft),
    now: container.read(appClockProvider).nowLocal,
    nextId: _ids.next,
  );
  if (!context.mounted || result == null) return;

  final repository = container.read(taskRepositoryProvider);
  await repository.update(result.task);
  if (!_sameReminderRules(initialReminderRules, result.reminderRules)) {
    final persisted = await repository.getById(result.task.id);
    if (persisted != null) {
      await container
          .read(taskReminderRulesServiceProvider)
          .replaceForTask(task: persisted, rules: result.reminderRules);
    }
  }
  if (initialRecurrence.rule != null || result.recurrenceRule != null) {
    await container
        .read(taskRecurrenceServiceProvider)
        .replaceRule(taskId: result.task.id, rule: result.recurrenceRule?.rule);
  }
}

/// Calendar occurrence handlers of the legacy `TaskCalendarBoard`.
Future<void> toggleOccurrenceCompleted(
  ProviderContainer container,
  TaskCalendarOccurrence occurrence,
) {
  return container
      .read(taskRecurrenceServiceProvider)
      .setCompleted(
        taskId: occurrence.task.id,
        originalLocalDateTime: occurrence.originalLocalDateTime,
        completed: !occurrence.isCompleted,
      );
}

Future<void> skipOccurrence(
  ProviderContainer container,
  TaskCalendarOccurrence occurrence,
) {
  return container
      .read(taskRecurrenceServiceProvider)
      .skip(
        taskId: occurrence.task.id,
        originalLocalDateTime: occurrence.originalLocalDateTime,
      );
}

Future<void> cancelOccurrence(
  ProviderContainer container,
  TaskCalendarOccurrence occurrence,
) {
  return container
      .read(taskRecurrenceServiceProvider)
      .cancel(
        taskId: occurrence.task.id,
        originalLocalDateTime: occurrence.originalLocalDateTime,
      );
}

Future<void> restoreOccurrence(
  ProviderContainer container,
  TaskCalendarOccurrence occurrence,
) {
  return container
      .read(taskRecurrenceServiceProvider)
      .restore(
        taskId: occurrence.task.id,
        originalLocalDateTime: occurrence.originalLocalDateTime,
      );
}

Future<void> moveOccurrence(
  ProviderContainer container,
  TaskCalendarOccurrence occurrence,
  DateTime movedGregorianLocal,
) {
  return container
      .read(taskRecurrenceServiceProvider)
      .moveToDeviceLocal(
        taskId: occurrence.task.id,
        originalLocalDateTime: occurrence.originalLocalDateTime,
        movedGregorianLocal: movedGregorianLocal,
      );
}

bool _sameReminderRules(
  List<TaskReminderRule> left,
  List<TaskReminderRule> right,
) {
  if (left.length != right.length) return false;
  final rightByTrigger = <Object, TaskReminderRule>{
    for (final rule in right) rule.trigger: rule,
  };
  for (final rule in left) {
    final other = rightByTrigger[rule.trigger];
    if (other == null ||
        other.id != rule.id ||
        other.enabled != rule.enabled ||
        other.privacyMode != rule.privacyMode) {
      return false;
    }
  }
  return true;
}
