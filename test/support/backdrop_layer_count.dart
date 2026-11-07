import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts the backdrop captures in the composited layer tree of the last
/// frame: every [BackdropFilterLayer] with a null `backdropKey` counts on its
/// own, and each distinct non-null key counts once (a [BackdropGroup] shares
/// one capture). Unlike the renderer's debug counter, this sees layers that
/// were not repainted in the frame (a page under a popup).
int countCompositedBackdrops(WidgetTester tester) {
  final root = tester.binding.renderViews.first.debugLayer;
  if (root == null) return 0;
  var independent = 0;
  final keys = <Object>{};
  void walk(Layer layer) {
    // OpacitySeedLayer is a renderer-internal subclass that seeds opacity; it
    // does not capture the backdrop.
    if (layer is BackdropFilterLayer &&
        layer.runtimeType.toString() != 'OpacitySeedLayer') {
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
