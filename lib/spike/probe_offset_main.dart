import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

const _variant = String.fromEnvironment('V', defaultValue: 'plain');
final _key = GlobalKey();
final _rootKey = GlobalKey();

class _P extends CustomPainter {
  const _P();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFFFFFFF));
    final b = Paint()..color = const Color(0xFF000000);
    for (var x = 0.0; x < s.width; x += 16) {
      c.drawRect(Rect.fromLTWH(x, 0, 8, s.height), b);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlass.precache();
  final g = _variant.startsWith('geom');
  final left = _variant == 'geom0' ? 0.0 : 296.0;
  final scene = SizedBox(width: g ? 900 : 320, height: g ? 136 : 176, child: RepaintBoundary(key: _key, child: Stack(children: [
    const Positioned.fill(child: CustomPaint(painter: _P())),
    Positioned(left: 40, top: g ? 20 : 40, width: 240, height: 96, child: const LiquidGlassLayer(
      settings: LiquidGlassSettings(refractionAmount: 60, refractionHeight: 20, frost: 0, highlight: 0, contourStrength: 0, bevelShadowStrength: 0),
      child: LiquidGlass(shape: LiquidRoundedSuperellipse(borderRadius: 40), child: SizedBox.expand()))),
  ])));
  Widget app;
  if (_variant == 'material') {
    app = MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: Align(alignment: Alignment.topLeft, child: scene)));
  } else {
    if (g) { app = MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: Stack(children: [Positioned(left: left, right: 24, top: 0, height: 136, child: scene)]))); } else { app = Directionality(textDirection: TextDirection.ltr, child: Align(alignment: Alignment.topLeft, child: scene)); }
  }
  app = RepaintBoundary(key: _rootKey, child: app);
  runApp(app);
  Timer(const Duration(seconds: 3), () async {
    final bd = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await bd.toImage(pixelRatio: 1);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final w = img.width;
    final lum = <int>[];
    for (var x = 41; x < 71; x++) {
      final o = ((g ? 68 : 88) * w + x) * 4;
      lum.add((bytes.getUint8(o) * 299 + bytes.getUint8(o + 1) * 587 + bytes.getUint8(o + 2) * 114) ~/ 1000);
    }
    final lo = lum.reduce((a, b) => a < b ? a : b), hi = lum.reduce((a, b) => a > b ? a : b);
    final t = (lo + hi) / 2;
    final e = <int>[];
    for (var i = 1; i < lum.length; i++) { if ((lum[i] >= t) != (lum[i - 1] >= t)) e.add(41 + i); }
    // ignore: avoid_print
    print('PROBE_ONLY variant=$_variant edges=$e');
    final rb = _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bdBox = bd.localToGlobal(Offset.zero);
    final img2 = await rb.toImage(pixelRatio: 1);
    final b2 = (await img2.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final w2 = img2.width;
    final l2 = <int>[];
    final ox = bdBox.dx.round(), oy = bdBox.dy.round();
    for (var x = 41; x < 71; x++) {
      final o = ((oy + (g ? 68 : 88)) * w2 + ox + x) * 4;
      l2.add((b2.getUint8(o) * 299 + b2.getUint8(o + 1) * 587 + b2.getUint8(o + 2) * 114) ~/ 1000);
    }
    final lo2 = l2.reduce((a, b) => a < b ? a : b), hi2 = l2.reduce((a, b) => a > b ? a : b);
    final t2 = (lo2 + hi2) / 2;
    final e2 = <int>[];
    for (var i = 1; i < l2.length; i++) { if ((l2[i] >= t2) != (l2[i - 1] >= t2)) e2.add(41 + i); }
    // ignore: avoid_print
    print('PROBE_ONLY ancestor origin=($ox,$oy) edges=$e2');
  });
}
