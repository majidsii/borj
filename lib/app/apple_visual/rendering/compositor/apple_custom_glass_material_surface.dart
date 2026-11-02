import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import '../geometry/apple_glass_applied_geometry.dart';
import '../geometry/apple_glass_applied_geometry_resolver.dart';
import '../material/apple_glass_blend_mode_semantics.dart';
import '../material/apple_glass_material_layer_resolver.dart';
import '../material/apple_glass_material_layers.dart';
import 'apple_custom_glass_filter.dart';
import 'apple_glass_shadow_runtime_pipeline.dart';

/// Hybrid Gate C surface for source-backed geometry and native fill layers.
///
/// This stage intentionally does not paint the source shadow stack yet.
/// Shadows containing Sketch Plus Darker remain on the custom-compositing
/// path established by the blend-semantics contract.
final class AppleCustomGlassMaterialSurface extends StatelessWidget {
  const AppleCustomGlassMaterialSurface({
    required this.recipe,
    required this.child,
    super.key,
  });

  final AppleLiquidGlassRecipe recipe;
  final Widget child;

  static const _geometryResolver = AppleGlassAppliedGeometryResolver();
  static const _materialResolver = AppleGlassMaterialLayerResolver();
  static const _blendModeResolver = AppleGlassBlendModeResolver();
  static const _shadowRuntimePipeline = AppleGlassShadowRuntimePipeline();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          // Geometry source evidence is defined in concrete bounds. Preserve
          // the previous filter path rather than inventing unbounded geometry.
          return AppleCustomGlassFilter(recipe: recipe, child: child);
        }

        final canvasSize = constraints.biggest;
        final geometry = _geometryResolver.resolve(
          recipe: recipe,
          canvasSize: canvasSize,
        );

        if (geometry == null) {
          // Roles whose applied usage geometry has not been source-backed yet
          // stay on the existing path. No guessed clip is introduced.
          return AppleCustomGlassFilter(recipe: recipe, child: child);
        }

        final material = _materialResolver.resolve(recipe);
        // Validates the recipe shadow stack; the result is not used here.
        _shadowRuntimePipeline.resolve(recipe: recipe);

        _assertNativeFillContract(material);

        final effectSize = Size(
          geometry.sourceFrameSize.width +
              geometry.exportInsets.left +
              geometry.exportInsets.right,
          geometry.sourceFrameSize.height +
              geometry.exportInsets.top +
              geometry.exportInsets.bottom,
        );

        return SizedBox(
          width: effectSize.width,
          height: effectSize.height,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Source shadow pass.
              CustomPaint(
                painter: _AppleGlassNativeZeroBlurShadowPainter(
                  geometry: geometry,
                  material: material,
                ),
                child: const SizedBox.expand(),
              ),

              // Backdrop effect MUST live outside the material clip.
              // The shader samples the surface behind the glass.
              Positioned.fill(
                child: AppleCustomGlassFilter(
                  recipe: recipe,
                  child: const SizedBox.expand(),
                ),
              ),

              // Material body.
              Positioned(
                left: geometry.exportInsets.left,
                top: geometry.exportInsets.top,
                width: geometry.sourceFrameSize.width,
                height: geometry.sourceFrameSize.height,
                child: ClipRSuperellipse(
                  clipper: _AppleGlassFixedSuperellipseClipper(
                    geometry.scaledShape,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: _AppleGlassNativeFillPainter(
                      geometry: geometry,
                      material: material,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // Foreground content.
              Positioned(
                left: geometry.exportInsets.left,
                top: geometry.exportInsets.top,
                width: geometry.sourceFrameSize.width,
                height: geometry.sourceFrameSize.height,
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }

  static void _assertNativeFillContract(
    AppleGlassSourceMaterialLayers material,
  ) {
    for (final fill in material.fills) {
      if (!fill.isEnabled) {
        continue;
      }

      if (fill.fillType != 0) {
        throw StateError(
          'Gate C native fill stage only supports source color fills; '
          'fill[${fill.index}] has fillType=${fill.fillType}.',
        );
      }

      final resolution = _blendModeResolver.resolve(fill.blendMode);

      if (resolution.requiresCustomCompositing ||
          resolution.nativeFlutterMode == null) {
        throw StateError(
          'Gate C fill[${fill.index}] requires custom blend compositing '
          'for source mode ${fill.blendMode}.',
        );
      }
    }
  }
}

final class _AppleGlassFixedSuperellipseClipper
    extends CustomClipper<ui.RSuperellipse> {
  const _AppleGlassFixedSuperellipseClipper(this.shape);

  final ui.RSuperellipse shape;

  @override
  ui.RSuperellipse getClip(ui.Size size) => shape;

  @override
  bool shouldReclip(covariant _AppleGlassFixedSuperellipseClipper oldClipper) {
    return oldClipper.shape != shape;
  }
}

final class _AppleGlassNativeZeroBlurShadowPainter extends CustomPainter {
  const _AppleGlassNativeZeroBlurShadowPainter({
    required this.geometry,
    required this.material,
  });

  final AppleGlassAppliedGeometry geometry;
  final AppleGlassSourceMaterialLayers material;

  static const _blendModeResolver = AppleGlassBlendModeResolver();

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    for (final shadow in material.shadows) {
      if (!shadow.isEnabled || shadow.blurRadius != 0 || shadow.spread != 0) {
        continue;
      }

      final blend = _blendModeResolver.resolve(shadow.blendMode);
      final nativeMode = blend.nativeFlutterMode;

      if (nativeMode == null || blend.requiresCustomCompositing) {
        continue;
      }

      final effectiveAlpha = (shadow.colorAlpha * shadow.contextOpacity).clamp(
        0.0,
        1.0,
      );

      final paint = ui.Paint()
        ..isAntiAlias = true
        ..color = ui.Color.from(
          alpha: effectiveAlpha,
          red: shadow.colorRed,
          green: shadow.colorGreen,
          blue: shadow.colorBlue,
        )
        ..blendMode = nativeMode;

      canvas.save();
      canvas.translate(shadow.offsetX, shadow.offsetY);
      canvas.drawRSuperellipse(geometry.scaledShape, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(
    covariant _AppleGlassNativeZeroBlurShadowPainter oldDelegate,
  ) {
    return oldDelegate.geometry.materialRect != geometry.materialRect ||
        oldDelegate.geometry.scaledShape != geometry.scaledShape ||
        !identical(oldDelegate.material, material);
  }
}

final class _AppleGlassNativeFillPainter extends CustomPainter {
  const _AppleGlassNativeFillPainter({
    required this.geometry,
    required this.material,
  });

  final AppleGlassAppliedGeometry geometry;
  final AppleGlassSourceMaterialLayers material;

  static const _blendModeResolver = AppleGlassBlendModeResolver();

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // Preserve the serialized source fill order exactly. Gate C does not
    // reorder source layers or collapse them into a guessed single tint.
    for (final fill in material.fills) {
      if (!fill.isEnabled) {
        continue;
      }

      final blend = _blendModeResolver.resolve(fill.blendMode);
      final nativeMode = blend.nativeFlutterMode;

      if (nativeMode == null || blend.requiresCustomCompositing) {
        throw StateError(
          'Source fill[${fill.index}] cannot use native Flutter blending.',
        );
      }

      final effectiveAlpha = (fill.colorAlpha * fill.contextOpacity).clamp(
        0.0,
        1.0,
      );

      final paint = ui.Paint()
        ..isAntiAlias = true
        ..color = ui.Color.from(
          alpha: effectiveAlpha,
          red: fill.colorRed,
          green: fill.colorGreen,
          blue: fill.colorBlue,
        )
        ..blendMode = nativeMode;

      canvas.drawRSuperellipse(geometry.scaledShape, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppleGlassNativeFillPainter oldDelegate) {
    return oldDelegate.geometry.materialRect != geometry.materialRect ||
        oldDelegate.geometry.scaledShape != geometry.scaledShape ||
        !identical(oldDelegate.material, material);
  }
}
