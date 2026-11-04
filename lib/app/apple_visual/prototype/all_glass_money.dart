// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'package:flutter/material.dart';

import 'all_glass_kit.dart';

List<Widget> buildMoneySections({required bool fake}) {
  return <Widget>[
    Text('پول', style: glassText(36, weight: FontWeight.w800)),
    kGap10,
    GlassSection(fake: fake, child: const _BalanceAndChart()),
    const SizedBox(height: 22),
    Text('دسته‌ها', style: glassText(20, weight: FontWeight.w700)),
    kGap10,
    GlassSection(fake: fake, child: const _CategoryRows()),
    const SizedBox(height: 22),
    Text('تراکنش‌ها', style: glassText(20, weight: FontWeight.w700)),
    kGap10,
    GlassSection(fake: fake, child: const _TransactionRows()),
  ];
}

class _BalanceAndChart extends StatefulWidget {
  const _BalanceAndChart();

  @override
  State<_BalanceAndChart> createState() => _BalanceAndChartState();
}

class _BalanceAndChartState extends State<_BalanceAndChart> {
  int _range = 0;

  static const List<String> _ranges = <String>['ماه', 'فصل', 'سال'];
  static const List<List<double>> _series = <List<double>>[
    <double>[0.2, 0.28, 0.25, 0.4, 0.52, 0.5, 0.68, 0.8],
    <double>[0.3, 0.2, 0.45, 0.38, 0.6, 0.55, 0.62, 0.7],
    <double>[0.15, 0.3, 0.26, 0.5, 0.42, 0.66, 0.6, 0.9],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GlassPiece(
          radius: 34,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('موجودی آبان', style: glassText(14, opacity: 0.8)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '۲۸٬۳۵۰٬۰۰۰',
                        style: glassText(34, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('تومان', style: glassText(15, opacity: 0.85)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                children: <Widget>[
                  Text(
                    'درآمد ۳۸٬۰۰۰٬۰۰۰',
                    style: glassText(13).copyWith(color: GlassPalette.mint),
                  ),
                  Text(
                    'هزینه ۹٬۶۵۰٬۰۰۰',
                    style: glassText(
                      13,
                    ).copyWith(color: const Color(0xFFFFB4BF)),
                  ),
                ],
              ),
            ],
          ),
        ),
        kGap10,
        SizedBox(
          height: 48,
          child: GlassPiece(
            radius: 24,
            padding: const EdgeInsets.all(5),
            child: Row(
              children: <Widget>[
                for (var i = 0; i < _ranges.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == _range,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _range = i),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // Non-glass selection pill: no glass on glass.
                            color: i == _range
                                ? Colors.white.withValues(alpha: 0.26)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Center(
                            child: Text(
                              _ranges[i],
                              style: glassText(
                                14,
                                weight: i == _range
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
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
        kGap10,
        SizedBox(
          height: 200,
          child: GlassPiece(
            radius: 34,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('روند هزینه', style: glassText(14, opacity: 0.85)),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _SpendLinePainter(_series[_range]),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpendLinePainter extends CustomPainter {
  _SpendLinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      // RTL: time runs from right to left.
      final x = size.width * (1 - i / (values.length - 1));
      final y = size.height * (1 - values[i]) * 0.9 + 4;
      pts.add(Offset(x, y));
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final mid = (p0.dx + p1.dx) / 2;
      path.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
    for (final p in pts) {
      canvas.drawCircle(p, 3.6, Paint()..color = GlassPalette.amber);
    }
  }

  @override
  bool shouldRepaint(_SpendLinePainter old) => old.values != values;
}

class _CategoryRows extends StatelessWidget {
  const _CategoryRows();

  static const List<(String, double, Color)> _cats = <(String, double, Color)>[
    ('خوراک', 0.38, GlassPalette.amber),
    ('مسکن', 0.34, GlassPalette.mint),
    ('رفت‌وآمد', 0.16, Color(0xFFFF8FA3)),
    ('سایر', 0.12, Color(0xFFC3A6FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final c in _cats) ...<Widget>[
          SizedBox(
            height: 70,
            child: GlassPiece(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          c.$1,
                          style: glassText(15, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        fa('${(c.$2 * 100).round()}٪'),
                        style: glassText(15, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  GlassProgressTrack(value: c.$2 / 0.4, color: c.$3),
                ],
              ),
            ),
          ),
          if (c != _cats.last) kGap10,
        ],
      ],
    );
  }
}

class _TransactionRows extends StatelessWidget {
  const _TransactionRows();

  static const List<(String, String, String, IconData, bool)> _tx =
      <(String, String, String, IconData, bool)>[
        ('ناهار با علی', 'امروز', '−۴۵۰٬۰۰۰', Icons.restaurant_rounded, false),
        ('قسط وام مسکن', 'دیروز', '−۴٬۲۰۰٬۰۰۰', Icons.home_rounded, false),
        ('اسنپ', 'دیروز', '−۱۸۵٬۰۰۰', Icons.directions_car_rounded, false),
        ('حقوق آبان', '۱ آبان', '+۳۸٬۰۰۰٬۰۰۰', Icons.payments_rounded, true),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final t in _tx) ...<Widget>[
          SizedBox(
            height: 66,
            child: GlassPiece(
              radius: 33,
              padding: const EdgeInsetsDirectional.only(start: 12, end: 20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Icon(t.$4, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: glassText(15, weight: FontWeight.w700),
                        ),
                        Text(t.$2, style: glassText(12, opacity: 0.72)),
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      t.$3,
                      style: glassText(15, weight: FontWeight.w800).copyWith(
                        color: t.$5
                            ? GlassPalette.mint
                            : const Color(0xFFFFD0D6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (t != _tx.last) kGap10,
        ],
      ],
    );
  }
}
