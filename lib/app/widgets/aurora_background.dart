import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:flutter/material.dart';

/// Pixel-oriented port of the original `.bgfx` CSS layer.
///
/// The blob geometry deliberately uses `vmax` and RTL inline positions, just
/// like `src/app.html`. Keeping this in one painter also avoids four oversized
/// composited widgets and produces a much closer backdrop on wide windows.
final class AuroraBackground extends StatefulWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

final class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    // Long-running clock. Each CSS animation derives its own period below.
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(hours: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.maybeOf(context);
    final reduceMotion = media?.disableAnimations ?? false;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final seconds = reduceMotion ? 0.0 : _clock.value * 12 * 60 * 60;
              return CustomPaint(
                painter: _OriginalAuroraPainter(
                  palette: palette,
                  seconds: seconds,
                  dark: dark,
                ),
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: palette.grainOpacity,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/original_grain.png'),
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                      alignment: Alignment.topLeft,
                    ),
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

final class _OriginalAuroraPainter extends CustomPainter {
  const _OriginalAuroraPainter({
    required this.palette,
    required this.seconds,
    required this.dark,
  });

  final OriginalPalette palette;
  final double seconds;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = Offset.zero & size;
    final vmax = math.max(size.width, size.height);

    canvas.drawRect(
      viewport,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          <Color>[
            palette.backgroundTop,
            palette.backgroundMiddle,
            palette.backgroundBottom,
          ],
          const <double>[0, .52, 1],
        ),
    );

    // Keep the neutral base gradient sharp, while softening only the moving
    // decorative layer in dark mode. This prevents the bright sweep from
    // cutting through task inputs without washing out text or glass rims.
    if (dark) {
      canvas.saveLayer(
        viewport.inflate(
          OriginalDesignTokens.darkAuroraDecorationBlurSigma * 2,
        ),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: OriginalDesignTokens.darkAuroraDecorationBlurSigma,
            sigmaY: OriginalDesignTokens.darkAuroraDecorationBlurSigma,
            tileMode: TileMode.mirror,
          ),
      );
    }

    // `inset-inline-*` in the source HTML is evaluated in RTL:
    // inline-end = left, inline-start = right.
    _paintBlob(
      canvas,
      baseRect: Rect.fromLTWH(-.18 * vmax, -.24 * vmax, .62 * vmax, .62 * vmax),
      focalX: .40,
      focalY: .40,
      transparentAt: .64,
      color: palette.blob1,
      progress: _alternate(36),
      dx: -.07 * vmax,
      dy: .09 * vmax,
      scaleDelta: .14,
    );

    final b2Size = .54 * vmax;
    _paintBlob(
      canvas,
      baseRect: Rect.fromLTWH(
        size.width + .20 * vmax - b2Size,
        -.12 * vmax,
        b2Size,
        b2Size,
      ),
      focalX: .58,
      focalY: .46,
      transparentAt: .62,
      color: palette.blob2,
      progress: _alternate(46),
      dx: .09 * vmax,
      dy: .06 * vmax,
      scaleDelta: .10,
    );

    final b3Size = .58 * vmax;
    _paintBlob(
      canvas,
      baseRect: Rect.fromLTWH(
        size.width + .14 * vmax - b3Size,
        size.height + .26 * vmax - b3Size,
        b3Size,
        b3Size,
      ),
      focalX: .50,
      focalY: .42,
      transparentAt: .63,
      color: palette.blob3,
      progress: _alternate(52),
      dx: .08 * vmax,
      dy: -.08 * vmax,
      scaleDelta: .16,
    );

    final b4Size = .48 * vmax;
    _paintBlob(
      canvas,
      baseRect: Rect.fromLTWH(
        -.15 * vmax,
        size.height + .18 * vmax - b4Size,
        b4Size,
        b4Size,
      ),
      focalX: .46,
      focalY: .50,
      transparentAt: .62,
      color: palette.blob4,
      progress: _alternate(42),
      dx: -.08 * vmax,
      dy: -.06 * vmax,
      scaleDelta: .08,
    );

    _paintSheenBand(
      canvas,
      size,
      vmax,
      opacityScale: dark ? OriginalDesignTokens.darkSheenBandOpacityScale : 1,
    );

    if (dark) {
      canvas.restore();
    }
  }

  double _alternate(double durationSeconds) {
    final cycle = durationSeconds * 2;
    final position = (seconds % cycle) / cycle;
    return position <= .5 ? position * 2 : (1 - position) * 2;
  }

  void _paintBlob(
    Canvas canvas, {
    required Rect baseRect,
    required double focalX,
    required double focalY,
    required double transparentAt,
    required Color color,
    required double progress,
    required double dx,
    required double dy,
    required double scaleDelta,
  }) {
    final translatedCenter = baseRect.center + Offset(dx, dy) * progress;
    final scaledSize = baseRect.width * (1 + scaleDelta * progress);
    final rect = Rect.fromCenter(
      center: translatedCenter,
      width: scaledSize,
      height: scaledSize,
    );
    final focal = Offset(
      rect.left + rect.width * focalX,
      rect.top + rect.height * focalY,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          focal,
          rect.width * transparentAt,
          <Color>[color, color.withValues(alpha: 0)],
          const <double>[0, 1],
        ),
    );
    canvas.restore();
  }

  void _paintSheenBand(
    Canvas canvas,
    Size size,
    double vmax, {
    required double opacityScale,
  }) {
    final phase = (seconds % 48) / 48;
    double offset;
    double opacity;

    if (phase <= .14) {
      offset = -.95 * vmax;
      opacity = 0;
    } else if (phase <= .26) {
      final t = (phase - .14) / .12;
      offset = ui.lerpDouble(-.95 * vmax, -.50 * vmax, t)!;
      opacity = t;
    } else if (phase <= .52) {
      final t = (phase - .26) / .26;
      offset = ui.lerpDouble(-.50 * vmax, .95 * vmax, t)!;
      opacity = 1 - t;
    } else {
      offset = .95 * vmax;
      opacity = 0;
    }

    if (opacity <= 0) return;

    final bandWidth = .58 * vmax;
    final bandHeight = size.height * 1.9;

    canvas.save();
    // In RTL the source band starts at the physical right edge.
    canvas.translate(size.width - bandWidth / 2 + offset, size.height / 2);
    canvas.rotate(16 * math.pi / 180);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: bandWidth,
      height: bandHeight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.left, 0),
          Offset(rect.right, 0),
          <Color>[
            Colors.transparent,
            palette.sheenBand.withValues(alpha: opacity * opacityScale),
            Colors.transparent,
          ],
          const <double>[0, .5, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OriginalAuroraPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.seconds != seconds ||
        oldDelegate.dark != dark;
  }
}
