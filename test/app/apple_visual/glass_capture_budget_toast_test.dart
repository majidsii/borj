import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backdrop_layer_count.dart';

void main() {
  testWidgets('phone with a sheet open and a toast entering stays within 3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          extensions: [AppTheme.dark],
        ),
        builder: (context, child) => GlassOverlayBackdrop(child: child!),
        home: const GlassProbeScene.phoneWithSheetTrigger(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('probe-open-sheet')));
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
    // The sheet's barrier covers the trigger; fire the toast through the
    // trigger's own callback.
    final button = tester.widget<GlassButton>(
      find.byKey(const ValueKey('probe-show-toast')),
    );
    button.onPressed!();
    var worst = 0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('کار حذف شد'), findsOneWidget);
      expect(find.text('تأیید'), findsOneWidget);
      final n = countCompositedBackdrops(tester);
      if (n > worst) worst = n;
    }
    await tester.pump(const Duration(seconds: 1)); // settled, before auto-hide
    expect(find.text('کار حذف شد'), findsOneWidget);
    final settled = countCompositedBackdrops(tester);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phone+sheet+toast entrance=$worst settled=$settled',
    );
    // ignore: avoid_print
    print('LG_CAPTURES scene=phone+sheet+toast path=composited max=$worst');
    expect(worst, lessThanOrEqualTo(3));
    expect(settled, lessThanOrEqualTo(3));
  });
}
