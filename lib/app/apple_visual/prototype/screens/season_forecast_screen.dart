// SPIKE EXCEPTION: see ../all_glass_kit.dart (direct liquid_glass_renderer use).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../all_glass_kit.dart';
import 'glass_d_common.dart';

/// Month-end forecast screen that paints its OWN seasonal wallpaper.
///
/// Wow: the glass season switcher recolours the whole wallpaper (800ms) and a
/// draggable glass sheet snaps to detents 0.28 / 0.6 / 0.92.
///
/// Layers: GlassSections for chart, switcher base, switcher lens (own sibling
/// layer so it can slide over the base) and the sheet, all inside a single
/// BackdropGroup, so one backdrop capture.
class SeasonForecastScreen extends StatefulWidget {
  const SeasonForecastScreen({super.key});

  @override
  State<SeasonForecastScreen> createState() => _SeasonForecastScreenState();
}

class _Palette {
  const _Palette(this.bgTop, this.bgBottom, this.blobs, this.accent);

  final Color bgTop;
  final Color bgBottom;
  final List<Color> blobs;
  final Color accent;

  static _Palette lerp(_Palette a, _Palette b, double t) {
    return _Palette(
      Color.lerp(a.bgTop, b.bgTop, t)!,
      Color.lerp(a.bgBottom, b.bgBottom, t)!,
      <Color>[
        for (var i = 0; i < a.blobs.length; i++)
          Color.lerp(a.blobs[i], b.blobs[i], t)!,
      ],
      Color.lerp(a.accent, b.accent, t)!,
    );
  }
}

const List<String> _seasonNames = <String>[
  'بهار',
  'تابستان',
  'پاییز',
  'زمستان',
];

const List<_Palette> _palettes = <_Palette>[
  // Spring: greens and blossom.
  _Palette(Color(0xFF0E4D3A), Color(0xFF0A3329), <Color>[
    Color(0xFF2BB673),
    Color(0xFFA6E22E),
    Color(0xFF7CF0D2),
    Color(0xFFF48FB1),
    Color(0xFF1FB5A8),
    Color(0xFF8BD450),
    Color(0xFF4FC3F7),
  ], Color(0xFFB8F5A0)),
  // Summer: gold.
  _Palette(Color(0xFF7A4A08), Color(0xFF4A2A10), <Color>[
    Color(0xFFF4A300),
    Color(0xFFFFD36B),
    Color(0xFFFF7A3D),
    Color(0xFF1FB5A8),
    Color(0xFFFFB347),
    Color(0xFFF4A300),
    Color(0xFFE8643C),
  ], Color(0xFFFFE08A)),
  // Autumn: rust, pomegranate, amber.
  _Palette(Color(0xFF4A1D12), Color(0xFF2E1010), <Color>[
    Color(0xFFB7410E),
    Color(0xFFF4A300),
    Color(0xFFC8324B),
    Color(0xFFD9692B),
    Color(0xFF8E2A3C),
    Color(0xFFF4A300),
    Color(0xFFC8324B),
  ], Color(0xFFFFD36B)),
  // Winter: lapis and ice.
  _Palette(Color(0xFF1F3A93), Color(0xFF0E1B4D), <Color>[
    Color(0xFFBDE6FF),
    Color(0xFF2A4FD0),
    Color(0xFF4FC3F7),
    Color(0xFF7B4FD1),
    Color(0xFF9CC9FF),
    Color(0xFF2A4FD0),
    Color(0xFFD8EEFF),
  ], Color(0xFFCFEAFF)),
];

const int _autumn = 2;

