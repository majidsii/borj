import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

typedef GlassTestVariant = ({
  String name,
  Brightness brightness,
  double textScale,
});

const List<GlassTestVariant> glassTestVariants = [
  (name: 'light 1.0', brightness: Brightness.light, textScale: 1.0),
  (name: 'dark 1.0', brightness: Brightness.dark, textScale: 1.0),
  (name: 'light 1.3', brightness: Brightness.light, textScale: 1.3),
  (name: 'dark 1.3', brightness: Brightness.dark, textScale: 1.3),
];

/// RTL app with AppTheme, the appearance scopes and the app background, as
/// BorjApp provides them. `overlayBackdrop` adds the app-root group.
Widget glassTestApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool reduceMotion = false,
  bool reduceTransparency = false,
  double intensity = 0.5,
  bool overlayBackdrop = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      extensions: [
        brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      ],
    ),
    builder: (context, navigator) {
      Widget app = MotionScope(
        reduceMotionSetting: false,
        child: GlassPreferencesScope(
          intensity: intensity,
          reduceTransparency: reduceTransparency,
          child: navigator ?? const SizedBox.shrink(),
        ),
      );
      if (overlayBackdrop) {
        app = GlassOverlayBackdrop(child: app);
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Directionality(textDirection: TextDirection.rtl, child: app),
      );
    },
    home: AppBackground(
      kind: AppBackgroundKind.phone,
      child: Material(
        type: MaterialType.transparency,
        child: Center(child: child),
      ),
    ),
  );
}
