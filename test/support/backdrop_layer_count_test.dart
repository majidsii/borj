// ignore_for_file: invalid_use_of_internal_member
import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:liquid_glass_renderer/src/internal/backdrop_seed.dart';

import 'backdrop_layer_count.dart';

void main() {
  testWidgets('counts the Part A phone scene as 2', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          extensions: [AppTheme.dark],
        ),
        home: const GlassProbeScene.phone(),
      ),
    );
    await tester.pump();
    expect(countCompositedBackdrops(tester), 2);
  });

  group('seeded passes', () {
    tearDown(() => SeededBackdropPassLayer.debugModeOverride = null);

    Future<void> pumpScene(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppTheme.dark],
          ),
          home: const GlassProbeScene.phone(),
        ),
      );
      await tester.pump();
    }

    testWidgets('a shared seed counts once, the naive count overcounts', (
      tester,
    ) async {
      SeededBackdropPassLayer.debugModeOverride = BackdropSeed.identity;
      await pumpScene(tester);
      final count = countCompositedBackdropsDetailed(tester);
      expect(count.activeSeededPasses, greaterThan(0));
      expect(count.captures, 2);
      expect(count.naive, greaterThan(count.captures));
    });

    testWidgets('without the override naive equals seed-aware', (tester) async {
      await pumpScene(tester);
      final count = countCompositedBackdropsDetailed(tester);
      expect(count.activeSeededPasses, 0);
      expect(count.naive, count.captures);
    });
  });
}
