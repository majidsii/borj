import 'package:borj/app/apple_visual/foundation/apple_glass_shape.dart';
import 'package:borj/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_theme.dart';
import 'package:borj/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/app/widgets/aurora_background.dart';
import 'package:flutter/material.dart';

/// One review row: a label and a sample that is built per theme.
final class GlassReviewSample {
  const GlassReviewSample(this.label, this.build);

  final String label;
  final Widget Function(AppleVisualThemeData theme) build;
}

final List<GlassReviewSample> glassReviewSamples = <GlassReviewSample>[
  GlassReviewSample(
    'Top-bar capsule',
    (theme) => _glass(
      theme,
      AppleGlassRole.mediumSurface,
      const AppleGlassShape.capsule(),
      const SizedBox(width: 220, height: 52),
    ),
  ),
  GlassReviewSample(
    'Tab control',
    (theme) => _glass(
      theme,
      AppleGlassRole.smallControl,
      const AppleGlassShape.capsule(),
      const SizedBox(width: 180, height: 40),
    ),
  ),
  GlassReviewSample(
    'Circle button',
    (theme) => _glass(
      theme,
      AppleGlassRole.smallControl,
      const AppleGlassShape.circle(),
      const SizedBox(width: 48, height: 48),
    ),
  ),
  GlassReviewSample(
    'Dialog surface',
    (theme) => _glass(
      theme,
      AppleGlassRole.largeSurface,
      const AppleGlassShape.rounded(28),
      const SizedBox(width: 240, height: 120),
    ),
  ),
];

Widget _glass(
  AppleVisualThemeData theme,
  AppleGlassRole role,
  AppleGlassShape shape,
  Widget child,
) {
  return AppleLiquidGlass(role: role, shape: shape, theme: theme, child: child);
}

/// Gradient, stripes and aurora behind a sample so refraction is visible.
final class GlassReviewBackdrop extends StatelessWidget {
  const GlassReviewBackdrop({
    required this.dark,
    required this.child,
    super.key,
  });

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: dark ? OriginalTheme.dark() : OriginalTheme.light(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dark
                        ? const <Color>[Color(0xFF101828), Color(0xFF3B2A6B)]
                        : const <Color>[Color(0xFFEAF2FF), Color(0xFFFFE3F1)],
                  ),
                ),
              ),
              const Positioned.fill(child: AuroraBackground(child: SizedBox())),
              Positioned.fill(
                child: CustomPaint(
                  painter: _StripesPainter(
                    dark ? const Color(0x33FFFFFF) : const Color(0x33000000),
                  ),
                ),
              ),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StripesPainter extends CustomPainter {
  const _StripesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 8, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => oldDelegate.color != color;
}
