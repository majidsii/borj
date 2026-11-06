import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/features/tasks/domain/task_reminder_trigger.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 7, 10);
  final updatedAt = DateTime.utc(2026, 8, 7, 11);

  TaskTemplate custom({
    String id = 'template-1',
    String templateName = '  جلسه کاری  ',
    String initialTaskTitle = '  جلسه با …  ',
    int priority = 2,
    int? estimatedDurationMinutes = 60,
    int displayOrder = 0,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    List<TaskTemplateReminderDefault> reminderDefaults = const [],
  }) {
    return TaskTemplate(
      id: id,
      kind: TaskTemplateKind.custom,
      templateName: templateName,
      initialTaskTitle: initialTaskTitle,
      priority: priority,
      estimatedDurationMinutes: estimatedDurationMinutes,
      reminderDefaults: reminderDefaults,
      hidden: false,
      displayOrder: displayOrder,
      createdAtUtc: createdAtUtc ?? createdAt,
      updatedAtUtc: updatedAtUtc ?? updatedAt,
    );
  }

  group('TaskTemplate', () {
    test('normalizes reusable text fields', () {
      final template = custom();

      expect(template.templateName, 'جلسه کاری');
      expect(template.initialTaskTitle, 'جلسه با …');
    });

    test('allows an empty initial task title', () {
      final template = custom(initialTaskTitle: '   ');

      expect(template.initialTaskTitle, '');
    });

    test('rejects a blank template name', () {
      expect(
        () => custom(templateName: '   '),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('requires a system key for system templates', () {
      expect(
        () => TaskTemplate(
          id: 'system-1',
          kind: TaskTemplateKind.system,
          templateName: 'جلسه',
          initialTaskTitle: 'جلسه با …',
          priority: 2,
          hidden: false,
          displayOrder: 0,
          createdAtUtc: createdAt,
          updatedAtUtc: updatedAt,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects a system key for custom templates', () {
      expect(
        () => TaskTemplate(
          id: 'custom-1',
          kind: TaskTemplateKind.custom,
          systemKey: 'meeting',
          templateName: 'جلسه',
          initialTaskTitle: '',
          priority: 2,
          hidden: false,
          displayOrder: 0,
          createdAtUtc: createdAt,
          updatedAtUtc: updatedAt,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('accepts a stable system key for system templates', () {
      final template = TaskTemplate(
        id: 'system-meeting',
        kind: TaskTemplateKind.system,
        systemKey: 'meeting',
        templateName: 'جلسه',
        initialTaskTitle: 'جلسه با …',
        priority: 2,
        hidden: false,
        displayOrder: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      );

      expect(template.systemKey, 'meeting');
    });

    test('rejects priority outside zero through three', () {
      expect(() => custom(priority: -1), throwsA(isA<ValidationFailure>()));
      expect(() => custom(priority: 4), throwsA(isA<ValidationFailure>()));
    });

    test('rejects non-positive estimated duration', () {
      expect(
        () => custom(estimatedDurationMinutes: 0),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => custom(estimatedDurationMinutes: -1),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects negative display order', () {
      expect(() => custom(displayOrder: -1), throwsA(isA<ValidationFailure>()));
    });

    test('requires UTC timestamps', () {
      expect(
        () => custom(createdAtUtc: DateTime(2026, 8, 7, 10)),
        throwsA(isA<ValidationFailure>()),
      );

      expect(
        () => custom(updatedAtUtc: DateTime(2026, 8, 7, 11)),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects updated timestamp before created timestamp', () {
      expect(
        () => custom(
          createdAtUtc: DateTime.utc(2026, 8, 7, 12),
          updatedAtUtc: DateTime.utc(2026, 8, 7, 11),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects duplicate reminder triggers', () {
      expect(
        () => custom(
          reminderDefaults: const [
            TaskTemplateReminderDefault(
              trigger: TaskReminderTrigger.atDue,
              privacyMode: NotificationPrivacyMode.full,
            ),
            TaskTemplateReminderDefault(
              trigger: TaskReminderTrigger.atDue,
              privacyMode: NotificationPrivacyMode.private,
            ),
          ],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
