import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults follow the spec', () {
    const p = AppearancePreferences.defaults;
    expect(p.mode, AppearanceMode.system);
    expect(p.glassIntensity, 0.5);
    expect(p.reduceMotion, isFalse);
    expect(p.reduceTransparency, isFalse);
  });

  test('mode maps to ThemeMode', () {
    expect(AppearanceMode.light.themeMode, ThemeMode.light);
    expect(AppearanceMode.dark.themeMode, ThemeMode.dark);
    expect(AppearanceMode.system.themeMode, ThemeMode.system);
  });

  test('json round-trips', () {
    const p = AppearancePreferences(
      mode: AppearanceMode.dark,
      glassIntensity: 0.25,
      reduceMotion: true,
      reduceTransparency: true,
    );
    expect(AppearancePreferences.fromJson(p.toJson()), p);
  });

  test('decoding is tolerant per field', () {
    expect(
      AppearancePreferences.fromJson(null),
      AppearancePreferences.defaults,
    );
    expect(AppearancePreferences.fromJson('x'), AppearancePreferences.defaults);
    final decoded = AppearancePreferences.fromJson(<String, Object?>{
      'mode': 'sepia',
      'glassIntensity': 3,
      'reduceMotion': 'yes',
      'reduceTransparency': true,
    });
    expect(decoded.mode, AppearanceMode.system);
    expect(decoded.glassIntensity, 1.0);
    expect(decoded.reduceMotion, isFalse);
    expect(decoded.reduceTransparency, isTrue);
    expect(
      AppearancePreferences.fromJson(<String, Object?>{
        'glassIntensity': -1,
      }).glassIntensity,
      0.0,
    );
    expect(
      AppearancePreferences.fromJson(<String, Object?>{
        'glassIntensity': 'a',
      }).glassIntensity,
      0.5,
    );
  });
}
