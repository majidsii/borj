import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';
import '../../support/reduced_motion_expectations.dart';

Widget _launcher(VoidCallback onUndo, {String message = 'کار حذف شد'}) =>
    Builder(
      builder: (context) => GlassButton(
        label: 'حذف',
        onPressed: () =>
            showUndoToast(context, message: message, onUndo: onUndo),
      ),
    );

void main() {
  for (final v in glassTestVariants) {
    testWidgets('shows (${v.name})', (tester) async {
      await tester.pumpWidget(
        glassTestApp(
          _launcher(() {}),
          brightness: v.brightness,
          textScale: v.textScale,
          overlayBackdrop: true,
        ),
      );
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.text('کار حذف شد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rises from 16 px below, auto-hides after 5 s', (tester) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(() {}), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pump();
    final start = tester.getRect(find.text('کار حذف شد')).top;
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.text('کار حذف شد')).top;
    expect(start - settled, closeTo(16, 1.5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('کار حذف شد'), findsNothing);
  });

  testWidgets('undo calls back and closes; a new toast replaces the old', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(
      glassTestApp(_launcher(() => undone++), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(find.text('کار حذف شد'), findsOneWidget);
    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('کار حذف شد'), findsNothing);
  });

  testWidgets('glass is one chrome capsule; the undo button is flat', (
    tester,
  ) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(() {}), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppGlass), findsNWidgets(2)); // launcher + toast
  });

  testWidgets('reduced motion: fade only', (tester) async {
    await tester.pumpWidget(
      glassTestApp(_launcher(() {}), reduceMotion: true, overlayBackdrop: true),
    );
    await expectNoMovement(
      tester,
      within: find.byType(Overlay).first,
      trigger: () => tester.tap(find.text('حذف')),
    );
    expect(find.text('کار حذف شد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('live region semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      glassTestApp(_launcher(() {}), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('کار حذف شد')),
      matchesSemantics(isLiveRegion: true, label: 'کار حذف شد'),
    );
    handle.dispose();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('undo fires once on a double tap', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      glassTestApp(_launcher(() => undone++), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('برگرداندن'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('برگرداندن'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(undone, 1);
  });

  testWidgets('undo during the auto-hide exit does nothing', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      glassTestApp(_launcher(() => undone++), overlayBackdrop: true),
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle(); // shows; the 5 s timer is not elapsed
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 30)); // mid exit
    expect(find.text('برگرداندن'), findsOneWidget);
    await tester.tap(find.text('برگرداندن'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(undone, 0);
    expect(find.text('کار حذف شد'), findsNothing);
  });

  testWidgets('a new toast in the old one\'s last exit frame is safe', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      glassTestApp(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
        reduceMotion: true,
        overlayBackdrop: true,
      ),
    );
    showUndoToast(context, message: 'الف', onUndo: () {});
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 5)); // A starts leaving
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190)); // A: last frame next
    showUndoToast(context, message: 'ب', onUndo: () {});
    await tester.pump(const Duration(milliseconds: 20)); // A reaches dismissed
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('ب'), findsOneWidget);
    expect(find.text('الف'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('ب'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
