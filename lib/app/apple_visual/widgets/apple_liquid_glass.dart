import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../foundation/apple_glass_shape.dart';
import '../foundation/apple_liquid_glass_recipe.dart';
import '../foundation/apple_visual_scope.dart';
import '../foundation/apple_visual_state.dart';
import '../foundation/apple_visual_theme.dart';

final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.role,
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    this.state = AppleControlState.idle,
    this.theme,
    super.key,
  });

  final AppleGlassRole role;
  final Widget child;
  final AppleGlassShape shape;
  final AppleControlState state;
  final AppleVisualThemeData? theme;

  @visibleForTesting
  static LiquidGlassSettings settingsFor(
    AppleGlassRole role,
    Brightness brightness,
  ) {
    return switch (role) {
      AppleGlassRole.overGlassControl => LiquidGlassSettings.ios27Clear(),
      _ => LiquidGlassSettings.ios27Regular(brightness: brightness),
    };
  }

  static LiquidShape _shapeFor(AppleGlassShape shape) {
    return switch (shape.kind) {
      AppleGlassShapeKind.capsule => const LiquidRoundedSuperellipse(
        borderRadius: 999,
      ),
      AppleGlassShapeKind.rounded => LiquidRoundedSuperellipse(
        borderRadius: shape.radius,
      ),
      AppleGlassShapeKind.circle => const LiquidOval(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? AppleVisualScope.of(context);
    return LiquidGlass.withOwnLayer(
      settings: settingsFor(role, resolved.brightness),
      shape: _shapeFor(shape),
      child: child,
    );
  }
}
