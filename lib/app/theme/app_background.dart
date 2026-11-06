// lib/app/theme/app_background.dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppBackgroundKind { phone, desk }

/// Light: pure white. Dark: charcoal gradient with warm light from the top
/// leading corner (top-right in RTL), as on the boards (`source/build.py`).
final class AppBackground extends StatelessWidget {
  const AppBackground({required this.kind, required this.child, super.key});

  final AppBackgroundKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    if (Theme.of(context).brightness == Brightness.light) {
      return ColoredBox(color: colors.background, child: child);
    }
    final glow = kind == AppBackgroundKind.phone
        ? colors.warmGlow
        : colors.warmGlow.withValues(alpha: 0.30);
    final corner = AlignmentDirectional.topStart.resolve(
      Directionality.of(context),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.backdropTop, colors.backdropBottom],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: corner,
            radius: kind == AppBackgroundKind.phone ? 0.95 : 0.8,
            colors: [glow, glow.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ),
        ),
        child: child,
      ),
    );
  }
}
