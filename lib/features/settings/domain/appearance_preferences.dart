import 'package:flutter/material.dart';

enum AppearanceMode {
  light,
  dark,
  system;

  ThemeMode get themeMode => switch (this) {
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.dark => ThemeMode.dark,
    AppearanceMode.system => ThemeMode.system,
  };
}

@immutable
final class AppearancePreferences {
  const AppearancePreferences({
    this.mode = AppearanceMode.system,
    this.glassIntensity = 0.5,
    this.reduceMotion = false,
    this.reduceTransparency = false,
  });

  factory AppearancePreferences.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return defaults;
    }
    final mode = AppearanceMode.values
        .where((value) => value.name == json['mode'])
        .firstOrNull;
    final intensity = json['glassIntensity'];
    final reduceMotion = json['reduceMotion'];
    final reduceTransparency = json['reduceTransparency'];
    return AppearancePreferences(
      mode: mode ?? defaults.mode,
      glassIntensity: intensity is num
          ? intensity.toDouble().clamp(0.0, 1.0)
          : defaults.glassIntensity,
      reduceMotion: reduceMotion is bool ? reduceMotion : defaults.reduceMotion,
      reduceTransparency: reduceTransparency is bool
          ? reduceTransparency
          : defaults.reduceTransparency,
    );
  }

  static const AppearancePreferences defaults = AppearancePreferences();

  final AppearanceMode mode;

  /// Liquid Glass slider: 0 = clear, 1 = tinted.
  final double glassIntensity;
  final bool reduceMotion;
  final bool reduceTransparency;

  AppearancePreferences copyWith({
    AppearanceMode? mode,
    double? glassIntensity,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) {
    return AppearancePreferences(
      mode: mode ?? this.mode,
      glassIntensity: (glassIntensity ?? this.glassIntensity).clamp(0.0, 1.0),
      reduceMotion: reduceMotion ?? this.reduceMotion,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'glassIntensity': glassIntensity,
    'reduceMotion': reduceMotion,
    'reduceTransparency': reduceTransparency,
  };

  @override
  bool operator ==(Object other) =>
      other is AppearancePreferences &&
      other.mode == mode &&
      other.glassIntensity == glassIntensity &&
      other.reduceMotion == reduceMotion &&
      other.reduceTransparency == reduceTransparency;

  @override
  int get hashCode =>
      Object.hash(mode, glassIntensity, reduceMotion, reduceTransparency);
}

abstract interface class AppearancePreferencesStore {
  Future<AppearancePreferences> load();

  Future<void> save(AppearancePreferences value);
}
