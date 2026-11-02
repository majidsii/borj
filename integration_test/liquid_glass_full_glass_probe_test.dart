import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

const _halfPeriod = 8;
const _canvas = Size(320, 176);
const _glass = Rect.fromLTWH(40, 40, 240, 96);
const _bevelScan = 30;
const _offGridThreshold = 3;

final class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final black = Paint()..color = const Color(0xFF000000);
    for (var x = 0; x < size.width; x += _halfPeriod * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), 0, _halfPeriod.toDouble(), size.height),
        black,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _scene(GlobalKey boundaryKey, LiquidGlassSettings settings) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox.fromSize(
          size: _canvas,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _StripePainter())),
              Positioned.fromRect(
                rect: _glass,
                child: LiquidGlassLayer(
                  settings: settings,
                  child: const LiquidGlass(
                    shape: LiquidRoundedSuperellipse(borderRadius: 40),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Canvas x positions of black/white edges along the glass's vertical
/// center, scanning [_bevelScan] px inward from its left edge.
Future<List<int>> _bevelEdges(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final width = image.width;
  image.dispose();

  final y = _glass.center.dy.round();
  final x0 = _glass.left.round() + 1;
  final luminance = <int>[];
  for (var x = x0; x < x0 + _bevelScan; x++) {
    final o = (y * width + x) * 4;
    luminance.add(
      (bytes.getUint8(o) * 299 + bytes.getUint8(o + 1) * 587 + bytes.getUint8(o + 2) * 114) ~/ 1000,
    );
  }
  final lo = luminance.reduce((a, b) => a < b ? a : b);
  final hi = luminance.reduce((a, b) => a > b ? a : b);
  final threshold = (lo + hi) / 2;

  final edges = <int>[];
  for (var i = 1; i < luminance.length; i++) {
    if ((luminance[i] >= threshold) != (luminance[i - 1] >= threshold)) {
      edges.add(x0 + i);
    }
  }
  return edges;
}

int _offGrid(int x) {
  final r = x % _halfPeriod;
  return r < _halfPeriod - r ? r : _halfPeriod - r;
}

Future<List<int>> _render(WidgetTester tester, LiquidGlassSettings settings) async {
  final key = GlobalKey();
  await tester.pumpWidget(_scene(key, settings));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return _bevelEdges(key);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(LiquidGlass.precache);

  testWidgets('negative control keeps stripes on grid', (tester) async {
    final edges = await _render(
      tester,
      const LiquidGlassSettings(
        refractionAmount: 0,
        frost: 0,
        highlight: 0,
        contourStrength: 0,
        bevelShadowStrength: 0,
      ),
    );
    // ignore: avoid_print
    print('LG_PROBE negative edges=$edges');
    expect(edges, isNotEmpty, reason: 'stripes washed out; probe is invalid');
    expect(edges.map(_offGrid), everyElement(lessThan(_offGridThreshold)));
  });

  testWidgets('full glass displaces stripes in the bevel', (tester) async {
    final edges = await _render(
      tester,
      const LiquidGlassSettings(
        refractionAmount: 60,
        refractionHeight: 20,
        frost: 0,
        highlight: 0,
        contourStrength: 0,
        bevelShadowStrength: 0,
      ),
    );
    // ignore: avoid_print
    print('LG_PROBE full edges=$edges');
    expect(edges, isNotEmpty, reason: 'stripes washed out; probe is invalid');
    expect(
      edges.map(_offGrid).any((d) => d >= _offGridThreshold),
      isTrue,
      reason: 'no displaced stripe edge: full glass is not active (FakeGlass fallback?)',
    );
  });
}
