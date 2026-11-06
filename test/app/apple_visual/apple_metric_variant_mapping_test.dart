import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple variant-aware source metrics', () {
    test('iOS segmented controls preserve Small and Large geometry', () {
      final ios = AppleSourceTokenMapper.metrics(
        family: AppleVisualFamily.ios27,
      );

      final segmented = ios.variantsFor(AppleMetricComponent.segmentedControl);

      expect(ios.isResolved, isTrue);
      expect(segmented.length, greaterThan(1));
      expect(
        segmented
            .map((variant) => variant.geometry['frame.height'])
            .whereType<double>()
            .toSet(),
        containsAll(<double>{32.0, 48.0}),
      );

      final large = segmented.singleWhere(
        (variant) => variant.provenance.any(
          (source) => source.sourceId == 'FE073914-A7E7-4E4E-9F4D-374AE7330AA9',
        ),
      );

      expect(large.geometry['frame.width'], 370.0);
      expect(large.geometry['frame.height'], 48.0);
      expect(large.sizeLabel, 'Large');

      final small = segmented.singleWhere(
        (variant) => variant.provenance.any(
          (source) => source.sourceId == '6DA75111-744B-47C1-8769-4254E1C3374A',
        ),
      );

      expect(small.geometry['frame.width'], 370.0);
      expect(small.geometry['frame.height'], 32.0);
      expect(small.sizeLabel, 'Small');
    });

    test('macOS search field preserves explicit Apple size label', () {
      final macos = AppleSourceTokenMapper.metrics(
        family: AppleVisualFamily.macos27,
      );

      final search = macos.variantsFor(AppleMetricComponent.searchField);

      final miniature = search.singleWhere(
        (variant) => variant.provenance.any(
          (source) => source.sourceId == '178C3D20-136B-4799-89C1-C1813A46A495',
        ),
      );

      expect(miniature.sizeLabel, 'Mn');
      expect(miniature.geometry['frame.width'], 120.0);
      expect(miniature.geometry['frame.height'], 16.0);
    });

    test('macOS toggle exact geometry duplicates retain state provenance', () {
      final macos = AppleSourceTokenMapper.metrics(
        family: AppleVisualFamily.macos27,
      );

      final toggles = macos.variantsFor(AppleMetricComponent.toggle);

      final compactToggle = toggles.singleWhere(
        (variant) =>
            variant.sizeLabel == 'Mn' &&
            variant.geometry['frame.width'] == 63.0 &&
            variant.geometry['frame.height'] == 16.0,
      );

      expect(
        compactToggle.provenance.map((source) => source.sourceId),
        containsAll(<String>[
          'BC9FF280-BDD8-4AA5-B2CD-ED6CBE8F797F',
          'E64ABC9F-439D-4299-A8D6-4EBCF7815DC7',
          '1EEBE37B-CD9A-4ED5-90EE-5CC65BBF2CF7',
        ]),
      );
    });

    test('generic Keyboard Switch is not classified as Toggle', () {
      final ios = AppleSourceTokenMapper.metrics(
        family: AppleVisualFamily.ios27,
      );

      final toggles = ios.variantsFor(AppleMetricComponent.toggle);

      expect(
        toggles
            .expand((variant) => variant.provenance)
            .any(
              (source) =>
                  source.sourceId == '753D239D-FACC-4173-A42B-4073094687A3',
            ),
        isFalse,
      );
    });

    test('metric geometry excludes material and visual-effect values', () {
      final allVariants = <AppleMetricVariant>[
        ...AppleSourceTokenMapper.metrics(
          family: AppleVisualFamily.ios27,
        ).variants,
        ...AppleSourceTokenMapper.metrics(
          family: AppleVisualFamily.macos27,
        ).variants,
      ];

      final effectPattern = RegExp(
        r'blur|shadow|saturat|bright|distort|depth|opacity|glass|'
        r'fill|color|border|stroke',
        caseSensitive: false,
      );

      for (final variant in allVariants) {
        for (final key in variant.geometry.keys) {
          expect(
            effectPattern.hasMatch(key),
            isFalse,
            reason: 'effect value leaked into metric geometry: $key',
          );
        }
      }
    });

    test('all initial component families remain multi-variant aware', () {
      for (final family in AppleVisualFamily.values) {
        final metrics = AppleSourceTokenMapper.metrics(family: family);

        for (final component in AppleMetricComponent.values) {
          expect(
            metrics.variantsFor(component),
            isNotEmpty,
            reason: 'missing $family source variants for $component',
          );
        }
      }
    });
  });
}
