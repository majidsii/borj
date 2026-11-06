import 'dart:ui' as ui;

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:flutter/material.dart';

/// Faithful port of the original `.glass` material from `src/app.html`.
///
/// CSS uses `backdrop-filter: blur(28px) saturate(185%)`. Flutter does not
/// expose a single combined backdrop filter, so the blurred backdrop is
/// isolated in its own layer and then receives the matching saturation matrix.
final class OriginalGlass extends StatelessWidget {
  const OriginalGlass({
    required this.child,
    super.key,
    this.padding,
    this.radius = OriginalDesignTokens.glassRadius,
    this.blurSigma = OriginalDesignTokens.glassBlurSigma,
    this.saturation = OriginalDesignTokens.glassSaturation,
    this.fill,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final double saturation;
  final Color? fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    Widget result = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadowPrimary,
              blurRadius: dark ? 50 : 44,
              offset: Offset(0, dark ? 16 : 14),
            ),
            BoxShadow(
              color: palette.shadowSecondary,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              Positioned.fill(
                child: _SaturatedBackdrop(
                  blurSigma: blurSigma,
                  saturation: saturation,
                ),
              ),
              CustomPaint(
                painter: _GlassFillPainter(
                  radius: radius,
                  palette: palette,
                  solidFill: fill,
                ),
                foregroundPainter: _GlassRimPainter(
                  radius: radius,
                  palette: palette,
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: result,
        ),
      );
    }
    return result;
  }
}

final class _SaturatedBackdrop extends StatelessWidget {
  const _SaturatedBackdrop({required this.blurSigma, required this.saturation});

  final double blurSigma;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.mirror,
        ),
        child: const ColoredBox(color: Colors.transparent),
      ),
    );
  }
}

List<double> _saturationMatrix(double saturation) {
  const red = .2126;
  const green = .7152;
  const blue = .0722;
  final inverse = 1 - saturation;

  return <double>[
    red * inverse + saturation,
    green * inverse,
    blue * inverse,
    0,
    0,
    red * inverse,
    green * inverse + saturation,
    blue * inverse,
    0,
    0,
    red * inverse,
    green * inverse,
    blue * inverse + saturation,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

final class _GlassFillPainter extends CustomPainter {
  const _GlassFillPainter({
    required this.radius,
    required this.palette,
    required this.solidFill,
  });

  final double radius;
  final OriginalPalette palette;
  final Color? solidFill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rrect);

    if (solidFill != null) {
      canvas.drawRect(rect, Paint()..color = solidFill!);
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, <Color>[
            palette.glassStart,
            palette.glassEnd,
          ]),
      );
    }

    // CSS: radial-gradient(130% 65% at 50% -18%, ... 55%).
    final center = Offset(size.width * .5, size.height * -.18);
    final radiusX = size.width * .65;
    final radiusY = size.height * .325;
    if (radiusX > 0 && radiusY > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1, radiusY / radiusX);
      canvas.drawCircle(
        Offset.zero,
        radiusX,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            radiusX,
            <Color>[
              palette.sheen.withValues(alpha: palette.sheenOpacity),
              Colors.transparent,
            ],
            const <double>[0, .55],
          ),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassFillPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.palette != palette ||
        oldDelegate.solidFill != solidFill;
  }
}

final class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({required this.radius, required this.palette});

  final double radius;
  final OriginalPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(.6),
      Radius.circular((radius - .6).clamp(0, radius).toDouble()),
    );

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.linear(
        Offset(size.width * .06, 0),
        Offset(size.width * .94, size.height),
        <Color>[
          palette.rimStart,
          palette.rimMid,
          palette.rimLow,
          palette.rimEnd,
        ],
        const <double>[0, .32, .60, 1],
      );
    canvas.drawRRect(rrect, rim);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.palette != palette;
  }
}

/// Faithful port of `.f-input`, `.f-select`, `.btn-ghost`, and related inner
/// glass controls.
final class OriginalFieldSurface extends StatelessWidget {
  const OriginalFieldSurface({
    required this.child,
    super.key,
    this.radius = OriginalDesignTokens.fieldRadius,
    this.padding,
    this.blurSigma = OriginalDesignTokens.fieldBlurSigma,
    this.saturation = OriginalDesignTokens.fieldSaturation,
    this.focused = false,
    this.fill,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double saturation;
  final bool focused;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: focused
              ? <BoxShadow>[
                  BoxShadow(
                    color: palette.accentSoft,
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              Positioned.fill(
                child: _SaturatedBackdrop(
                  blurSigma: blurSigma,
                  saturation: saturation,
                ),
              ),
              CustomPaint(
                painter: _InnerSurfacePainter(
                  radius: radius,
                  palette: palette,
                  focused: focused,
                  fill: fill,
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _InnerSurfacePainter extends CustomPainter {
  const _InnerSurfacePainter({
    required this.radius,
    required this.palette,
    required this.focused,
    required this.fill,
  });

  final double radius;
  final OriginalPalette palette;
  final bool focused;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill ?? palette.field);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(.5),
        Radius.circular((radius - .5).clamp(0, radius).toDouble()),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 1.4 : 1
        ..color = focused ? palette.accent : palette.hair,
    );

    final topPath = Path()
      ..moveTo(radius, .5)
      ..lineTo(size.width - radius, .5);
    canvas.drawPath(
      topPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = palette.hairTop,
    );
  }

  @override
  bool shouldRepaint(covariant _InnerSurfacePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.palette != palette ||
        oldDelegate.focused != focused ||
        oldDelegate.fill != fill;
  }
}
