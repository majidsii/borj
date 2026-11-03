import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'error_report.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installSpikeErrorHooks();
  try {
    // ignore: experimental_member_use
    LgrLogs.initAllLogs();
    await LiquidGlass.precache();
  } on Object catch (e, st) {
    recordSpikeError('precache', e, st);
  }
  runApp(const _SpikeApp());
}

final class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final black = Paint()..color = const Color(0xFF000000);
    for (var x = 0.0; x < size.width; x += 16) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 8, size.height), black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _SpikeApp extends StatelessWidget {
  const _SpikeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: spikeErrorOverlay,
      home: _SpikeScreen(),
    );
  }
}

final class _SpikeScreen extends StatefulWidget {
  const _SpikeScreen();

  @override
  State<_SpikeScreen> createState() => _SpikeScreenState();
}

final class _SpikeScreenState extends State<_SpikeScreen> {
  final _scroll = ScrollController();
  final _build = <int>[];
  final _raster = <int>[];
  final _rootKey = GlobalKey();
  final _status = ValueNotifier<List<String>>(['GLASS: probing...']);
  String _glassLine = 'GLASS: probing...';
  String _framesLine = '';
  double _bandLeft = 296;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll();
      Timer(const Duration(seconds: 3), _probe);
    });
    Timer(const Duration(seconds: 20), _report);
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    for (final t in timings) {
      _build.add(t.buildDuration.inMicroseconds);
      _raster.add(t.rasterDuration.inMicroseconds);
    }
  }

  Future<void> _autoScroll() async {
    while (mounted && !_reported) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(seconds: 4),
        curve: Curves.linear,
      );
      await _scroll.animateTo(
        0,
        duration: const Duration(seconds: 4),
        curve: Curves.linear,
      );
    }
  }

  Future<void> _probe() async {
    // Capture the ancestor boundary that wraps the whole screen at origin
    // (0,0); a nested boundary at a non-zero offset misses the refraction.
    // pixelRatio 1 => image pixels == logical px (stripes stay 8 logical px).
    final boundary =
        _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final width = image.width;
    image.dispose();
    const y = 68; // pill vertical center: 20 + 96 / 2
    final left = _bandLeft.round();
    final x0 = left + 41; // 1 px inside the pill's left edge (band x = 40)
    final luminance = <int>[];
    for (var x = x0; x < x0 + 30; x++) {
      final o = (y * width + x) * 4;
      luminance.add(
        (bytes.getUint8(o) * 299 +
                bytes.getUint8(o + 1) * 587 +
                bytes.getUint8(o + 2) * 114) ~/
            1000,
      );
    }
    final lo = luminance.reduce((a, b) => a < b ? a : b);
    final hi = luminance.reduce((a, b) => a > b ? a : b);
    final threshold = (lo + hi) / 2;
    final edges = <int>[];
    for (var i = 1; i < luminance.length; i++) {
      if ((luminance[i] >= threshold) != (luminance[i - 1] >= threshold)) {
        edges.add(x0 + i - left); // stripe-band coordinates
      }
    }
    final offGrid = edges.map((x) {
      final r = x % 8;
      return r < 8 - r ? r : 8 - r;
    }).toList();
    final full = offGrid.any((o) => o >= 3);
    _glassLine = 'GLASS: ${full ? 'FULL' : 'FALLBACK'} edges=$edges';
    _publish();
    // ignore: avoid_print
    print('SPIKE_RELEASE_PROBE edges=$edges offgrid=$offGrid');
  }

  static String _p(List<int> values, int percentile) {
    final sorted = [...values]..sort();
    final i = ((percentile / 100) * (sorted.length - 1)).round();
    return (sorted[i] / 1000).toStringAsFixed(2);
  }

  void _report() {
    _reported = true;
    final line =
        'SPIKE_FRAMES n=${_raster.length} '
        'build_p50_ms=${_p(_build, 50)} build_p90_ms=${_p(_build, 90)} '
        'raster_p50_ms=${_p(_raster, 50)} raster_p90_ms=${_p(_raster, 90)}';
    _framesLine =
        'n=${_raster.length}\n'
        'build p50 ${_p(_build, 50)} p90 ${_p(_build, 90)} ms\n'
        'raster p50 ${_p(_raster, 50)} p90 ${_p(_raster, 90)} ms';
    _publish();
    // ignore: avoid_print
    print(line);
  }

  void _publish() =>
      _status.value = [_glassLine, if (_framesLine.isNotEmpty) _framesLine];

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _scroll.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final settings = LiquidGlassSettings.ios27Regular(brightness: brightness);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final contentLeft = narrow ? 16.0 : 296.0;
    _bandLeft = contentLeft;
    return RepaintBoundary(
      key: _rootKey,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(contentLeft, 152, 24, 120),
                itemCount: 60,
                itemBuilder: (context, i) => Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        HSLColor.fromAHSL(
                          1,
                          (i * 37) % 360,
                          0.7,
                          0.55,
                        ).toColor(),
                        HSLColor.fromAHSL(
                          1,
                          (i * 37 + 90) % 360,
                          0.7,
                          0.45,
                        ).toColor(),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'کارت محتوا $i',
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            // Probe strip: 8 px stripes under a glass pill (Q1 release check).
            Positioned(
              left: contentLeft,
              right: 24,
              top: 0,
              height: 136,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _StripePainter()),
                  ),
                  Positioned(
                    left: 40,
                    top: 20,
                    width: 240,
                    height: 96,
                    child: const LiquidGlassLayer(
                      settings: LiquidGlassSettings(
                        frost: 0,
                        highlight: 0,
                        contourStrength: 0,
                        bevelShadowStrength: 0,
                      ),
                      child: LiquidGlass(
                        shape: LiquidRoundedSuperellipse(borderRadius: 40),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sidebar: one layer, one shape.
            if (!narrow)
              Positioned(
                left: 16,
                top: 16,
                bottom: 16,
                width: 256,
                child: LiquidGlassLayer(
                  settings: settings,
                  child: const LiquidGlass(
                    shape: LiquidRoundedSuperellipse(borderRadius: 28),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            // Bottom control bar: one layer, six blended controls.
            Positioned(
              left: contentLeft,
              right: narrow ? 16 : 24,
              bottom: 24,
              height: 64,
              child: LiquidGlassLayer(
                settings: settings,
                child: LiquidGlassBlendGroup(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < (narrow ? 4 : 6); i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        const LiquidGlass.grouped(
                          shape: LiquidRoundedSuperellipse(borderRadius: 28),
                          child: SizedBox(width: 56, height: 56),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Solid (non-glass) verdict overlay, above the bottom bar.
            Positioned(
              left: 16,
              bottom: 96,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _status,
                builder: (context, lines, _) => Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF000000),
                  child: Text(
                    lines.join('\n'),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      color: Color(0xFFFFFF00),
                      fontFamily: 'monospace',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
