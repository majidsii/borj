import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../foundation/apple_glass_shape.dart';

/// Flat material for anything drawn on glass (spec §2.2: never glass on glass).
final class GlassInner extends StatelessWidget {
  const GlassInner({
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    super.key,
  });

  final Widget child;
  final AppleGlassShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final radius = switch (shape.kind) {
      AppleGlassShapeKind.rounded => BorderRadius.circular(shape.radius),
      _ => BorderRadius.circular(999),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.innerTop, colors.innerBottom],
        ),
        border: Border.all(color: colors.innerEdge, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: colors.innerShadow,
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: child,
    );
  }
}
