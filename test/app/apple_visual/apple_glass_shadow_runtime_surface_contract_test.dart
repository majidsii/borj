import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shadow_runtime_pipeline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surface shadow runtime pipeline resolves source shadow stack', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    const pipeline = AppleGlassShadowRuntimePipeline();

    final layers = pipeline.resolve(recipe: recipe);

    expect(layers, hasLength(13));

    expect(layers.first.shadow.index, 0);

    expect(layers.last.shadow.index, 12);
  });
}
