// GENERATED FILE — DO NOT EDIT.
// Source: docs/superpowers/references/apple_swiftui_motion_runtime_reference.json
// Generator: tool/generate_apple_source_motion.py

class AppleGeneratedMotionProvenance {
  const AppleGeneratedMotionProvenance({
    required this.apiReference,
    required this.officialSwiftUIRuntimeReference,
    required this.exactInternalLiquidGlassMotion,
  });

  final String apiReference;
  final bool officialSwiftUIRuntimeReference;
  final bool exactInternalLiquidGlassMotion;
}

class AppleGeneratedSpringMotion {
  const AppleGeneratedSpringMotion({
    required this.id,
    required this.responseSeconds,
    required this.dampingFraction,
    required this.blendDurationSeconds,
    required this.provenance,
  });

  final String id;
  final double responseSeconds;
  final double dampingFraction;
  final double blendDurationSeconds;
  final AppleGeneratedMotionProvenance provenance;
}

abstract final class AppleSourceMotionReference {
  static const AppleGeneratedSpringMotion defaultSpring =
      AppleGeneratedSpringMotion(
        id: 'defaultSpring',
        responseSeconds: 0.55,
        dampingFraction: 1.0,
        blendDurationSeconds: 0.0,
        provenance: AppleGeneratedMotionProvenance(
          apiReference: 'Animation.default',
          officialSwiftUIRuntimeReference: true,
          exactInternalLiquidGlassMotion: false,
        ),
      );

  static const AppleGeneratedSpringMotion
  interactiveSpring = AppleGeneratedSpringMotion(
    id: 'interactiveSpring',
    responseSeconds: 0.15,
    dampingFraction: 0.86,
    blendDurationSeconds: 0.25,
    provenance: AppleGeneratedMotionProvenance(
      apiReference:
          'Animation.interactiveSpring(response:dampingFraction:blendDuration:)',
      officialSwiftUIRuntimeReference: true,
      exactInternalLiquidGlassMotion: false,
    ),
  );

  static const List<String> accessibilityPolicies = [
    'standard',
    'reduceMotion',
  ];
}
