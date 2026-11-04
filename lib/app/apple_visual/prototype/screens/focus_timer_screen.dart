// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../all_glass_kit.dart';
import 'glass_liquid_follower.dart';

enum _Phase { idle, running, paused }

class _Session {
  const _Session(this.time, this.minutes, this.completed);

  final String time;
  final int minutes;
  final bool completed;
}

const List<int> _presets = <int>[15, 25, 50];

/// Focus timer with liquid controls.
///
/// Layers: the disc, the control pair (two circles in one blend group that
/// split and merge), the preset capsule, the sliding selection pill (own layer
/// and backdrop) and the session rows.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  static final SpringDescription _splitSpring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 15,
  );

  int _preset = 1;
  int _elapsed = 0;
  _Phase _phase = _Phase.idle;
  Timer? _timer;
  final List<_Session> _sessions = <_Session>[
    const _Session('۰۹:۱۵', 25, true),
    const _Session('۱۱:۴۰', 50, true),
    const _Session('۱۳:۱۰', 15, false),
  ];
  late final AnimationController _split = AnimationController.unbounded(
    vsync: this,
  );

  int get _total => _presets[_preset] * 60;

  @override
  void dispose() {
    _timer?.cancel();
    _split.dispose();
    super.dispose();
  }

  void _animateSplit(bool apart) {
    final target = apart ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _split.value = target;
      return;
    }
    unawaited(
      _split.animateWith(
        SpringSimulation(_splitSpring, _split.value, target, _split.velocity),
      ),
    );
  }

  void _onPrimary() {
    if (_phase == _Phase.running) {
      _timer?.cancel();
      setState(() => _phase = _Phase.paused);
      _animateSplit(false);
      return;
    }
    setState(() => _phase = _Phase.running);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsed + 1 >= _total) {
        setState(() => _elapsed = _total);
        _finish();
      } else {
        setState(() => _elapsed++);
      }
    });
    _animateSplit(true);
  }

  void _finish() {
    _timer?.cancel();
    if (_elapsed >= 1) {
      _sessions.insert(
        0,
        _Session(
          '۱۴:۳۰',
          math.max(1, (_elapsed / 60).round()),
          _elapsed >= _total,
        ),
      );
    }
    setState(() {
      _elapsed = 0;
      _phase = _Phase.idle;
    });
    _animateSplit(false);
  }

  void _selectPreset(int i) {
    if (_phase == _Phase.running) {
      return;
    }
    setState(() {
      _preset = i;
      _elapsed = 0;
      _phase = _Phase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _total - _elapsed;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    return BackdropGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 54, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('تمرکز', style: glassText(36, weight: FontWeight.w800)),
            Text('طراحی صفحهٔ اصلی', style: glassText(16, opacity: 0.85)),
            const SizedBox(height: 14),
            Center(child: _buildDisc(fa('$mm:$ss'))),
            const SizedBox(height: 14),
            _buildControls(),
            const SizedBox(height: 10),
            Center(child: _buildPresets()),
            const SizedBox(height: 16),
            Text(
              'جلسه‌های امروز',
              style: glassText(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisc(String digits) {
    final status = switch (_phase) {
      _Phase.idle => 'آمادهٔ شروع',
      _Phase.running => 'در حال تمرکز',
      _Phase.paused => 'متوقف',
    };
    return GlassSection(
      child: SizedBox(
        width: 220,
        height: 220,
        child: GlassPiece(
          circle: true,
          child: CustomPaint(
            painter: _ArcPainter(_elapsed / _total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    digits,
                    key: const ValueKey<String>('timer-digits'),
                    style: glassText(56, weight: FontWeight.w700).copyWith(
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  Text(status, style: glassText(13, opacity: 0.8)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final primary = switch (_phase) {
      _Phase.idle => 'شروع',
      _Phase.running => 'توقف',
      _Phase.paused => 'ادامه',
    };
    return GlassSection(
      blend: 18,
      child: SizedBox(
        height: 88,
        child: LayoutBuilder(
          builder: (context, box) {
            final cx = box.maxWidth / 2;
            return AnimatedBuilder(
              animation: _split,
              builder: (context, _) {
                final t = math.max(0.0, _split.value);
                final dx = t * 62;
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: cx + dx - 40,
                      top: 4,
                      width: 80,
                      height: 80,
                      child: _controlCircle(
                        key: const ValueKey<String>('primary-button'),
                        label: primary,
                        onTap: _onPrimary,
                      ),
                    ),
                    if (t > 0.02)
                      Positioned(
                        left: cx - dx - 40,
                        top: 4,
                        width: 80,
                        height: 80,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: _controlCircle(
                            key: const ValueKey<String>('finish-button'),
                            label: 'پایان',
                            onTap: _finish,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _controlCircle({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassPiece(
        circle: true,
        child: Center(
          child: Text(label, style: glassText(17, weight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildPresets() {
    const width = 330.0;
    const pad = 5.0;
    const cw = (width - 2 * pad) / 3;
    return SizedBox(
      width: width,
      height: 52,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GlassSection(
              child: GlassPiece(
                radius: 26,
                padding: const EdgeInsets.all(pad),
                child: Row(
                  children: <Widget>[
                    for (var i = 0; i < _presets.length; i++)
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey<String>('preset-$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectPreset(i),
                          child: Center(
                            child: Text(
                              '${fa('${_presets[i]}')} دقیقه',
                              style: glassText(
                                14,
                                weight: i == _preset
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                opacity: i == _preset ? 1 : 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          LiquidFollower(
            target: Rect.fromLTWH(
              width - pad - (_preset + 1) * cw,
              pad,
              cw,
              52 - 2 * pad,
            ),
            builder: (context, rect) => LiquidGlass.withOwnLayer(
              settings: allGlassSettings().copyWith(refractionAmount: 60),
              appearance: const LiquidGlassAppearance.ios27RegularDark(
                tint: Color(0x22FFFFFF),
              ),
              shape: LiquidRoundedSuperellipse(
                borderRadius: math.min(rect.width, rect.height) / 2,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessions() {
    final shown = _sessions.take(4).toList();
    return GlassSection(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < shown.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: GlassPiece(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Text(shown[i].time, style: glassText(14)),
                    const SizedBox(width: 12),
                    Text(
                      '${fa('${shown[i].minutes}')} دقیقه',
                      style: glassText(14, opacity: 0.85),
                    ),
                    const Spacer(),
                    Icon(
                      shown[i].completed
                          ? Icons.check_circle_rounded
                          : Icons.timelapse_rounded,
                      size: 20,
                      color: shown[i].completed
                          ? GlassPalette.mint
                          : GlassPalette.amber,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(14);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = GlassPalette.amber;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
