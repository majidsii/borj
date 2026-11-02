import 'dart:ui';

import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_uniform_mapper.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_uniforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'glass shader exposes and accepts all custom uniform bindings',
    () async {
      final program = await FragmentProgram.fromAsset(
        'shaders/apple_liquid_glass.frag',
      );
      final shader = program.fragmentShader();

      const uniforms = AppleGlassShaderUniforms(
        saturation: 1.2,
        brightness: 0.1,
        distortion: 0.3,
        depth: 0.4,
        chromaticAberration: 0.2,
        customGlassRadius: 24,
        lighting: 0.5,
      );

      const AppleGlassShaderUniformMapper().apply(shader, uniforms);

      expect(() => shader.getUniformFloat('uSaturation'), returnsNormally);
      expect(() => shader.getUniformFloat('uBrightness'), returnsNormally);
      expect(() => shader.getUniformFloat('uDistortion'), returnsNormally);
      expect(() => shader.getUniformFloat('uDepth'), returnsNormally);
      expect(
        () => shader.getUniformFloat('uChromaticAberration'),
        returnsNormally,
      );
      expect(() => shader.getUniformFloat('uGlassRadius'), returnsNormally);
      expect(() => shader.getUniformFloat('uLighting'), returnsNormally);

      shader.dispose();
    },
  );
}
