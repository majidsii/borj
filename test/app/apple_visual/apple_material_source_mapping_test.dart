import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple Liquid Glass material source mapping', () {
    test('ios custom glass styles are source-backed', () {
      final materials = AppleSourceTokenMapper.materials(
        family: AppleVisualFamily.ios27,
      );

      expect(materials.isResolved, isTrue);
      expect(materials.customGlassStyles, hasLength(17));

      final sample = materials.customGlassStyles.singleWhere(
        (entry) => entry.sourceId == 'CF5489FF-32A3-4E4E-8634-02FD8BFD0286',
      );

      expect(sample.sourceName, 'Liquid Glass/Widget Glass');
      expect(
        sample.sourceValues['style.blurs[0].brightness'],
        closeTo(1.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].chromaticAberrationMultiplier'],
        closeTo(0.0, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].depth'], closeTo(0.5, 1e-12));
      expect(
        sample.sourceValues['style.blurs[0].distortion'],
        closeTo(0.2, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].extraSamplingRegion'],
        closeTo(0.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].layeringType'],
        closeTo(0.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].motionAngle'],
        closeTo(0.0, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].radius'], closeTo(3.0, 1e-12));
      expect(
        sample.sourceValues['style.blurs[0].saturation'],
        closeTo(1.0, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].type'], closeTo(4.0, 1e-12));
    });

    test('macos custom glass styles are source-backed', () {
      final materials = AppleSourceTokenMapper.materials(
        family: AppleVisualFamily.macos27,
      );

      expect(materials.isResolved, isTrue);
      expect(materials.customGlassStyles, hasLength(19));

      final sample = materials.customGlassStyles.singleWhere(
        (entry) => entry.sourceId == '85D10028-7CBB-4801-88E5-54C4EF430DF9',
      );

      expect(sample.sourceName, 'Liquid Glass/Lock Screen Time');
      expect(
        sample.sourceValues['style.blurs[0].brightness'],
        closeTo(1.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].chromaticAberrationMultiplier'],
        closeTo(0.0, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].depth'], closeTo(0.5, 1e-12));
      expect(
        sample.sourceValues['style.blurs[0].distortion'],
        closeTo(0.2, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].extraSamplingRegion'],
        closeTo(0.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].layeringType'],
        closeTo(0.0, 1e-12),
      );
      expect(
        sample.sourceValues['style.blurs[0].motionAngle'],
        closeTo(0.0, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].radius'], closeTo(3.0, 1e-12));
      expect(
        sample.sourceValues['style.blurs[0].saturation'],
        closeTo(1.4, 1e-12),
      );
      expect(sample.sourceValues['style.blurs[0].type'], closeTo(4.0, 1e-12));
    });
  });
}
