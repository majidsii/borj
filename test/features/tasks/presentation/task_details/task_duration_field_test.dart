// Task 2.2 Heavy UI RED
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/features/tasks/presentation/task_details/task_duration_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({
    required int hours,
    required int minutes,
    required ValueChanged<int> onHoursChanged,
    required ValueChanged<int> onMinutesChanged,
    required VoidCallback onClear,
    String? errorText,
    double width = 360,
  }) {
    return MaterialApp(
      theme: OriginalTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: width,
              child: TaskDurationField(
                hours: hours,
                minutes: minutes,
                onHoursChanged: onHoursChanged,
                onMinutesChanged: onMinutesChanged,
                onClear: onClear,
                errorText: errorText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Persian labels and controlled empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        hours: 0,
        minutes: 0,
        onHoursChanged: (_) {},
        onMinutesChanged: (_) {},
        onClear: () {},
      ),
    );

    expect(find.text('مدت تخمینی'), findsOneWidget);
    expect(find.text('ساعت'), findsWidgets);
    expect(find.text('دقیقه'), findsWidgets);
    expect(find.bySemanticsLabel('ساعت مدت تخمینی'), findsOneWidget);
    expect(find.bySemanticsLabel('دقیقه مدت تخمینی'), findsOneWidget);
    expect(find.bySemanticsLabel('پاک کردن مدت تخمینی'), findsOneWidget);
  });

  testWidgets('emits numeric hour and minute values', (tester) async {
    int? hours;
    int? minutes;

    await tester.pumpWidget(
      subject(
        hours: 0,
        minutes: 0,
        onHoursChanged: (value) => hours = value,
        onMinutesChanged: (value) => minutes = value,
        onClear: () {},
      ),
    );

    final hoursField = find.descendant(
      of: find.bySemanticsLabel('ساعت مدت تخمینی'),
      matching: find.byType(TextField),
    );
    final minutesField = find.descendant(
      of: find.bySemanticsLabel('دقیقه مدت تخمینی'),
      matching: find.byType(TextField),
    );

    await tester.enterText(hoursField, '12');
    await tester.enterText(minutesField, '59');

    expect(hours, 12);
    expect(minutes, 59);
  });

  testWidgets('clear action is explicit and inline error is visible', (
    tester,
  ) async {
    var cleared = false;

    await tester.pumpWidget(
      subject(
        hours: 2,
        minutes: 15,
        onHoursChanged: (_) {},
        onMinutesChanged: (_) {},
        onClear: () => cleared = true,
        errorText: 'دقیقه مدت تخمینی باید بین ۰ تا ۵۹ باشد.',
      ),
    );

    expect(
      find.text('دقیقه مدت تخمینی باید بین ۰ تا ۵۹ باشد.'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('پاک کردن مدت تخمینی'));
    expect(cleared, isTrue);
  });

  testWidgets('narrow width wraps without overflow', (tester) async {
    await tester.pumpWidget(
      subject(
        width: 210,
        hours: 1,
        minutes: 30,
        onHoursChanged: (_) {},
        onMinutesChanged: (_) {},
        onClear: () {},
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('task-duration-hours')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-duration-minutes')),
      findsOneWidget,
    );
  });
}
