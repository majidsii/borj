import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/glass_button.dart';
import 'package:flutter/material.dart';

/// One toolbar action a screen hands to the shell (the shell renders it in its
/// chrome scope; screens never paint chrome).
final class ShellAction {
  const ShellAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.leading = false,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onPressed;

  /// The tinted primary action (one per screen).
  final bool primary;

  /// Sits at the leading end (right in RTL); others at the trailing end.
  final bool leading;
}

/// A row of glass circle buttons: leading actions, a gap, trailing actions.
class ShellToolbar extends StatelessWidget {
  const ShellToolbar({
    required this.actions,
    required this.buttonSize,
    super.key,
  });

  final List<ShellAction> actions;
  final double buttonSize;

  Widget _button(BuildContext context, ShellAction a) => SizedBox(
    key: ValueKey('toolbar-${a.label}'),
    width: buttonSize,
    height: buttonSize,
    child: GlassButton(
      onPressed: () => a.onPressed(context),
      icon: a.icon,
      semanticLabel: a.label,
      variant: a.primary
          ? GlassButtonVariant.tinted
          : GlassButtonVariant.chrome,
      shape: const AppleGlassShape.circle(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final leading = [
      for (final a in actions)
        if (a.leading) a,
    ];
    final trailing = [
      for (final a in actions)
        if (!a.leading) a,
    ];
    List<Widget> spaced(List<ShellAction> list) => [
      for (var i = 0; i < list.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        _button(context, list[i]),
      ],
    ];
    return Row(
      children: [...spaced(leading), const Spacer(), ...spaced(trailing)],
    );
  }
}
