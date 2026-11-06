import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ios27 light smallControl preserves applied usage geometry separately',
    () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
      );

      expect(recipe.sourceValues['usage.frame.width'], 80);
      expect(recipe.sourceValues['usage.frame.height'], 48);

      final radius = recipe.sourceValues['usage.corners.radii[0]'];
      expect(radius, isA<num>());
      expect((radius! as num).toDouble(), greaterThan(1e30));

      expect(recipe.sourceValues['usage.corners.smoothing'], 0.6);
      expect(recipe.sourceValues['usage.corners.style'], 1);

      expect(
        recipe.roleMappingEvidence,
        contains('usageGeometrySelector=name:BG - Small'),
      );
      expect(
        recipe.roleMappingEvidence,
        contains('usageGeometryAgreementCount=6'),
      );

      expect(recipe.sourceValues.containsKey('render.cornerRadius'), isFalse);
      expect(
        recipe.sourceValues.containsKey('style.corners.radii[0]'),
        isFalse,
      );
    },
  );
}
