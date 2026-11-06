import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/presentation/task_templates/task_template_recurrence_draft.dart';

final class TaskTemplateDraft {
  TaskTemplateDraft({
    required this.templateName,
    required this.initialTaskTitle,
    required this.description,
    required this.priority,
    required this.estimatedHours,
    required this.estimatedMinutes,
    required List<TaskTemplateReminderDefault> reminderDefaults,
    required this.recurrence,
  }) : reminderDefaults = List<TaskTemplateReminderDefault>.from(
         reminderDefaults,
       );

  factory TaskTemplateDraft.create() {
    return TaskTemplateDraft(
      templateName: '',
      initialTaskTitle: '',
      description: '',
      priority: 0,
      estimatedHours: 0,
      estimatedMinutes: 0,
      reminderDefaults: const <TaskTemplateReminderDefault>[],
      recurrence: TaskTemplateRecurrenceDraft.create(),
    );
  }

  factory TaskTemplateDraft.fromTemplate(TaskTemplate template) {
    final duration = template.estimatedDurationMinutes ?? 0;
    return TaskTemplateDraft(
      templateName: template.templateName,
      initialTaskTitle: template.initialTaskTitle,
      description: template.description ?? '',
      priority: template.priority,
      estimatedHours: duration ~/ 60,
      estimatedMinutes: duration % 60,
      reminderDefaults: template.reminderDefaults,
      recurrence: TaskTemplateRecurrenceDraft.fromRecurrence(
        template.recurrenceDefault,
      ),
    );
  }

  String templateName;
  String initialTaskTitle;
  String description;
  int priority;
  int estimatedHours;
  int estimatedMinutes;
  final List<TaskTemplateReminderDefault> reminderDefaults;
  TaskTemplateRecurrenceDraft recurrence;

  String? validate() {
    if (templateName.trim().isEmpty) {
      return 'نام قالب نمی‌تواند خالی باشد.';
    }
    if (priority < 0 || priority > 3) {
      return 'اولویت قالب نامعتبر است.';
    }
    if (estimatedHours < 0 || estimatedMinutes < 0 || estimatedMinutes > 59) {
      return 'مدت تخمینی قالب نامعتبر است.';
    }
    return recurrence.validate();
  }

  TaskTemplate buildCustom({
    required String id,
    required int displayOrder,
    required DateTime savedAtUtc,
  }) {
    final error = validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final totalMinutes = estimatedHours * 60 + estimatedMinutes;
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.custom,
      templateName: templateName,
      initialTaskTitle: initialTaskTitle,
      description: description,
      priority: priority,
      estimatedDurationMinutes: totalMinutes == 0 ? null : totalMinutes,
      reminderDefaults: reminderDefaults,
      recurrenceDefault: recurrence.build(),
      hidden: false,
      displayOrder: displayOrder,
      createdAtUtc: savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }
}
