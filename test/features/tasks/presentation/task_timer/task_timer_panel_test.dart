import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/data/drift_task_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/presentation/task_timer/task_timer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late _MutableClock clock;
  final start = DateTime.utc(2026, 8, 6, 8);

  setUp(() async {
    database = openTestDatabase();
    clock = _MutableClock(start);
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        appClockProvider.overrideWithValue(clock),
      ],
    );
    await DriftTaskRepository(database).create(
      TaskItem(
        id: 'task-1',
        displayNumber: 1,
        title: 'کار تایمر',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Widget subject({String taskId = 'task-1'}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 620,
                child: TaskTimerPanel(taskId: taskId),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('starts pauses resumes and stops the persisted timer', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('task-timer-start')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('task-timer-pause')),
      findsOneWidget,
    );

    clock.value = start.add(const Duration(minutes: 2));
    await tester.tap(find.byKey(const ValueKey<String>('task-timer-pause')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('task-timer-resume')),
      findsOneWidget,
    );

    clock.value = start.add(const Duration(minutes: 5));
    await tester.tap(find.byKey(const ValueKey<String>('task-timer-resume')));
    await tester.pumpAndSettle();

    clock.value = start.add(const Duration(minutes: 8));
    await tester.tap(find.byKey(const ValueKey<String>('task-timer-stop')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('task-timer-start')),
      findsOneWidget,
    );
    expect(find.text('00:05:00'), findsWidgets);
  });

  testWidgets('manual dialog stores duration and note', (tester) async {
    clock.value = start.add(const Duration(hours: 2));
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('task-time-manual-add')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('manual-time-duration')),
        matching: find.byType(TextField),
      ),
      '25',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('manual-time-note')),
        matching: find.byType(TextField),
      ),
      'جلسه',
    );
    await tester.tap(find.byKey(const ValueKey<String>('manual-time-save')));
    await tester.pumpAndSettle();

    expect(find.text('جلسه'), findsOneWidget);
    expect(find.text('00:25:00'), findsWidgets);
  });

  testWidgets('shows another-task warning while global timer is occupied', (
    tester,
  ) async {
    await DriftTaskRepository(database).create(
      TaskItem(
        id: 'task-2',
        displayNumber: 2,
        title: 'کار دیگر',
        priority: 0,
        status: TaskStatus.planned,
        positionInStatus: 1,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
    );
    await container.read(taskTimerServiceProvider).start('task-2');

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('other-task-timer-active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-timer-start')),
      findsNothing,
    );
  });

  testWidgets('stopped entry can be deleted from history', (tester) async {
    clock.value = start.add(const Duration(hours: 1));
    await container
        .read(taskTimerServiceProvider)
        .addManualDuration(taskId: 'task-1', durationMinutes: 15);
    final entry =
        (await container.read(taskTimeRepositoryProvider).getByTask('task-1'))
            .single;

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey<String>('time-entry-delete-${entry.id}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('time-entry-delete-${entry.id}')),
      findsNothing,
    );
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime nowLocal() => value.toLocal();

  @override
  DateTime nowUtc() => value.toUtc();
}
