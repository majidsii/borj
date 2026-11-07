import 'package:borj/app/apple_visual/review/glass_probe_scene.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
