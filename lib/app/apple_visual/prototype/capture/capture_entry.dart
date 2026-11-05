// SPIKE: real-glass screenshot capture harness.
import 'package:flutter/widgets.dart';

import '../all_glass_wallpaper.dart';

/// One screen the capture harness can render to `<name>.png`.
class CaptureEntry {
  const CaptureEntry(
    this.name,
    this.builder, {
    this.size = CaptureEntry.phone,
    this.dark = true,
  });

  /// iPhone-like logical size.
  static const Size phone = Size(390, 844);

  /// Desktop logical size.
  static const Size mac = Size(1440, 900);

  /// File name without extension; also the CAPTURE_ONLY key.
  final String name;
  final WidgetBuilder builder;
  final Size size;
  final bool dark;
}

/// Wraps a screen on the all-glass wallpaper, as the gallery does.
Widget captureOnWallpaper(Widget screen) => Stack(
  children: <Widget>[
    const Positioned.fill(child: AllGlassWallpaper()),
    Positioned.fill(child: screen),
  ],
);
