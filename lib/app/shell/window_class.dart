import 'package:flutter/widgets.dart';

/// Window classes of redesign spec §5: compact < 600, medium 600–1023,
/// expanded ≥ 1024 logical px of window width.
enum WindowClass {
  compact,
  medium,
  expanded;

  static WindowClass forWidth(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 1024) return WindowClass.medium;
    return WindowClass.expanded;
  }

  static WindowClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}
