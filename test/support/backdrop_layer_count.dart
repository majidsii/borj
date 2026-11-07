import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts the backdrop captures in the composited layer tree of the last
/// frame: every [BackdropFilterLayer] with a null `backdropKey` counts on its
/// own, and each distinct non-null key counts once (a [BackdropGroup] shares
/// one capture). Unlike the renderer's debug counter, this sees layers that
/// were not repainted in the frame (a page under a popup).
bool _captures(BackdropFilterLayer layer) {
  if (layer.runtimeType.toString() != 'OpacitySeedLayer') return true;
  // ignore: avoid_dynamic_calls
  return (layer as dynamic).seeded == true;
}

int countCompositedBackdrops(WidgetTester tester) {
  final root = tester.binding.renderViews.first.debugLayer;
  if (root == null) return 0;
  var independent = 0;
  final keys = <Object>{};
  void walk(Layer layer) {
    // OpacitySeedLayer (renderer-internal, marked @internal, so not
    // importable without an analyzer warning) is a BackdropFilterLayer that
    // only captures while `seeded`: a fractional opacity sits above the glass.
    // Read `seeded` dynamically for that reason.
    if (layer is BackdropFilterLayer && _captures(layer)) {
      final key = layer.backdropKey;
      if (key == null) {
        independent++;
      } else {
        keys.add(key);
      }
    }
    if (layer is ContainerLayer) {
      Layer? child = layer.firstChild;
      while (child != null) {
        walk(child);
        child = child.nextSibling;
      }
    }
  }

  walk(root);
  return independent + keys.length;
}
