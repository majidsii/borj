import 'package:borj/app/router/app_router.dart';
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/original_controls.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/tasks/data/drift_task_template_repository.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:borj/features/tasks/domain/task_template.dart';
import 'package:borj/features/tasks/presentation/task_timer/task_timer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../support/borj_test_app.dart';

// Ported from the deleted legacy tasks panel tests (details, templates,
// timer): the same legacy dialogs, now opened from the Tasks screen.
final DateTime _now = DateTime.utc(2026, 11, 11, 10);

TaskItem _task({
  String id = 'edit-task',
  String title = 'کار موجود',
  String? description,
  DateTime? start,
  DateTime? due,
  int? estimate,
}) => TaskItem(
  id: id,
  displayNumber: 1,
  title: title,
  description: description,
  priority: 2,
  status: TaskStatus.planned,
  positionInStatus: 0,
  startAtUtc: start,
  dueAtUtc: due,
  estimatedDurationMinutes: estimate,
  createdAtUtc: DateTime.utc(2026, 8, 1, 8),
  updatedAtUtc: DateTime.utc(2026, 8, 1, 9),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<TaskItem> tasks = const [],
  Future<void> Function(ProviderContainer c)? extra,
}) async {
  useWindowSize(tester, const Size(900, 1000));
  final c = await pumpBorjTestApp(
    tester,
    overrides: [
      appClockProvider.overrideWithValue(
        FixedAppClock(utcValue: _now, localValue: _now),
      ),
    ],
    seed: (c) async {
      for (final t in tasks) {
        await c.read(taskRepositoryProvider).create(t);
      }
      await extra?.call(c);
    },
  );
  c.read(appRouterProvider).go('/tasks?view=list');
  await tester.pumpAndSettle();
  return c;
}

Future<void> _io(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pumpAndSettle();
}

Future<List<TaskItem>> _all(WidgetTester tester, ProviderContainer c) async =>
    (await tester.runAsync(
      () => c.read(taskRepositoryProvider).watchAll().first,
    ))!;

Finder _hint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Future<void> _press(WidgetTester tester, Finder f) async {
  final p = tester.widget<OriginalPressable>(
    find.ancestor(of: f, matching: find.byType(OriginalPressable)).first,
  );
  p.onPressed!();
  await tester.pumpAndSettle();
}

Future<void> _primary(WidgetTester tester, String label) async {
  final f = find.byWidgetPredicate(
    (w) => w is OriginalPrimaryButton && w.label == label,
  );
  expect(f, findsOneWidget);
  tester.widget<OriginalPrimaryButton>(f).onPressed!();
  await _io(tester);
}

