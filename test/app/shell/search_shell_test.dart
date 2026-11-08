import 'package:borj/app/design/design.dart';
import 'package:borj/app/shell/search_shell.dart';
import 'package:borj/app/shell/today_interim_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/backdrop_layer_count.dart';
import '../../support/borj_test_app.dart';
import '../../support/glass_fade_expectations.dart';

Future<void> _ctrlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  testWidgets(
    'compact: the search circle pushes the search page with a focused field',
    (tester) async {
      useWindowSize(tester, const Size(390, 844));
      await pumpBorjTestApp(tester);
      await tester.tap(find.byKey(const ValueKey('tab-search')));
      await tester.pumpAndSettle();
      expect(find.byType(SearchShellScreen), findsOneWidget);
      expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      GoRouter.of(tester.element(find.byType(SearchShellScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(TodayInterimPage), findsOneWidget);
    },
  );

  testWidgets(
    'expanded: Ctrl+K opens the overlay on the next frame; Escape closes',
    (tester) async {
      useWindowSize(tester, const Size(1440, 900));
      await pumpBorjTestApp(tester);
      await _ctrlK(tester);
      await tester.pump();
      expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('جست‌وجو به‌زودی'), findsNothing);
    },
  );

  testWidgets('expanded: the toolbar search capsule opens the same overlay', (
    tester,
  ) async {
    useWindowSize(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    expect(
      tester.getSize(find.byKey(const ValueKey('toolbar-search'))),
      const Size(230, 44),
    );
    await tester.tap(find.byKey(const ValueKey('toolbar-search')));
    await tester.pump();
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
  });

  testWidgets('medium: Ctrl+K opens the overlay', (tester) async {
    useWindowSize(tester, const Size(800, 900));
    await pumpBorjTestApp(tester);
    await _ctrlK(tester);
    await tester.pump();
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
  });

  testWidgets('expanded: overlay open stays within 4 captures', (tester) async {
    useWindowSize(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    await _ctrlK(tester);
    await tester.pump();
    expect(countCompositedBackdrops(tester), lessThanOrEqualTo(4));
  });

  testWidgets('expanded: the overlay never bare-fades its glass', (
    tester,
  ) async {
    useWindowSize(tester, const Size(1440, 900));
    await pumpBorjTestApp(tester);
    // The app's first page route already fades the shell (a settled route,
    // not the overlay): that is the baseline the overlay must not add to.
    final baseline = bareFadesAboveGlass(tester, find.byType(Navigator)).length;
    await _ctrlK(tester);
    await tester.pump();
    expect(find.byType(GlassOverlayContent), findsOneWidget);
    expect(
      bareFadesAboveGlass(tester, find.byType(Navigator)).length,
      baseline,
    );
    // No transition frames: the first pump after opening is the final one.
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('جست‌وجو به‌زودی'), findsOneWidget);
  });
}
