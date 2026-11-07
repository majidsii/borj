import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A 32 pt capsule chip with a 44 pt hit target. Off glass it is a row glass
/// capsule; on glass it is a [GlassInner].
class GlassChip extends StatelessWidget {
  const GlassChip({
    required this.label,
    this.onPressed,
    this.selected = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final tone = selected ? AppTextTone.link : AppTextTone.primary;
    const shape = AppleGlassShape.capsule();

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.selection : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 16, tone: tone),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: AppText(
                  label,
                  role: AppTextRole.footnote,
                  tone: tone,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final surface = GlassContext.isOnGlass(context)
        ? GlassInner(shape: shape, child: content)
        : AppGlass(role: GlassRole.row, shape: shape, child: content);

    return Pressable(
      onPressed: onPressed,
      selected: selected,
      hoverRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: surface,
      ),
    );
  }
}
