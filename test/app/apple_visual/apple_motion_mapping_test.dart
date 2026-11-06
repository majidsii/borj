import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple SwiftUI motion runtime reference', () {
    test('iOS default spring uses approved exact SwiftUI values', () {
      final ios = AppleSourceTokenMapper.motion(
        family: AppleVisualFamily.ios27,
      );

      expect(ios.isResolved, isTrue);
      expect(ios.defaultSpring.preset, AppleMotionPreset.defaultSpring);
      expect(ios.defaultSpring.responseSeconds, 0.55);
      expect(ios.defaultSpring.dampingFraction, 1.0);
      expect(ios.defaultSpring.blendDurationSeconds, 0.0);
    });

    test('iOS interactive spring uses approved exact SwiftUI values', () {
      final ios = AppleSourceTokenMapper.motion(
        family: AppleVisualFamily.ios27,
      );

      expect(ios.interactiveSpring.preset, AppleMotionPreset.interactiveSpring);
      expect(ios.interactiveSpring.responseSeconds, 0.15);
      expect(ios.interactiveSpring.dampingFraction, 0.86);
      expect(ios.interactiveSpring.blendDurationSeconds, 0.25);
    });

    test(
      'motion provenance keeps the approved claim boundary machine-visible',
      () {
        final ios = AppleSourceTokenMapper.motion(
          family: AppleVisualFamily.ios27,
        );

        for (final spring in <AppleSpringMotion>[
          ios.defaultSpring,
          ios.interactiveSpring,
        ]) {
          expect(spring.provenance.officialSwiftUIRuntimeReference, isTrue);
          expect(spring.provenance.exactInternalLiquidGlassMotion, isFalse);
          expect(spring.provenance.apiReference, isNotEmpty);
        }
      },
    );

    test('macOS and iOS use the same approved motion reference values', () {
      final ios = AppleSourceTokenMapper.motion(
        family: AppleVisualFamily.ios27,
      );
      final macos = AppleSourceTokenMapper.motion(
        family: AppleVisualFamily.macos27,
      );

      expect(
        macos.defaultSpring.responseSeconds,
        ios.defaultSpring.responseSeconds,
      );
      expect(
        macos.defaultSpring.dampingFraction,
        ios.defaultSpring.dampingFraction,
      );
      expect(
        macos.defaultSpring.blendDurationSeconds,
        ios.defaultSpring.blendDurationSeconds,
      );

      expect(
        macos.interactiveSpring.responseSeconds,
        ios.interactiveSpring.responseSeconds,
      );
      expect(
        macos.interactiveSpring.dampingFraction,
        ios.interactiveSpring.dampingFraction,
      );
      expect(
        macos.interactiveSpring.blendDurationSeconds,
        ios.interactiveSpring.blendDurationSeconds,
      );
    });

    test('Reduce Motion policy is represented explicitly', () {
      final ios = AppleSourceTokenMapper.motion(
        family: AppleVisualFamily.ios27,
      );

      expect(
        ios.accessibilityPolicies,
        containsAll(<AppleMotionAccessibilityPolicy>[
          AppleMotionAccessibilityPolicy.standard,
          AppleMotionAccessibilityPolicy.reduceMotion,
        ]),
      );
    });

    test(
      'unresolved motion tokens remain explicit and do not guess defaults',
      () {
        expect(AppleMotionTokens.empty.isResolved, isFalse);

        expect(() => AppleMotionTokens.empty.defaultSpring, throwsStateError);
        expect(
          () => AppleMotionTokens.empty.interactiveSpring,
          throwsStateError,
        );
        expect(
          () => AppleMotionTokens.empty.accessibilityPolicies,
          throwsStateError,
        );
      },
    );
  });
}
