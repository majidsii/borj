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
}
