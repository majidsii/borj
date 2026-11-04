import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/quick_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: QuickEntryScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows title, examples and submit', (tester) async {
    await pump(tester);
    expect(find.text('ورود سریع'), findsOneWidget);
    expect(find.text('ثبت'), findsOneWidget);
    expect(find.text('هر ماه پنجم اجاره ۱۲ میلیون'), findsOneWidget);
    expect(find.text('۲۰ دقیقه کتاب خواندم'), findsOneWidget);
  });

  testWidgets('typing spawns chips and the result card; deleting merges', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.byType(TextField),
      'ناهار با علی ۴۵۰ تومن از کارت ملت',
    );
    await tester.pumpAndSettle();
    expect(find.text('۴۵۰ تومان'), findsWidgets);
    expect(find.text('خوراک'), findsWidgets);
    expect(find.text('کارت ملت'), findsWidgets);
    expect(find.text('خرج'), findsOneWidget);
    expect(find.text('ناهار با علی'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ناهار با علی');
    await tester.pumpAndSettle();
    expect(find.text('۴۵۰ تومان'), findsNothing);
    expect(find.text('کارت ملت'), findsNothing);
    expect(find.text('خوراک'), findsWidgets);
  });

  testWidgets('tapping an example fills the field and submit confirms', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('هر ماه پنجم اجاره ۱۲ میلیون'));
    await tester.pumpAndSettle();
    expect(find.text('پرداخت تکراری'), findsOneWidget);
    expect(find.text('هر ماه · روز ۵'), findsWidgets);

    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ثبت شد'), findsOneWidget);
    expect(find.text('پرداخت تکراری'), findsNothing);
  });

  testWidgets('tapping a chip removes its token', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'فردا ساعت ۱۰ دندانپزشکی');
    await tester.pumpAndSettle();
    expect(find.text('یادآور'), findsOneWidget);
    await tester.tap(find.text('۱۰:۰۰').first);
    await tester.pumpAndSettle();
    expect(find.text('۱۰:۰۰'), findsNothing);
  });
}
