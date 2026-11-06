import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_materials.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_metrics.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_motion.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_theme.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_tokens.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_typography.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple visual source token contract', () {
    test('theme data is explicitly bound to one Apple visual family', () {
      const theme = AppleVisualThemeData(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        colors: AppleColorTokens.empty,
        typography: AppleTypographyTokens.empty,
        metrics: AppleMetricTokens.empty,
        materials: AppleMaterialTokens.empty,
        motion: AppleMotionTokens.empty,
      );

      expect(theme.family, AppleVisualFamily.ios27);
      expect(theme.brightness, Brightness.light);
    });

    test(
      'source-backed token groups cannot be mistaken for resolved production data',
      () {
        expect(AppleColorTokens.empty.isResolved, isFalse);
        expect(AppleTypographyTokens.empty.isResolved, isFalse);
        expect(AppleMetricTokens.empty.isResolved, isFalse);
        expect(AppleMaterialTokens.empty.isResolved, isFalse);
        expect(AppleMotionTokens.empty.isResolved, isFalse);
      },
    );

    test('resolved theme requires every token group to be resolved', () {
      const theme = AppleVisualThemeData(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        colors: AppleColorTokens.empty,
        typography: AppleTypographyTokens.empty,
        metrics: AppleMetricTokens.empty,
        materials: AppleMaterialTokens.empty,
        motion: AppleMotionTokens.empty,
      );

      expect(theme.isResolved, isFalse);
    });
  });

  // B6C_AGGREGATE_THEME_RESOLUTION_CONTRACT_V2
  group('AppleVisualThemeData aggregate resolution', () {
    for (final family in AppleVisualFamily.values) {
      for (final brightness in Brightness.values) {
        test(
          '$family $brightness resolves when every Gate B token group is resolved',
          () {
            final theme = AppleVisualThemeData(
              family: family,
              brightness: brightness,
              colors: AppleSourceTokenMapper.colors(
                family: family,
                brightness: brightness,
              ),
              typography: AppleSourceTokenMapper.typography(family: family),
              metrics: AppleSourceTokenMapper.metrics(family: family),
              materials: AppleSourceTokenMapper.materials(family: family),
              motion: AppleSourceTokenMapper.motion(family: family),
            );

            expect(theme.family, family);
            expect(theme.brightness, brightness);
            expect(theme.isResolved, isTrue);
          },
        );

        test(
          '$family $brightness remains unresolved when motion alone is unresolved',
          () {
            final theme = AppleVisualThemeData(
              family: family,
              brightness: brightness,
              colors: AppleSourceTokenMapper.colors(
                family: family,
                brightness: brightness,
              ),
              typography: AppleSourceTokenMapper.typography(family: family),
              metrics: AppleSourceTokenMapper.metrics(family: family),
              materials: AppleSourceTokenMapper.materials(family: family),
              motion: AppleMotionTokens.empty,
            );

            expect(theme.isResolved, isFalse);
          },
        );
      }
    }
  });
}
