// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'all_glass_kit.dart';

/// Sections of the «امروز» tab. Each entry is one sliver child with its own
/// glass layer (at most 16 shapes per layer).
List<Widget> buildTodaySections({required bool fake}) {
  return <Widget>[
    Text('امروز', style: glassText(36, weight: FontWeight.w800)),
    kGap10,
    _TimelineSection(fake: fake),
    const SizedBox(height: 22),
    Text('کارهای امروز', style: glassText(20, weight: FontWeight.w700)),
    kGap10,
    GlassSection(fake: fake, child: const _TaskRows()),
    const SizedBox(height: 22),
    GlassSection(fake: fake, child: const _TilesAndTimer()),
  ];
}

// ---------------------------------------------------------------------------
// Timeline: date capsule + strip share the content layer group; the lens
// together with the «اکنون» lens, which is real glass-on-glass and therefore
// keeps its own layer (independent backdrop sample).

class _Block {
  const _Block(this.title, this.from, this.to, this.color, this.lane);
  final String title;
  final double from;
  final double to;
  final Color color;
  final int lane;
}

const List<_Block> _blocks = <_Block>[
  _Block('ورزش صبح', 8, 9.25, GlassPalette.turquoise, 0),
  _Block('قسط وام', 11, 12, GlassPalette.saffron, 1),
  _Block('طراحی', 13, 14.5, GlassPalette.mint, 0),
  _Block('جلسه با تیم طراحی', 15, 17, GlassPalette.violet, 1),
  _Block('بیمه', 18, 19, GlassPalette.pomegranate, 0),
];

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.fake});

  final bool fake;

  static const double _capsuleH = 42;
  static const double _gap = 12;
  static const double _stripH = 138;
  static const double _hours = 14; // 08 -> 22
  static const double _now = 14.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const pad = 14.0;
        final inner = w - pad * 2;
        final nowX = pad + inner * (1 - (_now - 8) / _hours);
        return SizedBox(
          height: _capsuleH + _gap + _stripH,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: GlassSection(
                  fake: fake,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: _capsuleH,
                        child: GlassPiece(
                          radius: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'چهارشنبه ۱۳ آبان ۱۴۰۵',
                              style: glassText(15, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: _gap),
                      SizedBox(
                        height: _stripH,
                        width: w,
                        child: GlassPiece(
                          radius: 30,
                          padding: const EdgeInsets.symmetric(
                            horizontal: pad,
                            vertical: 12,
                          ),
                          child: _StripContent(width: inner),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: nowX - 50,
                top: _capsuleH + _gap + 34,
                width: 100,
                height: 74,
                child: LiquidGlass.withOwnLayer(
                  fake: fake,
                  settings: allGlassSettings().copyWith(
                    refractionHeight: 22,
                    refractionAmount: 90,
                    frost: 1.5,
                  ),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 37),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('اکنون', style: glassText(12, opacity: 0.9)),
                        Text(
                          '۱۴:۳۰',
                          style: glassText(20, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StripContent extends StatelessWidget {
  const _StripContent({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final unit = width / _TimelineSection._hours;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 18,
          child: Stack(
            children: <Widget>[
              for (var h = 8; h <= 22; h += 2)
                PositionedDirectional(
                  start: (h - 8) * unit - 10,
                  width: 20,
                  child: Text(
                    fa(h.toString().padLeft(2, '0')),
                    textAlign: TextAlign.center,
                    style: glassText(11, opacity: 0.75),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Stack(
            children: <Widget>[
              for (final b in _blocks)
                PositionedDirectional(
                  start: (b.from - 8) * unit,
                  width: (b.to - b.from) * unit - 3,
                  top: b.lane * 44.0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: b.color.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: (b.to - b.from) * unit > 56
                          ? Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: glassText(11, weight: FontWeight.w700),
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TaskRows extends StatelessWidget {
  const _TaskRows();

  static const List<(String, String?, bool)> _tasks = <(String, String?, bool)>[
    ('ورزش صبح', null, true),
    ('پرداخت قسط وام', null, true),
    ('جلسه با تیم طراحی', '۱۵:۰۰', false),
    ('تمدید بیمهٔ ماشین', '۱۸:۰۰', false),
    ('خرید هدیهٔ تولد مریم', null, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final t in _tasks) ...<Widget>[
          SizedBox(
            height: 62,
            child: GlassPiece(
              radius: 31,
              padding: const EdgeInsetsDirectional.only(start: 14, end: 20),
              child: Row(
                children: <Widget>[
                  _Check(done: t.$3),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glassText(16, weight: FontWeight.w600).copyWith(
                        color: Colors.white.withValues(alpha: t.$3 ? 0.62 : 1),
                        decoration: t.$3 ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                  if (t.$2 != null)
                    Text(t.$2!, style: glassText(14, opacity: 0.85)),
                ],
              ),
            ),
          ),
          if (t != _tasks.last) kGap10,
        ],
      ],
    );
  }
}

/// Round checkbox. Deliberately NOT glass: glass never sits on glass.
class _Check extends StatelessWidget {
  const _Check({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? GlassPalette.mint.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: done ? 0 : 0.7),
          width: 1.6,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 20, color: Color(0xFF0B3B35))
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class _TilesAndTimer extends StatelessWidget {
  const _TilesAndTimer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 156,
                child: GlassPiece(
                  radius: 30,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'مانده از بودجه',
                        style: glassText(13, opacity: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '۷٬۵۵۰٬۰۰۰',
                        style: glassText(22, weight: FontWeight.w800),
                      ),
                      Text('تومان', style: glassText(12, opacity: 0.8)),
                      const Spacer(),
                      const GlassProgressTrack(
                        value: 0.62,
                        color: GlassPalette.amber,
                      ),
                      const SizedBox(height: 6),
                      Text('۶۲٪ مانده', style: glassText(12, opacity: 0.8)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 156,
                child: GlassPiece(
                  radius: 30,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('پیاده‌روی', style: glassText(13, opacity: 0.8)),
                      const SizedBox(height: 6),
                      Text(
                        '۱۲ روز',
                        style: glassText(22, weight: FontWeight.w800),
                      ),
                      Text('پیاپی', style: glassText(12, opacity: 0.8)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          for (var i = 0; i < 7; i++)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < 6
                                    ? GlassPalette.mint
                                    : Colors.white.withValues(alpha: 0.2),
                                border: i < 6
                                    ? null
                                    : Border.all(color: Colors.white54),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        kGap10,
        const _TimerPill(),
      ],
    );
  }
}

class _TimerPill extends StatefulWidget {
  const _TimerPill();

  @override
  State<_TimerPill> createState() => _TimerPillState();
}

class _TimerPillState extends State<_TimerPill> {
  int _seconds = 42 * 60 + 10;
  bool _running = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _label {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return fa('$h:$m:$s');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: GlassPiece(
        radius: 34,
        padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: GlassPalette.pomegranate,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'طراحی صفحهٔ اصلی',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: glassText(15, weight: FontWeight.w600),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _label,
                style: glassText(18, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _running = !_running),
              child: Semantics(
                button: true,
                label: _running ? 'توقف' : 'ادامه',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                  child: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
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
