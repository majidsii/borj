import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shadow_runtime_painter.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shadow_stack_compositor.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_material_layer_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime painter receives complete resolved shadow backend stack', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    const materialResolver = AppleGlassMaterialLayerResolver();
    const compositor = AppleGlassShadowStackCompositor();

    final layers = compositor.resolveLayers(materialResolver.resolve(recipe));

    expect(layers, hasLength(13));

    expect(
      layers
          .where(
            (layer) => layer.backendKind == AppleGlassShadowBackendKind.native,
          )
          .length,
      7,
    );

    expect(
      layers
          .where(
            (layer) =>
                layer.backendKind == AppleGlassShadowBackendKind.plusDarker,
          )
          .length,
      6,
    );

    const painter = AppleGlassShadowRuntimePainter();

    expect(() => painter.paint(layers: layers), returnsNormally);
  });
}
