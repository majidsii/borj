// SPIKE EXCEPTION: see ../all_glass_kit.dart (direct liquid_glass_renderer use).
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A glass shape with an optional tint, for use inside a GlassSection.
class TintedGlass extends StatelessWidget {
  const TintedGlass({
    required this.child,
    this.radius = 28,
    this.tint,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final double radius;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.grouped(
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      appearance: tint == null
          ? null
          : LiquidGlassAppearance.ios27RegularDark(tint: tint!),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Splits [path] into dashes.
Path dashedPath(Path path, {double dash = 7, double gap = 6}) {
  final out = Path();
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      out.addPath(metric.extractPath(d, d + dash), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}
