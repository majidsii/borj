import 'dart:collection';

import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';

final class TaskRecurrenceBundle {
  TaskRecurrenceBundle({
    required this.taskId,
    required this.rule,
    List<TaskRecurrenceException> exceptions =
        const <TaskRecurrenceException>[],
    List<TaskOccurrenceCompletion> completions =
        const <TaskOccurrenceCompletion>[],
  }) : exceptions = UnmodifiableListView<TaskRecurrenceException>(
         List<TaskRecurrenceException>.from(exceptions),
       ),
       completions = UnmodifiableListView<TaskOccurrenceCompletion>(
         List<TaskOccurrenceCompletion>.from(completions),
       );

  final String taskId;
  final TaskRecurrenceRule? rule;
  final List<TaskRecurrenceException> exceptions;
  final List<TaskOccurrenceCompletion> completions;
}
