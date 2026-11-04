// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../all_glass_kit.dart';

class _Envelope {
  const _Envelope(this.name, this.allotted, this.spent, this.color, this.txs);

  final String name;
  final int allotted;
  final int spent;
  final Color color;
  final List<(String, String, String)> txs;

  int get left => allotted - spent;
}

const List<_Envelope> _envelopes = <_Envelope>[
  _Envelope('خوراک', 6500000, 4730000, GlassPalette.turquoise, [
    ('سوپرمارکت', '−۸۴۰٬۰۰۰', 'دیروز'),
    ('ناهار با علی', '−۴۵۰٬۰۰۰', 'امروز'),
    ('میوه و سبزی', '−۲۱۰٬۰۰۰', '۱۰ آبان'),
  ]),
  _Envelope('مسکن', 4300000, 4240000, GlassPalette.pomegranate, [
    ('قبض برق', '−۱۸۰٬۰۰۰', '۹ آبان'),
    ('شارژ ساختمان', '−۶۰۰٬۰۰۰', '۵ آبان'),
    ('اجارهٔ آبان', '−۳٬۴۶۰٬۰۰۰', '۱ آبان'),
  ]),
  _Envelope('رفت‌وآمد', 3000000, 1990000, GlassPalette.saffron, [
    ('کرایه تاکسی', '−۱۸۰٬۰۰۰', 'امروز'),
    ('بنزین', '−۴۲۰٬۰۰۰', '۱۱ آبان'),
    ('مترو', '−۳۵٬۰۰۰', '۸ آبان'),
  ]),
  _Envelope('تفریح', 2000000, 400000, GlassPalette.violet, [
    ('سینما', '−۲۴۰٬۰۰۰', '۶ آبان'),
    ('اشتراک موسیقی', '−۱۲۰٬۰۰۰', '۴ آبان'),
    ('کتاب', '−۴۰٬۰۰۰', '۲ آبان'),
  ]),
  _Envelope('سایر', 4200000, 1090000, GlassPalette.mint, [
    ('هدیهٔ تولد', '−۵۲۰٬۰۰۰', '۷ آبان'),
    ('داروخانه', '−۱۹۰٬۰۰۰', '۳ آبان'),
    ('آرایشگاه', '−۳۸۰٬۰۰۰', '۲ آبان'),
  ]),
];

bool _fakeByDefault() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } on Object {
    return false;
  }
}

String _money(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      b.write('٬');
    }
    b.write(s[i]);
  }
  return fa(b.toString());
}

/// Budget envelopes as round glass plates in a carousel with liquid page dots.
class EnvelopesScreen extends StatefulWidget {
  const EnvelopesScreen({super.key});

  @override
  State<EnvelopesScreen> createState() => _EnvelopesScreenState();
}

class _EnvelopesScreenState extends State<EnvelopesScreen> {
  final PageController _controller = PageController(viewportFraction: 0.7);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _pos {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? _page.toDouble();
    }
    return _page.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final fake = _fakeByDefault();
    final env = _envelopes[_page];
    return BackdropGroup(
      child: DefaultTextStyle(
        style: glassText(14),
        child: Padding(
          padding: const EdgeInsets.only(top: 62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'پاکت‌ها',
                  style: glassText(36, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              GlassSection(
                fake: fake,
                blend: 3,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          _chip('${_money(7550000)} مانده'),
                          const SizedBox(width: 10),
                          _chip('${fa('2')} پرداخت این هفته'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 270,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _envelopes.length,
                        clipBehavior: Clip.none,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) => AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final d = (_pos - i).abs().clamp(0.0, 1.0);
                            return Center(
                              child: Opacity(
                                opacity: 1 - 0.55 * d,
                                child: Transform.scale(
                                  scale: 1 - 0.22 * d,
                                  child: _Plate(env: _envelopes[i]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GlassSection(
                fake: fake,
                blend: 18,
                child: SizedBox(
                  height: 24,
                  width: 390,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _Dots(position: _pos),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassSection(
                fake: fake,
                blend: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    child: Column(
                      key: ValueKey<int>(_page),
                      children: <Widget>[
                        for (final t in env.txs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: 50,
                              child: GlassPiece(
                                radius: 22,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            t.$1,
                                            style: glassText(
                                              14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            t.$3,
                                            style: glassText(11, opacity: 0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      t.$2,
                                      style:
                                          glassText(
                                            14,
                                            weight: FontWeight.w800,
                                          ).copyWith(
                                            color: const Color(0xFFFFB4BF),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Flexible(
      child: GlassPiece(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: glassText(13, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.env});

  final _Envelope env;

  @override
  Widget build(BuildContext context) {
    final ratio = env.spent / env.allotted;
    final warn = ratio > 0.9;
    final color = warn ? GlassPalette.pomegranate : env.color;
    return SizedBox(
      width: 240,
      height: 240,
      child: LiquidGlass.grouped(
        shape: const LiquidOval(),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: _SectorPainter(ratio, color)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(env.name, style: glassText(18, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  _money(env.left),
                  style: glassText(26, weight: FontWeight.w800),
                ),
                Text('تومان مانده', style: glassText(12, opacity: 0.85)),
                const SizedBox(height: 4),
                Text(
                  '${_money(env.spent)} از ${_money(env.allotted)}',
                  style: glassText(11, opacity: 0.75),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted pie sector (paint, not glass) filling from the right (3 o'clock)
/// counter-clockwise by spent/allotted.
class _SectorPainter extends CustomPainter {
  _SectorPainter(this.ratio, this.color);

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(10);
    canvas
      ..drawArc(
        rect,
        0,
        -2 * math.pi * ratio.clamp(0.0, 1.0),
        true,
        Paint()..color = color.withValues(alpha: 0.5),
      )
      ..drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.3),
      );
  }

  @override
  bool shouldRepaint(_SectorPainter old) =>
      old.ratio != ratio || old.color != color;
}

/// Page dots as glass pills; the active pill stretches (worm) between pages and
/// merges with its neighbours through the layer's blend group.
class _Dots extends StatelessWidget {
  const _Dots({required this.position});

  final double position;

  static const double _spacing = 22;
  static const double _d = 10;
  static const double _w = 390;

  double _x(double i) => _w / 2 - (i - (_envelopes.length - 1) / 2) * _spacing;

  @override
  Widget build(BuildContext context) {
    final a = position.floor().clamp(0, _envelopes.length - 1);
    final f = (position - a).clamp(0.0, 1.0);
    final lead = _x(a.toDouble()) - _spacing * math.min(1.0, f * 2);
    final trail = _x(a.toDouble()) - _spacing * math.max(0.0, (f - 0.5) * 2);
    final left = math.min(lead, trail) - _d / 2 - 2;
    final right = math.max(lead, trail) + _d / 2 + 2;
    return Stack(
      children: <Widget>[
        for (var i = 0; i < _envelopes.length; i++)
          Positioned(
            left: _x(i.toDouble()) - _d / 2,
            top: 7,
            width: _d,
            height: _d,
            child: const GlassPiece(circle: true, child: SizedBox.shrink()),
          ),
        Positioned(
          left: left,
          width: right - left,
          top: 4,
          height: _d + 6,
          child: const GlassPiece(radius: 10, child: SizedBox.shrink()),
        ),
      ],
    );
  }
}
