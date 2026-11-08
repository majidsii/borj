import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/glass_button.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// A calm empty state: icon, title, message, optional primary action. It
/// appears with a `quick` fade; the glass button fades through
/// [GlassVisibility], the flat parts through [Opacity].
class EmptyState extends StatefulWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fade.value == 0 && !_fade.isAnimating) {
      final m = MotionScope.reducedOf(context)
          ? AppMotion.reduced
          : AppMotion.quick;
      _fade.animateTo(1, duration: m.duration, curve: m.curve);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final t = _fade.value.clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: t,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(widget.icon, size: 40, tone: AppTextTone.secondary),
                    const SizedBox(height: AppSpacing.s12),
                    AppText(
                      widget.title,
                      role: AppTextRole.headline,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.message != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      AppText(
                        widget.message!,
                        role: AppTextRole.subheadline,
                        tone: AppTextTone.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: AppSpacing.s16),
                GlassVisibility(
                  value: t,
                  child: GlassButton(
                    onPressed: widget.onAction,
                    label: widget.actionLabel,
                    variant: GlassButtonVariant.tinted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
