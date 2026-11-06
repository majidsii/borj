import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:borj/features/tasks/presentation/task_details/task_details_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = openTestDatabase();
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Widget subject({String? taskId}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: TaskDetailsForm(
                initialDraft: TaskDetailsDraft.create(
                  nowLocal: DateTime(2026, 8, 6, 8),
                ),
                titleHint: 'عنوان',
                taskId: taskId,
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('create mode keeps timer controls hidden', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('task-details-timer-panel')),
      findsNothing,
    );
  });

  testWidgets('edit mode exposes persisted timer controls', (tester) async {
    await tester.pumpWidget(subject(taskId: 'task-1'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('task-details-timer-panel')),
      findsOneWidget,
    );
    expect(find.text('زمان ثبت‌شده'), findsOneWidget);
  });
}
