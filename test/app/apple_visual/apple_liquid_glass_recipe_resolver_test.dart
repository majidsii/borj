import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleLiquidGlassRecipeResolver', () {
    test('resolves every source-backed idle recipe exactly', () {
      for (final family in AppleVisualFamily.values) {
        for (final brightness in Brightness.values) {
          for (final role in AppleGlassRole.values) {
            final recipe = AppleLiquidGlassRecipeResolver.resolve(
              family: family,
              brightness: brightness,
              role: role,
              state: AppleControlState.idle,
            );

            expect(recipe.family, family);
            expect(recipe.brightness, brightness);
            expect(recipe.role, role);
            expect(recipe.state, AppleControlState.idle);
            expect(recipe.sourceIds, isNotEmpty);
            expect(recipe.sourceNames, isNotEmpty);
            expect(recipe.sourceValues, isNotEmpty);
            expect(recipe.roleMappingEvidence, isNotEmpty);
          }
        }
      }
    });

    test('maps overGlassControl from source-backed usage provenance', () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
        role: AppleGlassRole.overGlassControl,
        state: AppleControlState.idle,
      );

      expect(
        recipe.roleMappingEvidence,
        contains('usageSelector=name:BG - Small'),
      );
      expect(
        recipe.roleMappingEvidence.any(
          (entry) => entry == 'usageRoot=Liquid Glass - Over Light Backgrounds',
        ),
        isTrue,
      );
    });

    test('preserves source values without guessed fallback keys', () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.dark,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
      );

      expect(recipe.sourceValues.keys, isNot(contains('fallback.blurSigma')));
      expect(recipe.sourceValues.keys, isNot(contains('fallback.opacity')));
      expect(recipe.sourceValues.keys, isNot(contains('fallback.radius')));
    });

    test('recipe collections are immutable', () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
        role: AppleGlassRole.tintedSmallControl,
        state: AppleControlState.idle,
      );

      expect(() => recipe.sourceIds.add('fake'), throwsUnsupportedError);
      expect(() => recipe.sourceNames.add('fake'), throwsUnsupportedError);
      expect(
        () => recipe.sourceValues['fallback.radius'] = 12,
        throwsUnsupportedError,
      );
      expect(
        () => recipe.roleMappingEvidence.add('fake'),
        throwsUnsupportedError,
      );
    });
  });
}
