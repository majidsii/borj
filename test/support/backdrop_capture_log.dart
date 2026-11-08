import 'dart:math' as math;

import 'package:flutter/foundation.dart';

final class CaptureRecord {
  const CaptureRecord({
    required this.maxCaptures,
    required this.shapeLimitExceeded,
    this.bareFadeWarned = false,
  });

  final int maxCaptures;

  /// The renderer printed "a LiquidGlassLayer has more than 16 glass shapes".
  final bool shapeLimitExceeded;

  /// The renderer printed "an Opacity or FadeTransition between a LiquidGlass
  /// and its LiquidGlassLayer only fades the glass's children". It prints that
  /// once per isolate, so assert it in a dedicated (first) test of a file.
  final bool bareFadeWarned;
}

/// Reads the debug capture counter of liquid_glass_renderer 1.0.0-dev.2.
abstract final class BackdropCaptureLog {
  static final RegExp _message = RegExp(
    r'liquid_glass_renderer: (\d+) independent backdrop captures in this frame',
  );

  static final RegExp _shapeLimit = RegExp(
    r'liquid_glass_renderer: a LiquidGlassLayer has more than \d+ glass shapes',
  );

  static final RegExp _bareFade = RegExp(r"only fades the glass's children");

  /// Runs [body] and returns the largest capture count printed meanwhile (1 if
  /// nothing was printed; the renderer only prints counts above 1) and whether
  /// the shape-limit warning appeared.
  static Future<CaptureRecord> record(Future<void> Function() body) async {
    final previous = debugPrint;
    var largest = 1;
    var shapeLimitExceeded = false;
    var bareFadeWarned = false;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && _shapeLimit.hasMatch(message)) {
        shapeLimitExceeded = true;
      }
      if (message != null && _bareFade.hasMatch(message)) {
        bareFadeWarned = true;
      }
      final match = message == null ? null : _message.firstMatch(message);
      if (match != null) {
        largest = math.max(largest, int.parse(match.group(1)!));
      }
      previous(message, wrapWidth: wrapWidth);
    };
    try {
      await body();
    } finally {
      debugPrint = previous;
    }
    return CaptureRecord(
      maxCaptures: largest,
      shapeLimitExceeded: shapeLimitExceeded,
      bareFadeWarned: bareFadeWarned,
    );
  }
}
