import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shadow_runtime_pipeline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves complete apple glass shadow runtime pipeline', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    const pipeline = AppleGlassShadowRuntimePipeline();

    final result = pipeline.resolve(recipe: recipe);

    expect(result, hasLength(13));

    expect(
      result.map((item) => item.shadow.index),
      orderedEquals(List<int>.generate(13, (index) => index)),
    );
  });
}
