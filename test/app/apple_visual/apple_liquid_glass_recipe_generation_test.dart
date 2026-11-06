import 'package:borj/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('required Liquid Glass roles are source-backed for each family', () {
    for (final family in ['ios27', 'macos27']) {
      final records = AppleSourceLiquidGlassRecipeReference.records
          .where((record) => record.family == family)
          .toList();

      expect(
        records.map((record) => record.role).toSet(),
        containsAll(<String>{
          'smallControl',
          'tintedSmallControl',
          'mediumSurface',
          'largeSurface',
          'overGlassControl',
        }),
      );

      for (final record in records) {
        expect(record.sourceIds, isNotEmpty);
        expect(record.sourceNames, isNotEmpty);
        expect(record.sourceValues, isNotEmpty);
        expect(record.roleMappingEvidence, isNotEmpty);
      }
    }
  });

  test('generated recipes contain no guessed defaults', () {
    for (final record in AppleSourceLiquidGlassRecipeReference.records) {
      expect(record.sourceValues.keys, isNot(contains('fallback.blurSigma')));
      expect(record.sourceValues.keys, isNot(contains('fallback.opacity')));
      expect(record.sourceValues.keys, isNot(contains('fallback.radius')));
    }
  });
}
