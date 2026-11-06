import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:borj/app/apple_visual/foundation/apple_renderer_deviation.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unresolved Liquid Glass state behavior', () {
    test('non-source-backed pressed state fails instead of reusing idle', () {
      expect(
        () => AppleLiquidGlassRecipeResolver.resolve(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
          role: AppleGlassRole.smallControl,
          state: AppleControlState.pressed,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('No source-backed Apple Liquid Glass recipe'),
          ),
        ),
      );
    });
  });

  group('renderer deviation baseline', () {
    test('production accepts zero renderer deviations', () {
      expect(AppleRendererDeviationBaseline.acceptedDeviations, isEmpty);
    });

    test('renderer deviation carries the approved evidence fields', () {
      const deviation = AppleRendererDeviation(
        family: AppleVisualFamily.macos27,
        component: 'test-only-component',
        platform: 'test-only-platform',
        reason: 'test-only-reason',
        measuredDelta: 0.5,
      );

      expect(deviation.family, AppleVisualFamily.macos27);
      expect(deviation.component, 'test-only-component');
      expect(deviation.platform, 'test-only-platform');
      expect(deviation.reason, 'test-only-reason');
      expect(deviation.measuredDelta, 0.5);
    });
  });
}
