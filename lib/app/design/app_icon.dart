// ignore_for_file: non_const_argument_for_const_parameter
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// An icon tinted by an [AppTextTone]. With [directional] it mirrors in RTL
/// through `IconData.matchTextDirection`.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size = 20,
    this.tone = AppTextTone.primary,
    this.directional = false,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final double size;
  final AppTextTone tone;
  final bool directional;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = tone.resolve(AppTheme.of(context).colors);
    // Rebuilt only to set matchTextDirection. This makes the instance
    // non-const, which blocks release icon tree-shaking (see report).
    final data = IconData(
      icon.codePoint,
      fontFamily: icon.fontFamily,
      fontPackage: icon.fontPackage,
      fontFamilyFallback: icon.fontFamilyFallback,
      matchTextDirection: directional,
    );
    final child = Icon(
      data,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
    return semanticLabel == null ? ExcludeSemantics(child: child) : child;
  }
}
