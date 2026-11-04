// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../all_glass_kit.dart';

class _Account {
  const _Account(this.name, this.balance, this.digits, this.tint, this.txs);

  final String name;
  final String balance;
  final String digits;
  final Color tint;
  final List<_Tx> txs;
}

class _Tx {
  const _Tx(this.title, this.amount, this.date, {this.income = false});

  final String title;
  final String amount;
  final String date;
  final bool income;
}

const List<_Account> _accounts = <_Account>[
  _Account('کارت ملت', '۲۱٬۴۰۰٬۰۰۰', '۴۴۱۲', GlassPalette.lapis, <_Tx>[
    _Tx('ناهار با علی', '−۴۵۰٬۰۰۰', 'امروز'),
    _Tx('سوپرمارکت', '−۸۴۰٬۰۰۰', 'دیروز'),
    _Tx('حقوق آبان', '+۳۸٬۰۰۰٬۰۰۰', '۱ آبان', income: true),
    _Tx('اشتراک موسیقی', '−۱۲۰٬۰۰۰', '۸ آبان'),
  ]),
  _Account('پس‌انداز', '۳۱٬۰۰۰٬۰۰۰', '۹۰۷۱', GlassPalette.turquoise, <_Tx>[
    _Tx('سود ماهانه', '+۶۲۰٬۰۰۰', '۱۲ آبان', income: true),
    _Tx('واریز از ملت', '+۵٬۰۰۰٬۰۰۰', '۵ آبان', income: true),
    _Tx('برداشت اضطراری', '−۱٬۵۰۰٬۰۰۰', '۲۸ مهر'),
    _Tx('واریز از ملت', '+۵٬۰۰۰٬۰۰۰', '۵ مهر', income: true),
  ]),
  _Account('نقد', '۱٬۲۰۰٬۰۰۰', '۰۰۰۰', GlassPalette.saffron, <_Tx>[
    _Tx('کرایه تاکسی', '−۱۸۰٬۰۰۰', 'امروز'),
    _Tx('قهوه', '−۹۵٬۰۰۰', 'دیروز'),
    _Tx('خرده‌ریز', '−۶۰٬۰۰۰', '۱۰ آبان'),
    _Tx('برداشت از خودپرداز', '+۲٬۰۰۰٬۰۰۰', '۹ آبان', income: true),
  ]),
  _Account('طلب از رضا', '۲٬۰۰۰٬۰۰۰', '۱۹۸۸', GlassPalette.pomegranate, <_Tx>[
    _Tx('قرض سفر', '+۱٬۵۰۰٬۰۰۰', '۲۰ مهر', income: true),
    _Tx('پیتزا', '+۵۰۰٬۰۰۰', '۱۴ مهر', income: true),
  ]),
];

bool _fakeByDefault() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } on Object {
    return false;
  }
}

/// Wallet-style deck of tinted glass account cards. Tapping a card lifts it to
/// the top, fans the others into a thin stack and slides its transactions in.
class WalletStackScreen extends StatefulWidget {
  const WalletStackScreen({super.key});

  @override
  State<WalletStackScreen> createState() => _WalletStackScreenState();
}

class _WalletStackScreenState extends State<WalletStackScreen> {
  static const double _bodyH = 610;
  static const double _cardH = 210;

  int? _selected;

  void _tap(int i) => setState(() => _selected = _selected == i ? null : i);

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dur = reduced ? Duration.zero : const Duration(milliseconds: 560);
    final sel = _selected;
    var fanK = 0;
    final cards = <Widget>[];
    for (var i = 0; i < _accounts.length; i++) {
      double top;
      double inset;
      double height;
      var compact = false;
      if (sel == null) {
        top = i * 76.0;
        inset = 20;
        height = _cardH;
      } else if (sel == i) {
        top = 0;
        inset = 10;
        height = 228;
      } else {
        top = 500 + fanK * 16.0;
        inset = 26 + fanK * 6.0;
        height = 70;
        compact = true;
        fanK++;
      }
      cards.add(
        AnimatedPositioned(
          key: ValueKey<int>(i),
          duration: dur,
          curve: Curves.easeOutBack,
          top: top,
          left: inset,
          right: inset,
          height: height,
          child: _WalletCard(
            account: _accounts[i],
            compact: compact,
            onTap: () => _tap(i),
          ),
        ),
      );
    }
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
                  'کیف پول',
                  style: glassText(36, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: _bodyH,
                child: GlassSection(
                  fake: _fakeByDefault(),
                  blend: 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      ...cards,
                      if (sel != null)
                        for (var r = 0; r < _accounts[sel].txs.length; r++)
                          _TxRow(
                            key: ValueKey<String>('tx-$sel-$r'),
                            tx: _accounts[sel].txs[r],
                            top: 246 + r * 58.0,
                            index: r,
                            reduced: reduced,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.account,
    required this.compact,
    required this.onTap,
  });

  final _Account account;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: account.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LiquidGlass.grouped(
          shape: const LiquidRoundedSuperellipse(borderRadius: 36),
          appearance: LiquidGlassAppearance.ios27RegularDark(
            tint: account.tint.withValues(alpha: 0.55),
          ),
          child: ClipRect(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GirihPainter(
                      Colors.white.withValues(alpha: compact ? 0.1 : 0.16),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 210,
                    maxHeight: 210,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                account.name,
                                style: glassText(18, weight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.contactless_rounded,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              account.balance,
                              style: glassText(34, weight: FontWeight.w800),
                            ),
                          ),
                          Text('تومان', style: glassText(13, opacity: 0.8)),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '•••• ${account.digits}',
                              style: glassText(14, opacity: 0.85),
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
    );
  }
}

/// Subtle engraved lattice of eight-pointed stars (two rotated squares).
class _GirihPainter extends CustomPainter {
  _GirihPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    const step = 46.0;
    const r = 15.0;
    for (var cy = 0.0; cy < size.height + step; cy += step) {
      for (var cx = 0.0; cx < size.width + step; cx += step) {
        for (final rot in <double>[0, math.pi / 4]) {
          final path = Path();
          for (var k = 0; k < 4; k++) {
            final a = rot + k * math.pi / 2;
            final pt = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
            if (k == 0) {
              path.moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          canvas.drawPath(path..close(), p);
        }
        canvas.drawLine(Offset(cx + r, cy), Offset(cx + step - r, cy), p);
        canvas.drawLine(Offset(cx, cy + r), Offset(cx, cy + step - r), p);
      }
    }
  }

  @override
  bool shouldRepaint(_GirihPainter old) => old.color != color;
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.tx,
    required this.top,
    required this.index,
    required this.reduced,
    super.key,
  });

  final _Tx tx;
  final double top;
  final int index;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      height: 50,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
        duration: reduced
            ? Duration.zero
            : Duration(milliseconds: 320 + index * 90),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -60 * (1 - t)),
            child: child,
          ),
        ),
        child: GlassPiece(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tx.title,
                      style: glassText(14, weight: FontWeight.w700),
                    ),
                    Text(tx.date, style: glassText(11, opacity: 0.7)),
                  ],
                ),
              ),
              Text(
                tx.amount,
                style: glassText(14, weight: FontWeight.w800).copyWith(
                  color: tx.income
                      ? GlassPalette.mint
                      : const Color(0xFFFFB4BF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
