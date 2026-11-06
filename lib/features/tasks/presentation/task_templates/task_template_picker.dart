import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:flutter/material.dart';

final class TaskTemplatePicker extends StatelessWidget {
  const TaskTemplatePicker({
    required this.templates,
    required this.onSelected,
    required this.onManage,
    super.key,
  });

  final List<TaskTemplate> templates;
  final ValueChanged<TaskTemplate> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final systems =
        templates
            .where(
              (item) => item.kind == TaskTemplateKind.system && !item.hidden,
            )
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final customs =
        templates
            .where(
              (item) => item.kind == TaskTemplateKind.custom && !item.hidden,
            )
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: 'قالب‌های سیستمی',
            templates: systems,
            onSelected: onSelected,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'قالب‌های شخصی',
            templates: customs,
            onSelected: onSelected,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.tune),
              label: const Text('مدیریت قالب‌ها'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.templates,
    required this.onSelected,
  });

  final String title;
  final List<TaskTemplate> templates;
  final ValueChanged<TaskTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (templates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('قالب فعالی وجود ندارد.'),
          )
        else
          ...templates.map(
            (template) => Card(
              child: ListTile(
                onTap: () => onSelected(template),
                title: Text(template.templateName),
                subtitle: Text(
                  [
                    if (template.initialTaskTitle.isNotEmpty)
                      template.initialTaskTitle,
                    if (template.estimatedDurationMinutes != null)
                      '${template.estimatedDurationMinutes} دقیقه',
                  ].join(' • '),
                ),
                trailing: const Icon(Icons.chevron_left),
              ),
            ),
          ),
      ],
    );
  }
}
