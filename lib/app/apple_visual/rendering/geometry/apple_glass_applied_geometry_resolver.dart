import 'dart:ui';

import 'package:flutter/widgets.dart' show EdgeInsets;

import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_applied_geometry.dart';

final class AppleGlassAppliedGeometryResolver {
  const AppleGlassAppliedGeometryResolver();

  static const double _epsilon = 1e-6;

  AppleGlassAppliedGeometry? resolve({
    required AppleLiquidGlassRecipe recipe,
    required Size canvasSize,
  }) {
    final values = recipe.sourceValues;

    final sourceWidth = _optionalDouble(values, 'usage.frame.width');
    final sourceHeight = _optionalDouble(values, 'usage.frame.height');
    final sourceRadius = _optionalDouble(values, 'usage.corners.radii[0]');

    if (sourceWidth == null || sourceHeight == null || sourceRadius == null) {
      return null;
    }

    final smoothing = _requiredDouble(values, 'usage.corners.smoothing');
    final cornerStyle = _requiredInt(values, 'usage.corners.style');

    // This contract is deliberately narrow. We have direct source evidence
    // for the first locked smooth-corner tuple only.
    if (!_close(smoothing, 0.6) || cornerStyle != 1) {
      throw StateError(
        'Unsupported Apple usage corner semantics: '
        'smoothing=$smoothing style=$cornerStyle',
      );
    }

    final shadowEnabled = _requiredBool(values, 'style.shadows[0].isEnabled');
    final shadowBlendMode = _requiredInt(
      values,
      'style.shadows[0].contextSettings.blendMode',
    );
    final blurRadius = _requiredDouble(values, 'style.shadows[0].blurRadius');
    final offsetX = _requiredDouble(values, 'style.shadows[0].offsetX');
    final offsetY = _requiredDouble(values, 'style.shadows[0].offsetY');
    final spread = _requiredDouble(values, 'style.shadows[0].spread');

    if (!shadowEnabled || shadowBlendMode != 0) {
      throw StateError(
        'Applied export geometry requires the source-backed enabled '
        'normal outer shadow at style.shadows[0].',
      );
    }

    final effectRadius = blurRadius + spread;

    if (effectRadius < 0) {
      throw StateError(
        'Negative source effect radius is not supported: $effectRadius',
      );
    }

    final left = effectRadius - offsetX;
    final right = effectRadius + offsetX;
    final top = effectRadius - offsetY;
    final bottom = effectRadius + offsetY;

    if (left < 0 || right < 0 || top < 0 || bottom < 0) {
      throw StateError(
        'Source shadow would produce negative export insets: '
        'left=$left top=$top right=$right bottom=$bottom',
      );
    }

    final exportInsets = EdgeInsets.fromLTRB(left, top, right, bottom);

    final expectedExportSize = Size(
      sourceWidth + left + right,
      sourceHeight + top + bottom,
    );

    final Rect materialRect;

    if (_sameSize(canvasSize, expectedExportSize)) {
      materialRect = Rect.fromLTWH(left, top, sourceWidth, sourceHeight);
    } else if (_sameSize(canvasSize, Size(sourceWidth, sourceHeight))) {
      // Runtime callers may provide the concrete material frame directly.
      materialRect = Rect.fromLTWH(0, 0, sourceWidth, sourceHeight);
    } else {
      throw StateError(
        'Apple source geometry cannot be silently fitted to canvas '
        '$canvasSize. Expected concrete source frame '
        '${Size(sourceWidth, sourceHeight)} or source export/effect frame '
        '$expectedExportSize.',
      );
    }

    final rawShape = RSuperellipse.fromRectAndRadius(
      materialRect,
      Radius.circular(sourceRadius),
    );

    final scaledShape = rawShape.scaleRadii();

    if (!scaledShape.isFinite || scaledShape.hasNaN) {
      throw StateError(
        'Apple source radius produced invalid RSuperellipse geometry.',
      );
    }

    return AppleGlassAppliedGeometry(
      sourceFrameSize: Size(sourceWidth, sourceHeight),
      exportInsets: exportInsets,
      materialRect: materialRect,
      sourceRadius: sourceRadius,
      scaledShape: scaledShape,
    );
  }

  bool _sameSize(Size a, Size b) {
    return _close(a.width, b.width) && _close(a.height, b.height);
  }

  bool _close(double a, double b) => (a - b).abs() <= _epsilon;

  double? _optionalDouble(Map<String, Object?> values, String key) {
    final value = values[key];

    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }

    throw StateError('Invalid source number: $key');
  }

  double _requiredDouble(Map<String, Object?> values, String key) {
    final value = values[key];

    if (value is num) {
      return value.toDouble();
    }

    throw StateError('Missing or invalid source number: $key');
  }

  int _requiredInt(Map<String, Object?> values, String key) {
    final value = values[key];

    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    throw StateError('Missing or invalid source integer: $key');
  }

  bool _requiredBool(Map<String, Object?> values, String key) {
    final value = values[key];

    if (value is bool) {
      return value;
    }

    throw StateError('Missing or invalid source bool: $key');
  }
}
