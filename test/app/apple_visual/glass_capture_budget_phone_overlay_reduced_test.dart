import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../support/backdrop_layer_count.dart';

void main() {
  testWidgets('phone with a sheet fading in (reduced motion) stays within 3', (
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: GlassOverlayBackdrop(child: child!),
        ),
        home: const GlassProbeScene.phoneWithSheetTrigger(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('probe-open-sheet')));
    await tester.pump();
    var worst = 0;
    var sawFractional = false;
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 16)); // during the fade
      expect(find.text('تأیید'), findsOneWidget);
      final v = tester
          .widget<LiquidGlass>(find.byType(LiquidGlass).last)
          .appearance!
          .visibility;
      if (v > 0 && v < 1) sawFractional = true;
      worst = worst < countCompositedBackdrops(tester)
          ? countCompositedBackdrops(tester)
          : worst;
    }
    expect(find.text('تأیید'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('تأیید'), findsOneWidget);
    expect(sawFractional, isTrue, reason: 'the fade must really be sampled');
    final settled = countCompositedBackdrops(tester);
    // ignore: avoid_print
    print(
      'LG_COMPOSITED scene=phone+sheet reduced fade=$worst settled=$settled',
    );
    expect(worst, lessThanOrEqualTo(3));
    expect(settled, lessThanOrEqualTo(3));
  });
}
