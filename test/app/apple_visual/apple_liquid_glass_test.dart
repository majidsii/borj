import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleLiquidGlass source contract', () {
    test('public constructor exposes no raw visual override parameters', () {
      final source = File(
        'lib/app/apple_visual/widgets/apple_liquid_glass.dart',
      ).readAsStringSync();

      final constructor = RegExp(
        r'const AppleLiquidGlass\(\{[\s\S]*?\}\);',
      ).firstMatch(source);

      expect(constructor, isNotNull);

      final contract = constructor!.group(0)!;

      for (final forbidden in <String>['blurSigma', 'opacity', 'borderColor']) {
        expect(contract, isNot(contains(forbidden)));
      }
    });
  });
}
