import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'apple_source_token_mapper.dart';
import 'apple_visual_platform_resolver.dart';
import 'apple_visual_theme.dart';

final class AppleVisualScope extends InheritedWidget {
  const AppleVisualScope({required this.data, required super.child, super.key});

  final AppleVisualThemeData data;

  static AppleVisualThemeData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppleVisualScope>();
    if (scope != null) {
      return scope.data;
    }
    return resolve(
      brightness: Theme.of(context).brightness,
      platform: defaultTargetPlatform,
    );
  }

  static AppleVisualThemeData resolve({
    required Brightness brightness,
    required TargetPlatform platform,
  }) {
    final family = AppleVisualPlatformResolver.resolve(platform);
    return AppleVisualThemeData(
      family: family,
      brightness: brightness,
      colors: AppleSourceTokenMapper.colors(
        family: family,
        brightness: brightness,
      ),
      typography: AppleSourceTokenMapper.typography(family: family),
      metrics: AppleSourceTokenMapper.metrics(family: family),
      materials: AppleSourceTokenMapper.materials(family: family),
      motion: AppleSourceTokenMapper.motion(family: family),
    );
  }

  @override
  bool updateShouldNotify(AppleVisualScope oldWidget) => oldWidget.data != data;
}
