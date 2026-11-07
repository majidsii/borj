import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../theme/app_theme.dart';
import '../foundation/apple_glass_shape.dart';
import '../foundation/apple_liquid_glass_recipe.dart';
import '../foundation/apple_visual_scope.dart';
import '../foundation/apple_visual_state.dart';
import '../foundation/apple_visual_theme.dart';
import '../foundation/glass_preferences_scope.dart';

final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.role,
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    this.state = AppleControlState.idle,
    this.theme,
    super.key,
  });

  final AppleGlassRole role;
  final Widget child;
  final AppleGlassShape shape;
  final AppleControlState state;
  final AppleVisualThemeData? theme;

  @visibleForTesting
  static LiquidGlassSettings settingsFor(
    AppleGlassRole role,
    Brightness brightness,
  ) {
    return switch (role) {
      AppleGlassRole.overGlassControl => LiquidGlassSettings.ios27Clear(),
      _ => LiquidGlassSettings.ios27Regular(brightness: brightness),
    };
  }

  static LiquidShape _shapeFor(AppleGlassShape shape) {
    return switch (shape.kind) {
      AppleGlassShapeKind.capsule => const LiquidRoundedSuperellipse(
        borderRadius: 999,
      ),
      AppleGlassShapeKind.rounded => LiquidRoundedSuperellipse(
        borderRadius: shape.radius,
      ),
      AppleGlassShapeKind.circle => const LiquidOval(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? AppleVisualScope.of(context);
    return LiquidGlass.withOwnLayer(
      settings: settingsFor(role, resolved.brightness),
      shape: _shapeFor(shape),
      child: child,
    );
  }
}

enum GlassRole { chrome, tinted, panel, row, sheet, clear }

enum GlassLayerKind {
  chrome,
  content,
  sheet,
  clear;

  static GlassLayerKind forRole(GlassRole role) => switch (role) {
    GlassRole.chrome || GlassRole.tinted => GlassLayerKind.chrome,
    GlassRole.panel || GlassRole.row => GlassLayerKind.content,
    GlassRole.sheet => GlassLayerKind.sheet,
    GlassRole.clear => GlassLayerKind.clear,
  };

  bool allows(GlassRole role) => switch (this) {
    GlassLayerKind.chrome =>
      role == GlassRole.chrome || role == GlassRole.tinted,
    GlassLayerKind.content =>
      role == GlassRole.panel ||
          role == GlassRole.row ||
          role == GlassRole.tinted,
    GlassLayerKind.sheet => role == GlassRole.sheet || role == GlassRole.tinted,
    GlassLayerKind.clear => role == GlassRole.clear,
  };
}

LiquidShape _liquidShape(AppleGlassShape shape) => switch (shape.kind) {
  AppleGlassShapeKind.capsule => const LiquidRoundedSuperellipse(
    borderRadius: 999,
  ),
  AppleGlassShapeKind.rounded => LiquidRoundedSuperellipse(
    borderRadius: shape.radius,
  ),
  AppleGlassShapeKind.circle => const LiquidOval(),
};

/// Inherited marker so [AppGlass] knows it sits inside a [GlassScope].
final class _GlassScopeMarker extends InheritedWidget {
  const _GlassScopeMarker({required this.kind, required super.child});

  final GlassLayerKind kind;

  @override
  bool updateShouldNotify(_GlassScopeMarker oldWidget) =>
      oldWidget.kind != kind;
}

/// Marks the subtree of one glass shape (spec: no glass on glass).
final class _OnGlassMarker extends InheritedWidget {
  const _OnGlassMarker({required super.child});

  @override
  bool updateShouldNotify(_OnGlassMarker oldWidget) => false;
}

/// Marks a subtree whose glass joins the nearest Flutter BackdropGroup.
final class _GlassGroupMarker extends InheritedWidget {
  const _GlassGroupMarker({required super.child});

  @override
  bool updateShouldNotify(_GlassGroupMarker oldWidget) => false;
}

abstract final class GlassContext {
  /// True inside an [AppGlass]: draw with GlassInner or a flat fill there.
  static bool isOnGlass(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnGlassMarker>() != null;

  static bool _joinsGroup(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GlassGroupMarker>() != null;
}

/// Bare backdrop group at the app root, for overlays (sheets, toasts). Screen
/// glass does not join it; only [GlassOverlayContent] does.
final class GlassOverlayBackdrop extends StatelessWidget {
  const GlassOverlayBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);
}

/// Wraps overlay content (a sheet, a toast) so its glass shares the root group.
final class GlassOverlayContent extends StatelessWidget {
  const GlassOverlayContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => _GlassGroupMarker(child: child);
}

/// One glass shape of the redesign (spec §3.1). Visuals come from the role,
/// the theme and [GlassPreferencesScope]; the constructor takes none.
final class AppGlass extends StatelessWidget {
  const AppGlass({
    required this.role,
    required this.child,
    this.shape = const AppleGlassShape.capsule(),
    super.key,
  });

  final GlassRole role;
  final Widget child;
  final AppleGlassShape shape;

  @visibleForTesting
  static LiquidGlassSettings settingsFor(
    GlassLayerKind kind,
    Brightness brightness,
    double intensity,
  ) {
    return switch (kind) {
      GlassLayerKind.chrome ||
      GlassLayerKind.content => LiquidGlassSettings.ios27Regular(
        brightness: brightness,
        tintAmount: intensity,
      ),
      GlassLayerKind.sheet => LiquidGlassSettings.ios27Regular(
        brightness: brightness,
        tintAmount: math.min(1.0, intensity + 0.25),
      ),
      GlassLayerKind.clear => LiquidGlassSettings.ios27Clear(
        tintAmount: intensity,
      ),
    };
  }

  static bool _fake(GlassLayerKind kind, GlassPreferences preferences) =>
      kind == GlassLayerKind.content && preferences.reduceTransparency;

  LiquidGlassAppearance _appearance(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return switch (role) {
      GlassRole.tinted => LiquidGlassAppearance.ios27Regular(
        brightness: brightness,
        tint: AppTheme.of(context).colors.accent.withValues(alpha: 0.9),
      ),
      GlassRole.clear => const LiquidGlassAppearance.ios27Clear(),
      _ => LiquidGlassAppearance.ios27Regular(brightness: brightness),
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !GlassContext.isOnGlass(context),
      'AppGlass inside another AppGlass: use GlassInner (no glass on glass)',
    );
    final marker = context
        .dependOnInheritedWidgetOfExactType<_GlassScopeMarker>();
    if (marker != null) {
      assert(
        marker.kind.allows(role),
        'GlassRole.${role.name} does not belong in a ${marker.kind.name} '
        'GlassScope',
      );
      return LiquidGlass.grouped(
        shape: _liquidShape(shape),
        appearance: _appearance(context),
        child: _OnGlassMarker(child: child),
      );
    }
    final kind = GlassLayerKind.forRole(role);
    final preferences = GlassPreferencesScope.of(context);
    return LiquidGlass.withOwnLayer(
      settings: settingsFor(
        kind,
        Theme.of(context).brightness,
        preferences.intensity,
      ),
      fake: _fake(kind, preferences),
      useBackdropGroup: GlassContext._joinsGroup(context),
      shape: _liquidShape(shape),
      appearance: _appearance(context),
      child: _OnGlassMarker(child: child),
    );
  }
}

/// One `LiquidGlassLayer` for a section of up to 16 shapes (renderer cap).
final class GlassScope extends StatelessWidget {
  const GlassScope({required this.kind, required this.child, super.key});

  final GlassLayerKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preferences = GlassPreferencesScope.of(context);
    return LiquidGlassLayer(
      settings: AppGlass.settingsFor(
        kind,
        Theme.of(context).brightness,
        preferences.intensity,
      ),
      fake: AppGlass._fake(kind, preferences),
      useBackdropGroup: GlassContext._joinsGroup(context),
      child: _GlassScopeMarker(kind: kind, child: child),
    );
  }
}

/// Scopes below one group read one shared backdrop: one capture per frame.
final class GlassBackdropGroup extends StatelessWidget {
  const GlassBackdropGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BackdropGroup(child: _GlassGroupMarker(child: child));
}
