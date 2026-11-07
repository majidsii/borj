import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// A single-line text field on a row-glass (off glass) or flat inner (on
/// glass) surface, with an accent focus ring.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textDirection,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextDirection? textDirection;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _focused = _node.hasFocus;
  }

  @override
  void didUpdateWidget(GlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      if (widget.focusNode != null) {
        _ownNode?.dispose();
        _ownNode = null;
      }
      _node.addListener(_onFocus);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colors;
    final reduced = MotionScope.reducedOf(context);
    const shape = AppleGlassShape.rounded(AppRadii.innerSmall);
    final radius = BorderRadius.circular(AppRadii.innerSmall);

    final field = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: widget.label,
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textDirection: widget.textDirection,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: colors.accent,
              style: theme.text.body.copyWith(color: colors.text),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: theme.text.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final surface = GlassContext.isOnGlass(context)
        ? GlassInner(shape: shape, child: field)
        : AppGlass(role: GlassRole.row, shape: shape, child: field);

    final ring = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _focused ? 1 : 0),
      duration: reduced ? Duration.zero : AppMotion.quick.duration,
      curve: AppMotion.quick.curve,
      builder: (context, alpha, _) => DecoratedBox(
        key: const ValueKey('glass-field-focus-ring'),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: colors.accent.withValues(alpha: alpha),
            width: 1.5,
          ),
        ),
      ),
    );

    final stack = Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _node.requestFocus,
          child: surface,
        ),
        Positioned.fill(child: IgnorePointer(child: ring)),
      ],
    );

    if (widget.label == null) return stack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AppText(
            widget.label!,
            role: AppTextRole.footnote,
            tone: AppTextTone.secondary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        stack,
      ],
    );
  }
}
