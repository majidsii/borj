import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _launcher({void Function(Object?)? onResult, bool withOrigin = true}) =>
    Builder(
      builder: (context) => GlassButton(
        label: 'باز کن',
        onPressed: () async {
          final box = context.findRenderObject()! as RenderBox;
          final origin = box.localToGlobal(Offset.zero) & box.size;
          final result = await showGlassSheet<String>(
            context,
            origin: withOrigin ? origin : null,
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

  testWidgets('reduced motion: fade only, rect never moves', (tester) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(), reduceMotion: true, overlayBackdrop: true),
    );
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    final rects = <Rect>[];
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      rects.add(tester.getRect(find.byType(AppGlass).last));
    }
    expect(rects.every((r) => r == rects.first), isTrue, reason: '$rects');
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(AppGlass).last), rects.first);
    expect(find.text('تأیید'), findsOneWidget);
  });

  testWidgets('reduced motion: no transform moves (expectNoMovement)', (
    tester,
  ) async {
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

  testWidgets('system back closes the sheet', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsNothing);
  });

  testWidgets('first frame sits at the trigger centre', (tester) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    final origin = tester.getRect(find.text('باز کن'));
    final trigger = tester.getRect(find.byType(AppGlass).first);
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    final first = tester.getRect(find.byType(AppGlass).last);
    expect((first.center - trigger.center).distance, lessThan(30));
    expect(origin.center.dx, closeTo(trigger.center.dx, 1));
  });

  testWidgets('without an origin it grows from the bottom centre', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(withOrigin: false), overlayBackdrop: true),
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    final first = tester.getRect(find.byType(AppGlass).last);
    expect(first.center.dx, closeTo(screen.width / 2, 2));
    expect(first.center.dy, closeTo(screen.height - 20, 2));
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byType(AppGlass).last);
    expect(settled.bottom, closeTo(screen.height - 8, 1));
  });

  testWidgets('phone width: inset 8, full width minus insets', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(AppGlass).last);
    expect(rect.left, closeTo(8, 0.5));
    expect(rect.width, closeTo(374, 0.5));
  });

  testWidgets('desktop width: 560, centred', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(AppGlass).last);
    expect(rect.width, closeTo(560, 0.5));
    expect(rect.center.dx, closeTo(720, 0.5));
  });

  testWidgets('grabbing mid-open does not jump; slow release springs back', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(_launcher(), overlayBackdrop: true));
    await tester.tap(find.text('باز کن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final sheet = find.byType(AppGlass).last;
    final before = tester.getRect(sheet);
    final gesture = await tester.startGesture(
      before.topCenter + const Offset(0, 10),
    );
    await tester.pump();
    expect(tester.getRect(sheet).top, closeTo(before.top, 2));
    await gesture.moveBy(const Offset(0, 15));
    await tester.pump();
    final dragged = tester.getRect(sheet).top - before.top;
    expect(dragged, closeTo(15, 3));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(sheet).bottom, closeTo(screen.height - 8, 1));
  });
}
