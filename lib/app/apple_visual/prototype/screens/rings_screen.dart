// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../all_glass_kit.dart';

const Color _kTasks = Color(0xFF5B8CFF);
const Color _kHabits = Color(0xFF2FC4B0);
const Color _kSpend = Color(0xFFF4B33A);

/// «خلاصه»: three segmented rings on one glass disc. Tap the disc and three
/// glass capsules pinch off it like liquid; tap again and they merge back.
class RingsScreen extends StatefulWidget {
  const RingsScreen({super.key});

  @override
  State<RingsScreen> createState() => _RingsScreenState();
}

class _RingsScreenState extends State<RingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _split = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 480),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _appear.value = 1;
      } else {
        _appear.forward();
      }
    }
  }

  @override
  void dispose() {
    _appear.dispose();
    _split.dispose();
    super.dispose();
  }

  void _toggle() {
    final target =
        _split.status == AnimationStatus.forward ||
            _split.status == AnimationStatus.completed
        ? 0.0
        : 1.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _split.value = target;
    } else if (target == 1) {
      _split.forward();
    } else {
      _split.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: glassText(14),
      child: BackdropGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 62, 16, 124),
          children: <Widget>[
            Text('خلاصه', style: glassText(36, weight: FontWeight.w800)),
            const SizedBox(height: 14),
            _Hero(appear: _appear, split: _split, onToggle: _toggle),
            const SizedBox(height: 22),
            GlassSection(child: _WeekAndHighlights(appear: _appear)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RingSpec {
  const _RingSpec(this.radius, this.segments, this.fraction, this.color);
  final double radius;
  final int segments;
  final double fraction;
  final Color color;
}

const List<_RingSpec> _rings = <_RingSpec>[
  _RingSpec(128, 5, 3 / 5, _kTasks),
  _RingSpec(98, 4, 2 / 4, _kHabits),
  _RingSpec(68, 10, 450 / 1200, _kSpend),
];

class _Hero extends StatelessWidget {
  const _Hero({
    required this.appear,
    required this.split,
    required this.onToggle,
  });

  final Animation<double> appear;
  final AnimationController split;
  final VoidCallback onToggle;

  static const double _disc = 300;
  static const double _capH = 76;
  static const double _capTop = 322;

  static const List<(String, String, String, Color)> _caps =
      <(String, String, String, Color)>[
        ('کارها', '۳ از ۵', 'انجام‌شده', _kTasks),
        ('عادت‌ها', '۲ از ۴', 'امروز', _kHabits),
        ('خرج', '۴۵۰ هزار', 'از ۱٫۲ میلیون', _kSpend),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final slot = (w - 16) / 3;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: SizedBox(
            height: _capTop + _capH + 4,
            width: w,
            child: GlassSection(
              blend: 34,
              child: AnimatedBuilder(
                animation: split,
                builder: (context, _) {
                  final v = Curves.easeOutBack.transform(
                    split.isAnimating && split.status == AnimationStatus.reverse
                        ? Curves.easeInOutCubic.transform(split.value)
                        : split.value,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: (w - _disc) / 2,
                        top: 0,
                        width: _disc,
                        height: _disc,
                        child: GlassPiece(
                          circle: true,
                          child: _DiscFace(appear: appear),
                        ),
                      ),
                      if (split.value > 0)
                        for (var i = 0; i < 3; i++) _capsule(i, v, w, slot),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _capsule(int i, double v, double w, double slot) {
    // RTL: capsule 0 sits at the right.
    final endCx = w - (i * (slot + 8)) - slot / 2;
    final endCy = _capTop + _capH / 2;
    final startCx = w / 2 + (1 - i) * 26.0;
    const startCy = 214.0;
    final cx = startCx + (endCx - startCx) * v;
    final cy = startCy + (endCy - startCy) * v;
    final cw = math.max(8.0, 36 + (slot - 36) * v);
    final ch = math.max(8.0, 36 + (_capH - 36) * v);
    final textOpacity = Interval(0.55, 1).transform(split.value);
    final cap = _caps[i];
    return Positioned(
      left: cx - cw / 2,
      top: cy - ch / 2,
      width: cw,
      height: ch,
      child: GlassPiece(
        radius: ch / 2,
        child: Opacity(
          opacity: textOpacity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cap.$4,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(cap.$1, style: glassText(12, opacity: 0.9)),
                    ],
                  ),
                  Text(cap.$2, style: glassText(17, weight: FontWeight.w800)),
                  Text(cap.$3, style: glassText(10.5, opacity: 0.75)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscFace extends StatelessWidget {
  const _DiscFace({required this.appear});

  final Animation<double> appear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(child: CustomPaint(painter: _RingsPainter(appear))),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('امروز', style: glassText(12, opacity: 0.8)),
            Text('۱۳ آبان', style: glassText(19, weight: FontWeight.w800)),
            Text('ضربه بزن', style: glassText(10.5, opacity: 0.6)),
          ],
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t) : super(repaint: t);

  final Animation<double> t;
  static const double _stroke = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < _rings.length; i++) {
      final spec = _rings[i];
      final local = Interval(
        i * 0.14,
        0.62 + i * 0.14,
        curve: Curves.easeOutCubic,
      ).transform(t.value);
      _paintRing(canvas, center, spec, spec.fraction * local);
    }
  }

  void _paintRing(Canvas canvas, Offset c, _RingSpec s, double frac) {
    final r = s.radius;
    const hw = _stroke / 2;
    final n = s.segments;
    final span = 2 * math.pi / n;
    final ga = 7.0 / r;
    final shear = _stroke * 0.42 / r;
    final track = Paint()..color = Colors.white.withValues(alpha: 0.2);
    final fill = Paint()
      ..color = s.color
      ..isAntiAlias = true;
    for (var i = 0; i < n; i++) {
      final a0 = -math.pi / 2 + i * span + ga / 2;
      final a1 = -math.pi / 2 + (i + 1) * span - ga / 2;
      final path = _segment(c, r, hw, a0, a1, shear);
      canvas.drawPath(path, track);
      final amt = (frac * n - i).clamp(0.0, 1.0);
      if (amt <= 0) {
        continue;
      }
      final end = a0 + amt * (a1 + shear - a0 + 0.02);
      final sector = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(
          Rect.fromCircle(center: c, radius: r + hw + 4),
          a0 - 0.02,
          end - (a0 - 0.02),
          false,
        )
        ..close();
      canvas
        ..save()
        ..clipPath(sector)
        ..drawPath(path, fill)
        ..restore();
    }
  }

  Path _segment(
    Offset c,
    double r,
    double hw,
    double a0,
    double a1,
    double sh,
  ) {
    Offset pt(double a, double rad) =>
        c + Offset(math.cos(a), math.sin(a)) * rad;
    final steps = math.max(3, ((a1 - a0) / 0.05).ceil());
    final pts = <Offset>[
      for (var k = 0; k <= steps; k++) pt(a0 + (a1 - a0) * k / steps, r + hw),
      pt(a1 + sh, r),
      for (var k = steps; k >= 0; k--) pt(a0 + (a1 - a0) * k / steps, r - hw),
      pt(a0 + sh, r),
    ];
    return Path()..addPolygon(pts, true);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------

class _WeekAndHighlights extends StatelessWidget {
  const _WeekAndHighlights({required this.appear});

  final Animation<double> appear;

  static const List<String> _days = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GlassPiece(
          radius: 32,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'این هفته',
                    style: glassText(16, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final l in const <(String, Color)>[
                            ('کارها', _kTasks),
                            ('عادت‌ها', _kHabits),
                            ('خرج', _kSpend),
                          ]) ...<Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: l.$2,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(l.$1, style: glassText(11, opacity: 0.8)),
                            const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(painter: _BarsPainter(appear, rtl: true)),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Text(
                        _days[i],
                        textAlign: TextAlign.center,
                        style: glassText(
                          12,
                          weight: i == 4 ? FontWeight.w800 : FontWeight.w500,
                          opacity: i == 4 ? 1 : 0.7,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _highlight(
          Icons.local_fire_department_rounded,
          _kSpend,
          '۱۲ روز پیاپی پیاده‌روی',
        ),
        const SizedBox(height: 10),
        _highlight(Icons.savings_rounded, _kHabits, 'خرج امروز زیر بودجه'),
      ],
    );
  }

  Widget _highlight(IconData icon, Color color, String text) {
    return SizedBox(
      height: 58,
      child: GlassPiece(
        radius: 29,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 20),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF10203A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: glassText(15, weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, {required this.rtl}) : super(repaint: t);

  final Animation<double> t;
  final bool rtl;

  // Sat..Fri; Wednesday (index 4) is today, later days are empty.
  static const List<List<double>> _data = <List<double>>[
    <double>[0.8, 0.6, 1, 0.4, 0.6, 0, 0],
    <double>[0.75, 1, 0.5, 0.75, 0.5, 0, 0],
    <double>[0.5, 0.9, 0.7, 0.6, 0.375, 0, 0],
  ];
  static const List<Color> _colors = <Color>[_kTasks, _kHabits, _kSpend];

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 7;
    const bw = 9.0;
    const gap = 3.0;
    const cluster = bw * 3 + gap * 2;
    final maxH = size.height;
    final todayPaint = Paint()..color = Colors.white.withValues(alpha: 0.14);
    final ghost = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (var d = 0; d < 7; d++) {
      final cx = rtl ? size.width - (d + 0.5) * step : (d + 0.5) * step;
      if (d == 4) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - step / 2 + 2, 0, step - 4, maxH),
            const Radius.circular(14),
          ),
          todayPaint,
        );
      }
      for (var k = 0; k < 3; k++) {
        final x = cx - cluster / 2 + k * (bw + gap);
        final local = Interval(
          (d * 0.05 + k * 0.04).clamp(0.0, 0.7),
          0.55 + d * 0.05,
          curve: Curves.easeOutBack,
        ).transform(t.value);
        final target = _data[k][d];
        final h = target <= 0
            ? bw
            : math.max(bw, (maxH - 14) * target * local.clamp(0.0, 1.2));
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxH - 6 - h, bw, h),
          const Radius.circular(bw / 2),
        );
        canvas.drawRRect(
          rect,
          target <= 0 ? ghost : (Paint()..color = _colors[k]),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.rtl != rtl;
}
