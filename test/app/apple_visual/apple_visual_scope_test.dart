import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('falls back to the app theme brightness, not the platform', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late Brightness seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Builder(
          builder: (context) {
            seen = AppleVisualScope.of(context).brightness;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, Brightness.light);
  });

  testWidgets('maps desktop platforms to macos27', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    late AppleVisualFamily family;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            family = AppleVisualScope.of(context).family;
            return const SizedBox();
          },
        ),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(family, AppleVisualFamily.macos27);
  });
}
