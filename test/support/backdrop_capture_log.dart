import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Reads the debug capture counter of liquid_glass_renderer 1.0.0-dev.2.
abstract final class BackdropCaptureLog {
  static final RegExp _message = RegExp(
    r'liquid_glass_renderer: (\d+) independent backdrop captures in this frame',
  );

  /// Runs [body] and returns the largest capture count printed meanwhile, or 1
  /// if nothing was printed (the renderer only prints counts above 1).
  static Future<int> record(Future<void> Function() body) async {
    final previous = debugPrint;
    var largest = 1;
    debugPrint = (String? message, {int? wrapWidth}) {
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
    return largest;
  }
}