Future<void> _option(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const ValueKey('tasks-options')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('add with details persists fields', (tester) async {
    final c = await _pump(tester);
    await _option(tester, 'option-add-details');
    await tester.enterText(_hint('عنوان کار'), 'کار برنامه‌ریزی');
    await tester.enterText(
      _hint('جزئیات، خروجی مورد انتظار یا نکات مهم…'),
      'شرح برنامه‌ریزی',
    );
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('ساعت مدت تخمینی'),
        matching: find.byType(TextField),
      ),
      '1',
    );
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('دقیقه مدت تخمینی'),
        matching: find.byType(TextField),
      ),
      '30',
    );
    await _primary(tester, 'افزودن کار');
    final task = (await _all(tester, c)).single;
    expect(task.title, 'کار برنامه‌ریزی');
    expect(task.description, 'شرح برنامه‌ریزی');
    expect(task.estimatedDurationMinutes, 90);
    expect(task.status, TaskStatus.planned);
    expect(task.positionInStatus, 0);
    expect(task.displayNumber, 1);
    expect(find.text('کار برنامه‌ریزی'), findsWidgets);
  });

  testWidgets('full edit clears optional fields and keeps identity', (
    tester,
  ) async {
    final startLocal = Jalali(
      1405,
      5,
      13,
    ).toDateTime().copyWith(hour: 11, minute: 30);
    final task = _task(
      description: 'شرح موجود',
      start: startLocal.toUtc(),
      due: startLocal.copyWith(hour: 15, minute: 0).toUtc(),
      estimate: 90,
    );
    final c = await _pump(tester, tasks: [task]);
    await tester.tap(find.text('کار موجود'));
    await tester.pumpAndSettle();
    await tester.enterText(_hint('جزئیات، خروجی مورد انتظار یا نکات مهم…'), '');
    for (final l in [
      'پاک کردن زمان شروع',
      'پاک کردن زمان سررسید',
      'پاک کردن مدت تخمینی',
    ]) {
      await _press(tester, find.bySemanticsLabel(l));
    }
    await _primary(tester, 'ذخیره تغییرات');
    final u = (await _all(tester, c)).single;
    expect(u.id, task.id);
    expect(u.displayNumber, task.displayNumber);
    expect(u.createdAtUtc, task.createdAtUtc);
    expect(u.status, task.status);
    expect(u.positionInStatus, task.positionInStatus);
    expect(u.description, isNull);
    expect(u.startAtUtc, isNull);
    expect(u.dueAtUtc, isNull);
    expect(u.estimatedDurationMinutes, isNull);
  });

  testWidgets(
    'template picker prefills details and persists nothing until add',
    (tester) async {
      final c = await _pump(
        tester,
        extra: (c) => DriftTaskTemplateRepository(c.read(appDatabaseProvider))
            .createCustom(
              TaskTemplate(
                id: 'picker-template',
                kind: TaskTemplateKind.custom,
                templateName: 'قالب آماده',
                initialTaskTitle: 'عنوان از قالب',
                description: 'شرح از قالب',
                priority: 2,
                estimatedDurationMinutes: 40,
                hidden: false,
                displayOrder: 0,
                createdAtUtc: DateTime.utc(2026, 8, 8, 8),
                updatedAtUtc: DateTime.utc(2026, 8, 8, 8),
              ),
            ),
      );
      await _option(tester, 'option-template-pick');
      expect(find.text('قالب آماده'), findsOneWidget);
      await tester.tap(find.text('قالب آماده'));
      await tester.pumpAndSettle();
      expect(await _all(tester, c), isEmpty);
      expect(
        tester.widget<TextField>(_hint('عنوان کار')).controller!.text,
        'عنوان از قالب',
      );
      expect(find.text('افزودن کار با جزئیات'), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(await _all(tester, c), isEmpty);

      await _option(tester, 'option-template-pick');
      await tester.tap(find.text('قالب آماده'));
      await tester.pumpAndSettle();
      await _primary(tester, 'افزودن کار');
      final t = (await _all(tester, c)).single;
      expect(t.title, 'عنوان از قالب');
      expect(t.description, 'شرح از قالب');
      expect(t.priority, 2);
      expect(t.estimatedDurationMinutes, 40);
    },
  );

  testWidgets('edit save-as-template persists a custom template', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      tasks: [
        _task(
          id: 'source-task',
          title: 'قالب از کار موجود',
          description: 'شرح منبع',
          estimate: 70,
        ),
      ],
    );
    await tester.tap(find.text('قالب از کار موجود'));
    await tester.pumpAndSettle();
    final save = find.byWidgetPredicate(
      (w) => w is OriginalGhostButton && w.label == 'ذخیره به‌عنوان قالب',
    );
    expect(save, findsOneWidget);
    tester.widget<OriginalGhostButton>(save).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('نام قالب'), findsOneWidget);
    await tester.tap(find.text('ذخیره قالب'));
    await _io(tester);
    final templates = await tester.runAsync(
      () => DriftTaskTemplateRepository(c.read(appDatabaseProvider)).getAll(),
    );
    final custom = templates!
        .where((t) => t.kind == TaskTemplateKind.custom)
        .toList();
    expect(custom, hasLength(1));
    expect(custom.single.templateName, 'قالب از کار موجود');
    expect(custom.single.initialTaskTitle, 'قالب از کار موجود');
    expect(custom.single.description, 'شرح منبع');
    expect(custom.single.estimatedDurationMinutes, 70);
    // The source task is untouched and its editor stays open.
    expect((await _all(tester, c)).single.title, 'قالب از کار موجود');
    expect(find.text('ویرایش کار'), findsWidgets);
  });

  testWidgets('active timer strip names the task', (tester) async {
    await _pump(
      tester,
      tasks: [_task(id: 'tt', title: 'کار دارای تایمر')],
      extra: (c) => c.read(taskTimerServiceProvider).start('tt'),
    );
    expect(find.byKey(const ValueKey('global-active-timer')), findsOneWidget);
    expect(find.text('کار دارای تایمر'), findsWidgets);
  });

  testWidgets('TaskTimeTotalBadge shows accumulated time', (tester) async {
    final c = await _pump(
      tester,
      tasks: [_task(id: 'tb', title: 'کار زمان‌دار')],
      extra: (c) => c
          .read(taskTimerServiceProvider)
          .addManualDuration(taskId: 'tb', durationMinutes: 30),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: OriginalTheme.light(),
          home: const Scaffold(body: TaskTimeTotalBadge(taskId: 'tb')),
        ),
      ),
    );
    await _io(tester);
    expect(find.byKey(const ValueKey('task-time-badge-tb')), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
  });
}
