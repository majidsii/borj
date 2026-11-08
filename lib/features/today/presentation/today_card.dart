import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/widgets.dart';

/// The glass panel every Today card sits in: one content scope, one panel.
class TodayCard extends StatelessWidget {
  const TodayCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget card = GlassScope(
      kind: GlassLayerKind.content,
      child: AppGlass(
        role: GlassRole.panel,
        shape: const AppleGlassShape.rounded(AppRadii.cardLarge),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel != null) {
      card = Semantics(container: true, label: semanticLabel, child: card);
    }
    return card;
  }
}
