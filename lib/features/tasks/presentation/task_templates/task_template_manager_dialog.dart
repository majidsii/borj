import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:flutter/material.dart';

final class TaskTemplateManagerDialog extends StatelessWidget {
  const TaskTemplateManagerDialog({
    required this.templates,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onSetHidden,
    required this.onReorder,
    required this.onRestoreSystemDefaults,
    super.key,
  });

  final List<TaskTemplate> templates;
  final VoidCallback onCreate;
  final ValueChanged<TaskTemplate> onEdit;
  final Future<void> Function(TaskTemplate template) onDelete;
  final Future<void> Function(TaskTemplate template) onDuplicate;
  final Future<void> Function(TaskTemplate template, bool hidden) onSetHidden;
  final Future<void> Function(TaskTemplateKind kind, List<String> orderedIds)
  onReorder;
  final Future<void> Function() onRestoreSystemDefaults;

  @override
  Widget build(BuildContext context) {
    final systems =
        templates.where((item) => item.kind == TaskTemplateKind.system).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final customs =
        templates.where((item) => item.kind == TaskTemplateKind.custom).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Material(
      child: SizedBox(
        width: 760,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'مدیریت قالب‌ها',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('قالب جدید'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TemplateSection(
              title: 'قالب‌های سیستمی',
              kind: TaskTemplateKind.system,
              templates: systems,
              onEdit: onEdit,
              onDelete: onDelete,
              onDuplicate: onDuplicate,
              onSetHidden: onSetHidden,
              onReorder: onReorder,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async => onRestoreSystemDefaults(),
              icon: const Icon(Icons.restore),
              label: const Text('بازگردانی قالب‌های سیستمی'),
            ),
            const SizedBox(height: 24),
            _TemplateSection(
              title: 'قالب‌های شخصی',
              kind: TaskTemplateKind.custom,
              templates: customs,
              onEdit: onEdit,
              onDelete: onDelete,
              onDuplicate: onDuplicate,
              onSetHidden: onSetHidden,
              onReorder: onReorder,
            ),
          ],
        ),
      ),
    );
  }
}

final class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.title,
    required this.kind,
    required this.templates,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onSetHidden,
    required this.onReorder,
  });

  final String title;
  final TaskTemplateKind kind;
  final List<TaskTemplate> templates;
  final ValueChanged<TaskTemplate> onEdit;
  final Future<void> Function(TaskTemplate template) onDelete;
  final Future<void> Function(TaskTemplate template) onDuplicate;
  final Future<void> Function(TaskTemplate template, bool hidden) onSetHidden;
  final Future<void> Function(TaskTemplateKind kind, List<String> orderedIds)
  onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: templates.length,
          onReorderItem: (oldIndex, newIndex) async {
            final ids = templates.map((item) => item.id).toList();
            final moved = ids.removeAt(oldIndex);
            ids.insert(newIndex, moved);
            await onReorder(kind, ids);
          },
          itemBuilder: (context, index) {
            final template = templates[index];
            final isSystem = template.kind == TaskTemplateKind.system;

            return Card(
              key: ValueKey<String>(template.id),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator),
                ),
                title: Row(
                  children: <Widget>[
                    Expanded(child: Text(template.templateName)),
                    Chip(label: Text(isSystem ? 'سیستمی' : 'شخصی')),
                  ],
                ),
                subtitle: Text(
                  template.hidden ? 'مخفی از انتخاب سریع' : 'فعال',
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: <Widget>[
                    if (!isSystem)
                      IconButton(
                        tooltip: 'ویرایش ${template.templateName}',
                        onPressed: () => onEdit(template),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    IconButton(
                      tooltip: 'تکثیر ${template.templateName}',
                      onPressed: () async => onDuplicate(template),
                      icon: const Icon(Icons.copy_outlined),
                    ),
                    IconButton(
                      tooltip: template.hidden
                          ? 'نمایش ${template.templateName}'
                          : 'مخفی‌کردن ${template.templateName}',
                      onPressed: () async =>
                          onSetHidden(template, !template.hidden),
                      icon: Icon(
                        template.hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    if (!isSystem)
                      IconButton(
                        tooltip: 'حذف ${template.templateName}',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('حذف قالب'),
                              content: Text(
                                'قالب «${template.templateName}» حذف شود؟',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('انصراف'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await onDelete(template);
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
