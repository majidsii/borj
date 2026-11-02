import 'dart:ui';

import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/geometry/apple_glass_applied_geometry.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/geometry/apple_glass_applied_geometry_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/geometry/apple_glass_shadow_geometry.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_material_layer_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_material_layers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const appliedGeometryResolver = AppleGlassAppliedGeometryResolver();
  const materialResolver = AppleGlassMaterialLayerResolver();

  late AppleGlassAppliedGeometry geometry;
  late AppleGlassSourceMaterialLayers material;

  setUp(() {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    geometry = appliedGeometryResolver.resolve(
      recipe: recipe,
      canvasSize: const Size(110, 78),
    )!;

    material = materialResolver.resolve(recipe);
  });

  AppleGlassSourceShadowLayer shadow(int index) =>
      material.shadows.singleWhere((shadow) => shadow.index == index);

  test('zero spread preserves source shape before applying offset', () {
    final result = AppleGlassShadowGeometry.resolve(
      geometry: geometry,
      shadow: shadow(0),
    );

    expect(result.shape, geometry.scaledShape.shift(const Offset(0, 8)));
    expect(result.shape.outerRect, const Rect.fromLTRB(15, 15, 95, 63));
    expect(result.blurRadius, 15);
  });

  test('positive spread expands the source superellipse', () {
    final result = AppleGlassShadowGeometry.resolve(
      geometry: geometry,
      shadow: shadow(1),
    );

    expect(result.shape, geometry.scaledShape.inflate(0.5));
    expect(result.shape.outerRect, const Rect.fromLTRB(14.5, 6.5, 95.5, 55.5));
    expect(result.blurRadius, 0);
  });

  test('negative spread contracts before applying x offset', () {
    final result = AppleGlassShadowGeometry.resolve(
      geometry: geometry,
      shadow: shadow(2),
    );

    expect(
      result.shape,
      geometry.scaledShape.inflate(-0.75).shift(const Offset(-1.25, 0)),
    );
    expect(result.shape.outerRect, const Rect.fromLTRB(14.5, 7.75, 93, 54.25));
  });

  test('offsetY moves spread-adjusted geometry vertically', () {
    final result = AppleGlassShadowGeometry.resolve(
      geometry: geometry,
      shadow: shadow(6),
    );

    expect(
      result.shape,
      geometry.scaledShape.inflate(-4).shift(const Offset(0, -4)),
    );
    expect(result.shape.outerRect, const Rect.fromLTRB(19, 7, 91, 47));
  });

  test('negative spread remains valid when blur plus spread is negative', () {
    final sourceShadow = shadow(6);
    expect(sourceShadow.blurRadius + sourceShadow.spread, lessThan(0));

    final result = AppleGlassShadowGeometry.resolve(
      geometry: geometry,
      shadow: sourceShadow,
    );

    expect(result.shape.isFinite, isTrue);
    expect(result.shape.isEmpty, isFalse);
    expect(result.blurRadius, 0.5);
  });
}
