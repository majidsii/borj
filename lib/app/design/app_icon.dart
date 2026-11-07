import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// An icon tinted by an [AppTextTone].
///
/// Directional icons (back, forward, chevrons) are `IconData` constants that
/// already carry `matchTextDirection: true`, such as `Icons.arrow_back` and
/// `Icons.chevron_left`. Flutter's [Icon] mirrors them in RTL by itself, so
/// AppIcon needs no flag and never rebuilds the `IconData` (a non-const
/// instance would break release icon tree-shaking).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size = 20,
    this.tone = AppTextTone.primary,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final double size;
  final AppTextTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      size: size,
      color: tone.resolve(AppTheme.of(context).colors),
      semanticLabel: semanticLabel,
    );
    return semanticLabel == null ? ExcludeSemantics(child: child) : child;
  }
}
