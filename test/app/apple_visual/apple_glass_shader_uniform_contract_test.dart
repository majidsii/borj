import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_uniform_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves deterministic shader uniforms from source values', () {
    final recipe = AppleLiquidGlassRecipe(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
      sourceIds: const ['source'],
      sourceNames: const ['source'],
      sourceValues: const {
        'style.saturation': 1.2,
        'style.brightness': 0.1,
        'style.distortion': 0.3,
        'style.depth': 0.4,
        'style.lighting': 0.5,
      },
      roleMappingEvidence: const ['test'],
    );

    final uniforms = const AppleGlassShaderUniformResolver().resolve(recipe);

    expect(uniforms.saturation, 1.2);
    expect(uniforms.brightness, 0.1);
    expect(uniforms.distortion, 0.3);
    expect(uniforms.depth, 0.4);
    expect(uniforms.lighting, 0.5);
  });
  test('resolves source chromatic aberration multiplier', () {
    final recipe = AppleLiquidGlassRecipe(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
      sourceIds: const ['source'],
      sourceNames: const ['source'],
      sourceValues: const {'style.blurs[0].chromaticAberrationMultiplier': 0.4},
      roleMappingEvidence: const ['test'],
    );

    final uniforms = const AppleGlassShaderUniformResolver().resolve(recipe);

    expect(uniforms.chromaticAberration, 0.4);
  });

  test('uses neutral shader defaults when source values are absent', () {
    final recipe = AppleLiquidGlassRecipe(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
      sourceIds: const ['source'],
      sourceNames: const ['source'],
      sourceValues: const {},
      roleMappingEvidence: const ['test'],
    );

    final uniforms = const AppleGlassShaderUniformResolver().resolve(recipe);

    expect(uniforms.saturation, 1);
    expect(uniforms.brightness, 1);
    expect(uniforms.distortion, 0);
    expect(uniforms.depth, 0);
    expect(uniforms.chromaticAberration, 0);
    expect(uniforms.customGlassRadius, 0);
    expect(uniforms.lighting, 0);
  });
}
