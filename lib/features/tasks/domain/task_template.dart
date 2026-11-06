import 'dart:collection';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template_recurrence.dart';

enum TaskTemplateKind { system, custom }

final class TaskTemplateReminderDefault {
  const TaskTemplateReminderDefault({
    required this.trigger,
    required this.privacyMode,
  });

  final TaskReminderTrigger trigger;
  final NotificationPrivacyMode privacyMode;

  @override
  bool operator ==(Object other) {
    return other is TaskTemplateReminderDefault &&
        other.trigger == trigger &&
        other.privacyMode == privacyMode;
  }

  @override
  int get hashCode => Object.hash(trigger, privacyMode);
}

final class TaskTemplate {
  TaskTemplate({
    required String id,
    required this.kind,
    String? systemKey,
    required String templateName,
    required String initialTaskTitle,
    String? description,
    required this.priority,
    this.estimatedDurationMinutes,
    List<TaskTemplateReminderDefault> reminderDefaults = const [],
    this.recurrenceDefault,
    required this.hidden,
    required this.displayOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  }) : id = id.trim(),
       systemKey = _normalizeOptional(systemKey),
       templateName = templateName.trim(),
       initialTaskTitle = initialTaskTitle.trim(),
       description = _normalizeOptional(description),
       reminderDefaults = UnmodifiableListView<TaskTemplateReminderDefault>(
         List<TaskTemplateReminderDefault>.from(reminderDefaults),
       ) {
    if (this.id.isEmpty) {
      throw const ValidationFailure('شناسه قالب نمی‌تواند خالی باشد.');
    }

    if (this.templateName.isEmpty) {
      throw const ValidationFailure('نام قالب نمی‌تواند خالی باشد.');
    }

    switch (kind) {
      case TaskTemplateKind.system:
        if (this.systemKey == null) {
          throw const ValidationFailure(
            'قالب سیستمی باید کلید پایدار داشته باشد.',
          );
        }

      case TaskTemplateKind.custom:
        if (this.systemKey != null) {
          throw const ValidationFailure(
            'قالب سفارشی نمی‌تواند کلید سیستمی داشته باشد.',
          );
        }
    }

    if (priority < 0 || priority > 3) {
      throw const ValidationFailure('اولویت قالب نامعتبر است.');
    }

    final duration = estimatedDurationMinutes;
    if (duration != null && duration <= 0) {
      throw const ValidationFailure('مدت تخمینی قالب باید بیشتر از صفر باشد.');
    }

    if (displayOrder < 0) {
      throw const ValidationFailure('ترتیب نمایش قالب نامعتبر است.');
    }

    _validateUtc(createdAtUtc);
    _validateUtc(updatedAtUtc);

    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw const ValidationFailure(
        'زمان بروزرسانی قالب نمی‌تواند قبل از زمان ایجاد باشد.',
      );
    }

    final seenTriggers = <TaskReminderTrigger>{};
    for (final reminder in this.reminderDefaults) {
      if (!seenTriggers.add(reminder.trigger)) {
        throw const ValidationFailure(
          'قالب نمی‌تواند یادآور تکراری داشته باشد.',
        );
      }
    }
  }

  final String id;
  final TaskTemplateKind kind;
  final String? systemKey;

  final String templateName;
  final String initialTaskTitle;
  final String? description;

  final int priority;
  final int? estimatedDurationMinutes;

  final List<TaskTemplateReminderDefault> reminderDefaults;
  final TaskTemplateRecurrence? recurrenceDefault;

  final bool hidden;
  final int displayOrder;

  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get isSystem => kind == TaskTemplateKind.system;
  bool get isCustom => kind == TaskTemplateKind.custom;

  static String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static void _validateUtc(DateTime value) {
    if (!value.isUtc) {
      throw const ValidationFailure('زمان‌های قالب باید با UTC ذخیره شوند.');
    }
  }
}
