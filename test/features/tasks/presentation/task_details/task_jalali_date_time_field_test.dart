// Task 2.2 Heavy UI RED
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/features/tasks/presentation/task_details/task_jalali_date_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  Widget subject({
    required DateTime? valueLocal,
    required ValueChanged<DateTime?> onChanged,
    String? errorText,
    double width = 520,
  }) {
    return MaterialApp(
      theme: OriginalTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: width,
              child: TaskJalaliDateTimeField(
                label: 'شروع',
                valueLocal: valueLocal,
                onChanged: onChanged,
                errorText: errorText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('null state uses Persian unset labels and stable semantics', (
    tester,
  ) async {
    await tester.pumpWidget(subject(valueLocal: null, onChanged: (_) {}));

    expect(find.text('زمان شروع'), findsOneWidget);
    expect(find.text('تنظیم نشده'), findsNWidgets(2));
    expect(find.bySemanticsLabel('انتخاب تاریخ شروع'), findsOneWidget);
    expect(find.bySemanticsLabel('انتخاب ساعت شروع'), findsOneWidget);
    expect(find.bySemanticsLabel('پاک کردن زمان شروع'), findsNothing);
  });

  testWidgets('selected value renders Jalali date local time and clear', (
    tester,
  ) async {
    DateTime? changed;
    final value = Jalali(
      1405,
      5,
      13,
    ).toDateTime().copyWith(hour: 11, minute: 30);

    await tester.pumpWidget(
      subject(valueLocal: value, onChanged: (next) => changed = next),
    );

    expect(find.text('۱۳ مرداد ۱۴۰۵'), findsOneWidget);
    expect(find.text('۱۱:۳۰'), findsOneWidget);
    expect(find.bySemanticsLabel('پاک کردن زمان شروع'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('پاک کردن زمان شروع'));
    expect(changed, isNull);
  });

  testWidgets('custom Jalali date selection preserves local time', (
    tester,
  ) async {
    DateTime? changed;
    final value = Jalali(
      1405,
      5,
      10,
    ).toDateTime().copyWith(hour: 14, minute: 25);

    await tester.pumpWidget(
      subject(valueLocal: value, onChanged: (next) => changed = next),
    );

    await tester.tap(find.bySemanticsLabel('انتخاب تاریخ شروع'));
    await tester.pumpAndSettle();

    expect(find.text('انتخاب تاریخ شروع'), findsWidgets);
    expect(find.bySemanticsLabel('ماه قبل'), findsOneWidget);
    expect(find.bySemanticsLabel('ماه بعد'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('task-jalali-day-11')));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    final jalali = Jalali.fromDateTime(changed!);
    expect(jalali.year, 1405);
    expect(jalali.month, 5);
    expect(jalali.day, 11);
    expect(changed!.hour, 14);
    expect(changed!.minute, 25);
  });

  testWidgets('project time selector preserves selected date', (tester) async {
    DateTime? changed;
    final value = Jalali(
      1405,
      5,
      10,
    ).toDateTime().copyWith(hour: 14, minute: 25);

    await tester.pumpWidget(
      subject(valueLocal: value, onChanged: (next) => changed = next),
    );

    await tester.tap(find.bySemanticsLabel('انتخاب ساعت شروع'));
    await tester.pumpAndSettle();

    expect(find.text('انتخاب ساعت شروع'), findsWidgets);
    expect(find.bySemanticsLabel('افزایش ساعت'), findsOneWidget);
    expect(find.bySemanticsLabel('افزایش دقیقه'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('افزایش ساعت'));
    await tester.tap(find.text('تأیید ساعت'));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!.year, value.year);
    expect(changed!.month, value.month);
    expect(changed!.day, value.day);
    expect(changed!.hour, 15);
    expect(changed!.minute, 25);
  });

  testWidgets('inline error and narrow width remain stable', (tester) async {
    await tester.pumpWidget(
      subject(
        width: 260,
        valueLocal: null,
        onChanged: (_) {},
        errorText: 'زمان شروع نامعتبر است.',
      ),
    );

    expect(find.text('زمان شروع نامعتبر است.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
