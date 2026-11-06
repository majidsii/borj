import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_platform_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleVisualPlatformResolver', () {
    test('maps Android and iOS to the iOS 27 visual family', () {
      expect(
        AppleVisualPlatformResolver.resolve(TargetPlatform.android),
        AppleVisualFamily.ios27,
      );
      expect(
        AppleVisualPlatformResolver.resolve(TargetPlatform.iOS),
        AppleVisualFamily.ios27,
      );
    });

    test('maps Windows Linux and macOS to the macOS 27 visual family', () {
      expect(
        AppleVisualPlatformResolver.resolve(TargetPlatform.windows),
        AppleVisualFamily.macos27,
      );
      expect(
        AppleVisualPlatformResolver.resolve(TargetPlatform.linux),
        AppleVisualFamily.macos27,
      );
      expect(
        AppleVisualPlatformResolver.resolve(TargetPlatform.macOS),
        AppleVisualFamily.macos27,
      );
    });
  });
}
