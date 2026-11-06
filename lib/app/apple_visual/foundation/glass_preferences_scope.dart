import 'package:flutter/widgets.dart';

@immutable
final class GlassPreferences {
  const GlassPreferences({
    this.intensity = 0.5,
    this.reduceTransparency = false,
  });

  final double intensity;
  final bool reduceTransparency;
}

/// Carries the glass intensity slider and «کاهش شفافیت» to every glass widget,
/// so the glass constructors take no visual parameters.
final class GlassPreferencesScope extends InheritedWidget {
  const GlassPreferencesScope({
    required this.intensity,
    required this.reduceTransparency,
    required super.child,
    super.key,
  });

  final double intensity;
  final bool reduceTransparency;

  static GlassPreferences of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GlassPreferencesScope>();
    return scope == null
        ? const GlassPreferences()
        : GlassPreferences(
            intensity: scope.intensity,
            reduceTransparency: scope.reduceTransparency,
          );
  }

  @override
  bool updateShouldNotify(GlassPreferencesScope oldWidget) =>
      oldWidget.intensity != intensity ||
      oldWidget.reduceTransparency != reduceTransparency;
}
