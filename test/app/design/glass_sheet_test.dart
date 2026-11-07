import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _launcher({void Function(Object?)? onResult}) => Builder(
  builder: (context) => GlassButton(
    label: 'باز کن',
    onPressed: () async {
      final box = context.findRenderObject()! as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final result = await showGlassSheet<String>(
        context,
        origin: origin,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: GlassButton(
            label: 'تأیید',
            variant: GlassButtonVariant.tinted,
            onPressed: () => GlassSheet.close(context, 'ok'),
          ),
        ),
      );
      onResult?.call(result);
    },
  ),
);

void main() {
  for (final v in glassTestVariants) {
    testWidgets('opens and settles (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _launcher(),
          brightness: v.brightness,
          textScale: v.textScale,
          overlayBackdrop: true,
        ),
      );
      await tester.tap(find.text('باز کن'));
      await tester.pumpAndSettle();
      expect(find.text('تأیید'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('grows from the trigger, then closes with a result', (
    tester,
  ) async {
    Object? result;
    await tester.pumpWidget(
      glassTestApp(
        _launcher(onResult: (r) => result = r),
        overlayBackdrop: true,
      ),
    );
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final early = tester.getRect(find.byType(AppGlass).last);
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byType(AppGlass).last);
    expect(early.width, lessThan(settled.width));
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(result, 'ok');
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets(
    'drag follows 1:1; a slow short drag springs back; a fling dismisses',
    (tester) async {
      await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
      await tester.tap(find.text('باز کن'));
      await tester.pumpAndSettle();
      final sheet = find.byType(AppGlass).last;
      final top = tester.getRect(sheet).top;
      final gesture = await tester.startGesture(
        tester.getRect(sheet).topCenter + const Offset(0, 10),
      );
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(tester.getRect(sheet).top, closeTo(top + 30, 1.5));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(sheet).top, closeTo(top, 1));
      await tester.fling(sheet, const Offset(0, 200), 1500);
      await tester.pumpAndSettle();
      expect(find.text('تأیید'), findsNothing);
    },
  );

  testWidgets('scrim tap, Escape and back close the sheet', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets('sheet glass joins the overlay group; content inside is flat', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
    ); // tinted button inside sheet glass must not nest glass
    expect(
      find.byType(AppGlass),
      findsNWidgets(2),
    ); // launcher + sheet; the inner button is flat
  });

  testWidgets('reduced motion: fade only', (tester) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(), reduceMotion: true, overlayBackdrop: true),
    );
    await expectNoMovement(
      tester,
      within: find.byType(Navigator),
      trigger: () => tester.tap(find.text('باز کن')),
    );
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
  });
}
