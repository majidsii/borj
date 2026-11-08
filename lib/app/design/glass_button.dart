import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum GlassButtonVariant { chrome, tinted, plain }

/// A 44 pt-minimum button. Off glass, chrome and tinted draw real glass; on
/// glass they fall back to [GlassInner] and a flat accent fill (no glass on
/// glass).
class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.onPressed,
    this.label,
    this.icon,
    this.variant = GlassButtonVariant.chrome,
    this.shape,
    this.semanticLabel,
    super.key,
  }) : assert(
         label != null || icon != null,
         'GlassButton needs a label or an icon',
       );

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final GlassButtonVariant variant;
  final AppleGlassShape? shape;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconOnly = label == null;
    final effectiveShape =
        shape ??
        (iconOnly
            ? const AppleGlassShape.circle()
            : const AppleGlassShape.capsule());
    final radius = BorderRadius.circular(
      effectiveShape.kind == AppleGlassShapeKind.rounded
          ? effectiveShape.radius
          : 999,
    );
    final tone = switch (variant) {
      GlassButtonVariant.tinted => AppTextTone.onTint,
      GlassButtonVariant.plain => AppTextTone.link,
      GlassButtonVariant.chrome => AppTextTone.primary,
    };

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly ? 0 : AppSpacing.s16,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) AppIcon(icon!, tone: tone),
            if (icon != null && label != null)
              const SizedBox(width: AppSpacing.s8),
            if (label != null)
              Flexible(
                child: AppText(
                  label!,
                  role: AppTextRole.callout,
                  tone: tone,
                  weight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );

    final onGlass = GlassContext.isOnGlass(context);
    final Widget surface;
    switch (variant) {
      case GlassButtonVariant.plain:
        surface = content;
      case GlassButtonVariant.chrome:
        surface = onGlass
            ? GlassInner(shape: effectiveShape, child: content)
            : AppGlass(
                role: GlassRole.chrome,
                shape: effectiveShape,
                child: content,
              );
      case GlassButtonVariant.tinted:
        surface = onGlass
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.of(context).colors.accent,
                  borderRadius: radius,
                ),
                child: content,
              )
            : AppGlass(
                role: GlassRole.tinted,
                shape: effectiveShape,
                child: content,
              );
    }

    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      hoverRadius: radius,
      dimsGlass: !onGlass && variant != GlassButtonVariant.plain,
      child: surface,
    );
  }
}
