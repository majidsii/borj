import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts the backdrop captures in the composited layer tree of the last
/// frame. Unlike the renderer's debug counter, this sees layers that were not
/// repainted in the frame (a page under a popup).
///
/// Every [BackdropFilterLayer] with a null `backdropKey` counts on its own,
/// and each distinct non-null key counts once (a [BackdropGroup] shares one
/// capture).
///
/// On a real device the renderer wraps glass filters in a
/// `SeededBackdropPassLayer`. When that pass is active and its only child is a
/// clip, the whole pass is ONE capture keyed by the seed key (the inner
/// filters read the pass, not the root), so its subtree is not walked. A
/// hidden pass paints nothing and counts nothing. Any other pass paints its
/// children normally. Seed keys and native backdrop keys share one dedup set.
/// Under `flutter test` the seed mode is `BackdropSeed.none`, so no pass is
/// active and the count is the plain one.
///
/// [captures] is the seed-aware count, [naive] counts every keyless filter
/// independently (it overcounts on device), and [activeSeededPasses] is how
/// many seeded passes were counted, so callers can tell a real-glass walk
/// from a vacuous one.
typedef BackdropCount = ({int captures, int naive, int activeSeededPasses});

bool _captures(BackdropFilterLayer layer) {
  if (layer.runtimeType.toString() != 'OpacitySeedLayer') return true;
  // OpacitySeedLayer (renderer-internal, marked @internal, so not importable
  // without an analyzer warning) is a BackdropFilterLayer that only captures
  // while `seeded`: a fractional opacity sits above the glass.
  // ignore: avoid_dynamic_calls
  return (layer as dynamic).seeded == true;
}

bool _isSeededPass(Layer layer) =>
    layer.runtimeType.toString() == 'SeededBackdropPassLayer';

/// Mirrors the seeded branch of `SeededBackdropPassLayer.addToScene` (after
/// the `hidden` check): whether the pass paints one seed capture, and its key
/// (null means independent).
({bool seeded, Object? key}) _seedCapture(ContainerLayer pass) {
  final dynamic p = pass;
  // ignore: avoid_dynamic_calls
  if (p.passRect == null) return (seeded: false, key: null);
  // ignore: avoid_dynamic_calls
  if (p.nativeSeed.toString() == 'BackdropSeed.none') {
    return (seeded: false, key: null);
  }
  final child = pass.firstChild;
  if (child == null || child.nextSibling != null) {
    return (seeded: false, key: null);
  }
  final clipped = switch (child) {
    ClipRectLayer(:final clipRect, :final clipBehavior) =>
      clipRect != null && clipBehavior != Clip.none,
    ClipPathLayer(:final clipPath, :final clipBehavior) =>
      clipPath != null && clipBehavior != Clip.none,
    _ => false,
  };
  // ignore: avoid_dynamic_calls
  return (seeded: clipped, key: clipped ? p.debugSeedKey as Object? : null);
}

BackdropCount countCompositedBackdropsDetailed(WidgetTester tester) {
  final root = tester.binding.renderViews.first.debugLayer;
  if (root == null) return (captures: 0, naive: 0, activeSeededPasses: 0);
  var independent = 0;
  var naiveIndependent = 0;
  var passes = 0;
  final keys = <Object>{};
  final naiveKeys = <Object>{};

  // The old algorithm: every keyless filter counts on its own.
  void walkNaive(Layer layer) {
    if (layer is BackdropFilterLayer && _captures(layer)) {
      final key = layer.backdropKey;
      if (key == null) {
        naiveIndependent++;
      } else {
        naiveKeys.add(key);
      }
    }
    if (layer is ContainerLayer) {
      Layer? child = layer.firstChild;
      while (child != null) {
        walkNaive(child);
        child = child.nextSibling;
      }
    }
  }

  // The seed-aware walk.
  void walkAware(Layer layer) {
    if (_isSeededPass(layer)) {
      // ignore: avoid_dynamic_calls
      if ((layer as dynamic).hidden == true) return;
      final capture = _seedCapture(layer as ContainerLayer);
      if (capture.seeded) {
        passes++;
        final key = capture.key;
        if (key == null) {
          independent++;
        } else {
          keys.add(key);
        }
        return;
      }
    } else if (layer is BackdropFilterLayer && _captures(layer)) {
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
        walkAware(child);
        child = child.nextSibling;
      }
    }
  }

  walkNaive(root);
  walkAware(root);
  return (
    captures: independent + keys.length,
    naive: naiveIndependent + naiveKeys.length,
    activeSeededPasses: passes,
  );
}

/// The seed-aware count of backdrop captures; see
/// [countCompositedBackdropsDetailed].
int countCompositedBackdrops(WidgetTester tester) =>
    countCompositedBackdropsDetailed(tester).captures;
