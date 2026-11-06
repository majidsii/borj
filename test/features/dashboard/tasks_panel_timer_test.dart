import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  final now = DateTime.utc(2026, 8, 6, 8);

  setUp(() async {
    database = openTestDatabase();
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        appClockProvider.overrideWithValue(
          FixedAppClock(utcValue: now, localValue: now.toLocal()),
        ),
      ],
    );
    await container
        .read(taskRepositoryProvider)
        .create(
          TaskItem(
            id: 'panel-timer-task',
            displayNumber: 1,
            title: 'کار دارای تایمر',
            priority: 1,
            status: TaskStatus.planned,
            positionInStatus: 0,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: SizedBox(width: 780, child: TasksPanel()),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('panel shows global active timer with task title', (
    tester,
  ) async {
    await container.read(taskTimerServiceProvider).start('panel-timer-task');

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('global-active-timer')),
      findsOneWidget,
    );
    expect(find.text('کار دارای تایمر'), findsWidgets);
  });

  testWidgets('task row shows accumulated time badge', (tester) async {
    await container
        .read(taskTimerServiceProvider)
        .addManualDuration(taskId: 'panel-timer-task', durationMinutes: 30);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('task-time-badge-panel-timer-task')),
      findsOneWidget,
    );
    expect(find.text('30m'), findsOneWidget);
  });
}
