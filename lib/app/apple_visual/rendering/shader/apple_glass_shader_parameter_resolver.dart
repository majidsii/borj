import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_shader_parameters.dart';

final class AppleGlassShaderParameterResolver {
  const AppleGlassShaderParameterResolver();

  AppleGlassShaderParameters resolve(AppleLiquidGlassRecipe recipe) {
    final values = recipe.sourceValues;

    return AppleGlassShaderParameters(
      saturation: _first(values, [
        'style.saturation',
        'style.blurs[0].saturation',
      ]),
      brightnessResponse: _first(values, [
        'style.brightness',
        'style.brightnessResponse',
        'style.blurs[0].brightnessResponse',
        'style.blurs[0].brightness',
      ]),
      distortionStrength: _first(values, [
        'style.distortion',
        'style.distortionStrength',
        'style.blurs[0].distortionStrength',
        'style.blurs[0].distortion',
      ]),
      depthResponse: _first(values, [
        'style.depth',
        'style.depthResponse',
        'style.blurs[0].depthResponse',
        'style.blurs[0].depth',
      ]),
      lightingResponse: _first(values, [
        'style.lighting',
        'style.lightingResponse',
        'style.blurs[0].lightingResponse',
        'style.blurs[0].lighting',
      ]),
      chromaticAberration: _first(values, [
        'style.blurs[0].chromaticAberrationMultiplier',
        'style.chromaticAberration',
        'style.blurs[0].chromaticAberration',
      ]),
      customGlassRadius: _first(values, [
        'style.radius',
        'style.blurs[0].radius',
      ]),
    );
  }

  double _first(Map<String, Object?> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];

      if (value != null) {
        return _number(value);
      }
    }

    return 0;
  }

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }
}
