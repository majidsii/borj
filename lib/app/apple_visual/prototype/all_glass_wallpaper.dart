// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'all_glass_kit.dart';

/// Vivid Persian-tile wallpaper made of large soft blobs that drift slowly.
class AllGlassWallpaper extends StatefulWidget {
  const AllGlassWallpaper({super.key});

  @override
  State<AllGlassWallpaper> createState() => _AllGlassWallpaperState();
}

class _AllGlassWallpaperState extends State<AllGlassWallpaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WallpaperPainter(_controller),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Blob {
  const _Blob(this.color, this.x, this.y, this.r, this.phase);
  final Color color;
  final double x;
  final double y;
  final double r;
  final double phase;
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const List<_Blob> _blobs = <_Blob>[
    _Blob(GlassPalette.turquoise, 0.15, 0.16, 0.50, 0.0),
    _Blob(GlassPalette.saffron, 0.92, 0.30, 0.46, 1.3),
    _Blob(GlassPalette.pomegranate, 0.10, 0.52, 0.48, 2.4),
    _Blob(GlassPalette.violet, 0.85, 0.66, 0.48, 3.6),
    _Blob(GlassPalette.turquoise, 0.35, 0.88, 0.50, 4.7),
    _Blob(GlassPalette.saffron, 0.05, 0.96, 0.36, 5.5),
    _Blob(GlassPalette.pomegranate, 0.95, 0.96, 0.40, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[GlassPalette.lapis, Color(0xFF16276B)],
        ).createShader(Offset.zero & size),
    );
    final angle = t.value * 2 * math.pi;
    final base = size.shortestSide;
    for (final b in _blobs) {
      final dx = math.sin(angle + b.phase) * 0.07 * size.width;
      final dy = math.cos(angle * 2 + b.phase) * 0.04 * size.height;
      final center = Offset(b.x * size.width + dx, b.y * size.height + dy);
      final radius = b.r * base * 1.25;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              b.color.withValues(alpha: 0.95),
              b.color.withValues(alpha: 0.0),
            ],
            stops: const <double>[0.25, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter oldDelegate) => oldDelegate.t != t;
}
