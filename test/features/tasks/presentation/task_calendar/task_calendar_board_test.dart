import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/recurrence/recurrence_end.dart';
import 'package:borj/core/recurrence/recurrence_local_date_time.dart';
import 'package:borj/core/recurrence/recurrence_rule.dart';
import 'package:borj/core/recurrence/recurrence_time_zone.dart';
import 'package:borj/features/tasks/domain/task_calendar_occurrence.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_occurrence_completion.dart';
import 'package:borj/features/tasks/domain/task_recurrence_exception.dart';
import 'package:borj/features/tasks/domain/task_recurrence_rule.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_calendar/task_calendar_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  final nowUtc = DateTime.utc(2026, 8, 6, 8);
  final task = TaskItem(
    id: 'calendar-task',
    displayNumber: 1,
    title: 'کار تقویم',
    priority: 2,
    status: TaskStatus.planned,
    positionInStatus: 0,
    dueAtUtc: DateTime.utc(2026, 8, 7, 9),
    createdAtUtc: nowUtc,
    updatedAtUtc: nowUtc,
  );
  final rule = TaskRecurrenceRule(
    id: 'calendar-rule',
    taskId: task.id,
    rule: RecurrenceRule.daily(
      anchorLocalDateTime: RecurrenceLocalDateTime(
        year: 2026,
        month: 8,
        day: 7,
        hour: 9,
      ),
      timeZone: RecurrenceTimeZone.fixed('Etc/UTC'),
      end: RecurrenceEnd.afterCount(3),
    ),
    createdAtUtc: nowUtc,
    updatedAtUtc: nowUtc,
  );

  Widget subject({
    required Future<void> Function(TaskCalendarOccurrence) onComplete,
  }) {
    return MaterialApp(
      theme: OriginalTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: TaskCalendarBoard(
              tasks: <TaskItem>[task],
              rules: <TaskRecurrenceRule>[rule],
              exceptions: const <TaskRecurrenceException>[],
              completions: const <TaskOccurrenceCompletion>[],
              floatingTimeZoneId: 'Etc/UTC',
              now: () => DateTime(2026, 8, 7, 10),
              onToggleCompleted: onComplete,
              onSkip: (_) async {},
              onCancel: (_) async {},
              onRestore: (_) async {},
              onMove: (_, _) async {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Calendar as a monthly grid with selected-day tasks', (
    tester,
  ) async {
    await tester.pumpWidget(subject(onComplete: (_) async {}));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('task-calendar-board')),
      findsOneWidget,
    );
    expect(find.text('کار تقویم'), findsOneWidget);
    expect(find.text('انجام شد'), findsOneWidget);
    expect(find.text('امروز'), findsOneWidget);
  });

  testWidgets('completion action returns the stable occurrence identity', (
    tester,
  ) async {
    TaskCalendarOccurrence? completed;
    await tester.pumpWidget(
      subject(onComplete: (value) async => completed = value),
    );
    await tester.pumpAndSettle();

    final completeButton = find.text('انجام شد');

    await tester.ensureVisible(completeButton);
    await tester.pumpAndSettle();
    await tester.tap(completeButton);
    await tester.pumpAndSettle();

    expect(completed, isNotNull);
    expect(completed!.occurrenceKey, 'calendar-task@2026-08-07T09:00');
  });

  testWidgets('calendar can switch to Gregorian display', (tester) async {
    await tester.pumpWidget(subject(onComplete: (_) async {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('میلادی'));
    await tester.pumpAndSettle();

    expect(find.textContaining('اوت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
