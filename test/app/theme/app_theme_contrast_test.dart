// test/app/theme/app_theme_contrast_test.dart
import 'dart:math' as math;

import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _worst(Color text, AppColors colors) {
  var worst = double.infinity;
  for (final base in <Color>{colors.background, colors.window}) {
    for (final stop in colors.glassTextStops) {
      worst = math.min(worst, _contrast(text, Color.alphaBlend(stop, base)));
    }
  }
  return worst;
}

void main() {
  final cases = <String, (AppColors, List<String>)>{
    'light': (
      AppTheme.light.colors,
      [
        'text',
        'textSecondary',
        'textSecondaryStrong',
        'link',
        'success',
        'warn',
        'danger',
        'purple',
      ],
    ),
    'dark': (
      AppTheme.dark.colors,
      [
        'text',
        'textSecondary',
        'textSecondaryStrong',
        'link',
        'success',
        'warn',
        'danger',
        'purple',
      ],
    ),
  };

  for (final MapEntry(key: mode, value: (colors, roles)) in cases.entries) {
    for (final role in roles) {
      test('$mode $role is at least 4.5:1 on the brightest glass stop', () {
        final color = colors.byName(role);
        expect(_worst(color, colors), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('income text uses success, not teal', () {
    expect(AppTheme.light.colors.moneyIncome, AppTheme.light.colors.success);
    expect(AppTheme.dark.colors.moneyIncome, AppTheme.dark.colors.success);
  });
}