class _SeasonForecastScreenState extends State<SeasonForecastScreen>
    with TickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );
  late final AnimationController _shift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    value: 1,
  );
  final DraggableScrollableController _sheet = DraggableScrollableController();

  int _season = _autumn;
  _Palette _from = _palettes[_autumn];
  _Palette _to = _palettes[_autumn];
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _drift.stop();
      _shift.value = 1;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _shift.dispose();
    _sheet.dispose();
    super.dispose();
  }

  _Palette get _current =>
      _Palette.lerp(_from, _to, Curves.easeInOutCubic.transform(_shift.value));

  void _pick(int i) {
    if (i == _season) {
      return;
    }
    HapticFeedback.selectionClick();
    // Start from whatever is on screen now so rapid taps never jump.
    _from = _current;
    _to = _palettes[i];
    setState(() => _season = i);
    if (_reduced) {
      _shift.value = 1;
    } else {
      _shift.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: glassText(14),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_drift, _shift]),
                builder: (context, _) => CustomPaint(
                  painter: _SeasonWallpaperPainter(_current, _drift.value),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropGroup(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: _buildTop()),
                  Positioned.fill(child: _buildSheet()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 58, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSwitcher(),
          const SizedBox(height: 6),
          Text(
            'آبان',
            style: glassText(104, weight: FontWeight.w100, height: 1.15),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  '۱۹٫۱ میلیون',
                  style: glassText(46, weight: FontWeight.w200),
                ),
                const SizedBox(width: 8),
                Text('تومان', style: glassText(15, opacity: 0.85)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 10,
            children: <Widget>[
              Text(
                'پیش‌بینی پایان ماه · بودجه ۲۰ میلیون',
                style: glassText(13.5, opacity: 0.85),
              ),
              Text(
                'در محدودهٔ بودجه',
                style: glassText(
                  13.5,
                  weight: FontWeight.w800,
                ).copyWith(color: GlassPalette.mint),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassSection(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildSwitcher() {
    const h = 48.0;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final seg = (w - 8) / 4;
        // RTL: segment 0 (بهار) sits at the right edge.
        final lensLeft = 4 + (3 - _season) * seg;
        return SizedBox(
          height: h,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: GlassSection(
                  child: TintedGlass(radius: 24, child: SizedBox.expand()),
                ),
              ),
              // The lens slides on its own sibling layer above the base.
              AnimatedPositioned(
                duration: _reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                left: lensLeft,
                top: 4,
                width: seg,
                height: h - 8,
                child: IgnorePointer(
                  child: GlassSection(
                    settings: allGlassSettings().copyWith(
                      refractionAmount: 110,
                      refractionHeight: 30,
                    ),
                    child: TintedGlass(
                      radius: 20,
                      tint: _palettes[_season].accent.withValues(alpha: 0.35),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: <Widget>[
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == _season,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _pick(i),
                              child: Center(
                                child: Text(
                                  _seasonNames[i],
                                  style: glassText(
                                    14,
                                    weight: i == _season
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: TintedGlass(
        radius: 32,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('روند هزینهٔ انباشته', style: glassText(13.5, opacity: 0.85)),
            const SizedBox(height: 6),
            Expanded(
              child: AnimatedBuilder(
                animation: _shift,
                builder: (context, _) => CustomPaint(
                  painter: _ForecastPainter(_current.accent),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('۱ آبان', style: glassText(11.5, opacity: 0.75)),
                Text(
                  'امروز ۱۳',
                  style: glassText(11.5, weight: FontWeight.w800),
                ),
                Text('۳۰ آبان', style: glassText(11.5, opacity: 0.75)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return DraggableScrollableSheet(
      controller: _sheet,
      initialChildSize: 0.28,
      minChildSize: 0.28,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const <double>[0.28, 0.6, 0.92],
      builder: (context, scroll) {
        return GlassSection(
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
            child: Column(
              children: <Widget>[
                _sheetHeader(),
                kGap10,
                _weekStrip(),
                kGap10,
                _installment(),
                kGap10,
                _rangeBars(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final cur = _sheet.size;
        final next = cur < 0.4 ? 0.6 : (cur < 0.75 ? 0.92 : 0.28);
        if (_reduced) {
          _sheet.jumpTo(next);
        } else {
          _sheet.animateTo(
            next,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: TintedGlass(
          radius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برنامهٔ مالی آبان',
                style: glassText(16, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekStrip() {
    // Wednesday 13 Aban + 6 days. Amounts in thousand toman.
    const days = <(String, int, int, String)>[
      ('چ', 13, 0, ''),
      ('پ', 14, 480, 'اینترنت'),
      ('ج', 15, 0, ''),
      ('ش', 16, 1200, 'بیمه'),
      ('ی', 17, 0, ''),
      ('د', 18, 350, 'اشتراک'),
      ('س', 19, 2800, 'شهریه'),
    ];
    return TintedGlass(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('پرداخت‌های ۷ روز آینده', style: glassText(14, opacity: 0.9)),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final d in days)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        if (d.$3 > 0)
                          Text(
                            fa(
                              '${d.$3 >= 1000 ? (d.$3 / 1000).toStringAsFixed(1).replaceAll('.', '٫') : d.$3}',
                            ),
                            style: glassText(10.5, weight: FontWeight.w700),
                          ),
                        const SizedBox(height: 3),
                        Container(
                          width: 14,
                          height: d.$3 == 0 ? 4 : 8 + d.$3 / 3000 * 40,
                          decoration: BoxDecoration(
                            color: d.$3 == 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : _palettes[_season].accent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          fa('${d.$1} ${d.$2}'),
                          style: glassText(
                            11.5,
                            weight: d.$2 == 13
                                ? FontWeight.w800
                                : FontWeight.w500,
                            opacity: d.$2 == 13 ? 1 : 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _installment() {
    return TintedGlass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GlassPalette.pomegranate.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'قسط وام ۱۰ آذر',
                  style: glassText(15.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text('۲۷ روز دیگر', style: glassText(12.5, opacity: 0.8)),
              ],
            ),
          ),
          Text('۳٬۲۰۰٬۰۰۰', style: glassText(15, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _rangeBars() {
    // value/lo/hi as fractions of the axis (0..1); label shows spend in M.
    const rows = <(String, String, double, double, double)>[
      ('خوراک', '۳٫۱', 0.62, 0.50, 0.70),
      ('رفت‌وآمد', '۱٫۴', 0.28, 0.25, 0.45),
      ('مسکن', '۴٫۸', 0.96, 0.80, 0.96),
      ('تفریح', '۰٫۶', 0.12, 0.15, 0.40),
    ];
    return TintedGlass(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'دسته‌ها نسبت به بازهٔ معمول',
            style: glassText(14, opacity: 0.9),
          ),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    child: Text(r.$1, style: glassText(13.5)),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: CustomPaint(
                        painter: _RangeBarPainter(
                          value: r.$3,
                          lo: r.$4,
                          hi: r.$5,
                          color: _palettes[_season].accent,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      '${r.$2}م',
                      textAlign: TextAlign.end,
                      style: glassText(12.5, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  _RangeBarPainter({
    required this.value,
    required this.lo,
    required this.hi,
    required this.color,
  });

  final double value;
  final double lo;
  final double hi;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // RTL: the axis starts at the right edge.
    double x(double f) => size.width * (1 - f);
    final mid = size.height / 2;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, mid - 2, size.width, 4),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.2),
      )
      ..drawRRect(
        RRect.fromLTRBR(
          x(hi),
          1,
          x(lo),
          size.height - 1,
          const Radius.circular(6),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      )
      ..drawCircle(Offset(x(value), mid), 6, Paint()..color = color)
      ..drawCircle(
        Offset(x(value), mid),
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white,
      );
  }

  @override
  bool shouldRepaint(_RangeBarPainter old) =>
      old.value != value || old.lo != lo || old.hi != hi || old.color != color;
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(this.accent);

  final Color accent;

  // Cumulative spend (millions) for Aban 1..13; projection ends at 19.1 on 30.
  static const List<double> _spent = <double>[
    0.4,
    1.1,
    1.5,
    2.4,
    3.0,
    3.3,
    4.2,
    5.0,
    5.6,
    6.9,
    7.7,
    8.9,
    9.65,
  ];
  static const double _end = 19.1;
  static const double _budget = 20;
  static const double _max = 22;

  @override
  void paint(Canvas canvas, Size size) {
    // RTL: day 1 at the right edge.
    Offset pt(int day, double v) => Offset(
      size.width * (1 - (day - 1) / 29),
      size.height - size.height * (v / _max),
    );

    final budgetY = pt(1, _budget).dy;
    canvas.drawPath(
      dashedPath(
        Path()
          ..moveTo(0, budgetY)
          ..lineTo(size.width, budgetY),
        dash: 3,
        gap: 5,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    final solid = Path();
    final pts = <Offset>[
      for (var i = 0; i < _spent.length; i++) pt(i + 1, _spent[i]),
    ];
    solid.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final mid = (p0.dx + p1.dx) / 2;
      solid.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(solid)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    canvas.drawPath(solid, stroke);

    // Dashed projection from today to the month end.
    final today = pts.last;
    final endPt = pt(30, _end);
    final proj = Path()
      ..moveTo(today.dx, today.dy)
      ..cubicTo(
        today.dx - (today.dx - endPt.dx) * 0.4,
        today.dy - 6,
        endPt.dx + (today.dx - endPt.dx) * 0.3,
        endPt.dy + 4,
        endPt.dx,
        endPt.dy,
      );
    canvas
      ..drawPath(
        dashedPath(proj),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = accent,
      )
      ..drawCircle(endPt, 4.5, Paint()..color = accent)
      ..drawCircle(
        today,
        9,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      )
      ..drawCircle(today, 5, Paint()..color = Colors.white);

    final tp = TextPainter(
      text: TextSpan(
        text: fa('بودجه ۲۰م'),
        style: glassText(10.5, opacity: 0.85),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, budgetY - tp.height - 1));
  }

  @override
  bool shouldRepaint(_ForecastPainter old) => old.accent != accent;
}

class _SeasonWallpaperPainter extends CustomPainter {
  _SeasonWallpaperPainter(this.palette, this.t);

  final _Palette palette;
  final double t;

  static const List<(double, double, double, double)> _layout =
      <(double, double, double, double)>[
        (0.15, 0.16, 0.50, 0.0),
        (0.92, 0.30, 0.46, 1.3),
        (0.10, 0.52, 0.48, 2.4),
        (0.85, 0.66, 0.48, 3.6),
        (0.35, 0.88, 0.50, 4.7),
        (0.05, 0.96, 0.36, 5.5),
        (0.95, 0.96, 0.40, 0.8),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[palette.bgTop, palette.bgBottom],
        ).createShader(Offset.zero & size),
    );
    final angle = t * 2 * math.pi;
    final base = size.shortestSide;
    for (var i = 0; i < _layout.length; i++) {
      final b = _layout[i];
      final dx = math.sin(angle + b.$4) * 0.07 * size.width;
      final dy = math.cos(angle * 2 + b.$4) * 0.04 * size.height;
      final center = Offset(b.$1 * size.width + dx, b.$2 * size.height + dy);
      final radius = b.$3 * base * 1.25;
      final color = palette.blobs[i];
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0),
            ],
            stops: const <double>[0.25, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_SeasonWallpaperPainter old) =>
      old.palette != palette || old.t != t;
}
