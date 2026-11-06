import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pointer interaction matching the original CSS controls: no Material ripple,
/// a spring-like press scale, and a hand cursor on desktop.
final class OriginalPressable extends StatefulWidget {
  const OriginalPressable({
    required this.child,
    required this.onPressed,
    super.key,
    this.pressedScale = .95,
    this.borderRadius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  State<OriginalPressable> createState() => _OriginalPressableState();
}

final class _OriginalPressableState extends State<OriginalPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final content = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: const Duration(milliseconds: 180),
      curve: const Cubic(.32, 1.35, .4, 1),
      child: widget.child,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: enabled ? content : Opacity(opacity: .48, child: content),
        ),
      ),
    );
  }
}

final class OriginalPrimaryButton extends StatelessWidget {
  const OriginalPrimaryButton({
    required this.onPressed,
    super.key,
    this.label,
    this.icon,
    this.compact = false,
    this.square = false,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final bool compact;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = BorderRadius.circular(OriginalDesignTokens.pillRadius);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) Icon(icon, color: Colors.white, size: 16),
        if (icon != null && label != null) const SizedBox(width: 8),
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14 : 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );

    return OriginalPressable(
      onPressed: onPressed,
      pressedScale: .94,
      borderRadius: radius,
      semanticLabel: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[palette.accent, palette.accent2],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.accent.withValues(alpha: .35),
              blurRadius: compact ? 20 : 26,
              offset: Offset(0, compact ? 8 : 10),
            ),
            const BoxShadow(color: Color(0x8CFFFFFF), offset: Offset(0, -1)),
          ],
        ),
        child: SizedBox(
          width: square ? 48 : null,
          height: square ? 48 : (compact ? 40 : 44),
          child: Padding(
            padding: square
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(horizontal: compact ? 17 : 22),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

final class OriginalGhostButton extends StatelessWidget {
  const OriginalGhostButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = BorderRadius.circular(OriginalDesignTokens.pillRadius);
    return OriginalFieldSurface(
      radius: OriginalDesignTokens.pillRadius,
      blurSigma: 16,
      saturation: 1.60,
      child: OriginalPressable(
        onPressed: onPressed,
        borderRadius: radius,
        semanticLabel: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 15, color: palette.ink),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class OriginalPills extends StatelessWidget {
  const OriginalPills({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
    this.compact = false,
  });

  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List<Widget>.generate(items.length, (index) {
        final active = index == selected;
        final radius = BorderRadius.circular(OriginalDesignTokens.pillRadius);
        return OriginalPressable(
          onPressed: () => onSelected(index),
          pressedScale: .96,
          borderRadius: radius,
          semanticLabel: items[index],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: active ? palette.thumb : Colors.transparent,
              border: active ? Border.all(color: palette.hair, width: 1) : null,
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: palette.shadowSecondary,
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: palette.hairTop,
                        offset: const Offset(0, -1),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 5.5 : 6.5,
            ),
            child: Text(
              items[index],
              style: TextStyle(
                color: active ? palette.ink : palette.muted,
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }),
    );
  }
}

final class OriginalTextField extends StatefulWidget {
  const OriginalTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.pill = false,
    this.suffix,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final bool pill;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<OriginalTextField> createState() => _OriginalTextFieldState();
}

final class _OriginalTextFieldState extends State<OriginalTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = widget.pill
        ? OriginalDesignTokens.pillRadius
        : OriginalDesignTokens.fieldRadius;

    return OriginalFieldSurface(
      radius: radius,
      focused: _focusNode.hasFocus,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        textDirection: widget.textDirection,
        textAlign: widget.textAlign,
        cursorColor: palette.accent,
        style: TextStyle(
          color: palette.ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: palette.faint,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon, color: palette.faint, size: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: widget.suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}
