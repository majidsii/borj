import 'dart:io';

import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_theme.dart';
import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleLiquidGlass source-consumption contract', () {
    testWidgets('resolves the exact source-backed tuple into diagnostics', (
      tester,
    ) async {
      final theme = _resolvedTheme(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
      );

      final widget = AppleLiquidGlass(
        theme: theme,
        role: AppleGlassRole.mediumSurface,
        state: AppleControlState.idle,
        child: const SizedBox(key: ValueKey<String>('liquid-glass-child')),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );

      final mounted = tester.widget<AppleLiquidGlass>(
        find.byType(AppleLiquidGlass),
      );

      final actual = mounted.debugRenderDiagnostics.recipe;

      final expected = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        role: AppleGlassRole.mediumSurface,
        state: AppleControlState.idle,
      );

      expect(actual.family, expected.family);
      expect(actual.brightness, expected.brightness);
      expect(actual.role, expected.role);
      expect(actual.state, expected.state);
      expect(actual.sourceIds, expected.sourceIds);
      expect(actual.sourceNames, expected.sourceNames);
      expect(actual.sourceValues, expected.sourceValues);
      expect(actual.roleMappingEvidence, expected.roleMappingEvidence);

      expect(
        find.byKey(const ValueKey<String>('liquid-glass-child')),
        findsOneWidget,
      );
    });

    test(
      'constructor defaults state to idle and requires no visual overrides',
      () {
        final theme = _resolvedTheme(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
        );

        final widget = AppleLiquidGlass(
          theme: theme,
          role: AppleGlassRole.smallControl,
          child: const SizedBox.shrink(),
        );

        expect(widget.theme, same(theme));
        expect(widget.role, AppleGlassRole.smallControl);
        expect(widget.state, AppleControlState.idle);
      },
    );

    test('public constructor exposes no raw visual override parameters', () {
      final source = File(
        'lib/app/apple_visual/widgets/apple_liquid_glass.dart',
      ).readAsStringSync();

      final constructor = RegExp(
        r'const AppleLiquidGlass\(\{[\s\S]*?\}\);',
      ).firstMatch(source);

      expect(constructor, isNotNull);

      final contract = constructor!.group(0)!;

      for (final forbidden in <String>[
        'blurSigma',
        'opacity',
        'radius',
        'borderColor',
      ]) {
        expect(contract, isNot(contains(forbidden)));
      }
    });
  });
}

AppleVisualThemeData _resolvedTheme({
  required AppleVisualFamily family,
  required Brightness brightness,
}) {
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
