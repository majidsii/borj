import 'dart:math' as math;

enum AppleGlassShapeKind { capsule, rounded, circle }

final class AppleGlassShape {
  const AppleGlassShape.capsule()
    : kind = AppleGlassShapeKind.capsule,
      radius = 0;
  const AppleGlassShape.rounded(this.radius)
    : kind = AppleGlassShapeKind.rounded;
  const AppleGlassShape.circle()
    : kind = AppleGlassShapeKind.circle,
      radius = 0;

  final AppleGlassShapeKind kind;
  final double radius;

  /// Inner shape for content inset by [padding] (concentric corners).
  AppleGlassShape concentricInner(double padding) => switch (kind) {
    AppleGlassShapeKind.rounded => AppleGlassShape.rounded(
      math.max(0.0, radius - padding),
    ),
    _ => this,
  };
}
