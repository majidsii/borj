// SPIKE: renders registry screens with the REAL liquid_glass_renderer and
// saves PNGs. Run via tool/capture_glass.sh.
//
// The capture boundary must sit at the window origin (0,0): nested offset
// boundaries miss the real glass in RepaintBoundary.toImage.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../all_glass_kit.dart';
import 'capture_entry.dart';

const String _captureDir = String.fromEnvironment('CAPTURE_DIR');
const String _captureOnly = String.fromEnvironment('CAPTURE_ONLY');
// Must equal the window's real devicePixelRatio: the glass shader layer is
// drawn in physical pixels and does not rescale with toImage(pixelRatio).
const int _settleFrames = 20;
const Duration _settleDelay = Duration(milliseconds: 1200);

class GlassCaptureApp extends StatefulWidget {
  const GlassCaptureApp({required this.entries, super.key});

  final List<CaptureEntry> entries;

  @override
  State<GlassCaptureApp> createState() => _GlassCaptureAppState();
}

class _GlassCaptureAppState extends State<GlassCaptureApp> {
  final GlobalKey _boundaryKey = GlobalKey();
  late final List<CaptureEntry> _queue;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final only = _captureOnly
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    _queue = <CaptureEntry>[
      for (final e in widget.entries)
        if (only.isEmpty || only.contains(e.name)) e,
    ];
    if (_captureDir.isEmpty) {
      stderr.writeln('CAPTURE_DIR is not set; nothing to do.');
      exit(2);
    }
    unawaited(_run());
  }

  Future<void> _frames(int n) async {
    for (var i = 0; i < n; i++) {
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Future<void> _run() async {
    final dpr = View.of(context).devicePixelRatio;
    Directory(_captureDir).createSync(recursive: true);
    await LiquidGlass.precache();
    var failed = 0;
    for (var i = 0; i < _queue.length; i++) {
      final entry = _queue[i];
      setState(() => _index = i);
      await _frames(_settleFrames);
      await Future<void>.delayed(_settleDelay);
      await _frames(_settleFrames);
      try {
        final boundary =
            _boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        if (boundary.localToGlobal(Offset.zero) != Offset.zero) {
          throw StateError('capture boundary is not at the window origin');
        }
        final image = await boundary.toImage(pixelRatio: dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final path = '$_captureDir/${entry.name}.png';
        File(path).writeAsBytesSync(data!.buffer.asUint8List());
        stdout.writeln('CAPTURED ${entry.name} -> $path');
      } on Object catch (e) {
        failed++;
        stderr.writeln('FAILED ${entry.name}: $e');
      }
    }
    stdout.writeln('CAPTURE DONE ${_queue.length - failed}/${_queue.length}');
    await stdout.flush();
    exit(failed == 0 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const SizedBox.shrink();
    }
    final entry = _queue[_index];
    final brightness = entry.dark ? Brightness.dark : Brightness.light;
    final mq = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFF05060F),
        // OverflowBox lets the screen keep its logical size even when the
        // window is smaller; the boundary stays anchored at (0,0).
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: entry.size.width,
          maxWidth: entry.size.width,
          minHeight: entry.size.height,
          maxHeight: entry.size.height,
          child: RepaintBoundary(
            key: _boundaryKey,
            child: MediaQuery(
              data: mq.copyWith(
                size: entry.size,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                platformBrightness: brightness,
              ),
              child: Theme(
                data: ThemeData(brightness: brightness),
                child: DefaultTextStyle(
                  style: glassText(14),
                  child: KeyedSubtree(
                    key: ValueKey<String>(entry.name),
                    child: Builder(builder: entry.builder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
