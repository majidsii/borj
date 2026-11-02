import 'dart:ui';

import 'apple_glass_shader_uniforms.dart';

final class AppleGlassShaderUniformMapper {
  const AppleGlassShaderUniformMapper();

  void apply(FragmentShader shader, AppleGlassShaderUniforms uniforms) {
    shader.getUniformFloat('uSaturation').set(uniforms.saturation);
    shader.getUniformFloat('uBrightness').set(uniforms.brightness);
    shader.getUniformFloat('uDistortion').set(uniforms.distortion);
    shader.getUniformFloat('uDepth').set(uniforms.depth);
    shader
        .getUniformFloat('uChromaticAberration')
        .set(uniforms.chromaticAberration);
    shader.getUniformFloat('uGlassRadius').set(uniforms.customGlassRadius);
    shader.getUniformFloat('uLighting').set(uniforms.lighting);
  }
}
