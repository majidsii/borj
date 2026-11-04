// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../all_glass_kit.dart';
import 'glass_liquid_follower.dart';

enum _Kind { task, payment, habit }

class _Item {
  const _Item(this.kind, this.text);

  final _Kind kind;
  final String text;
}

class _MonthInfo {
  const _MonthInfo(this.name, this.startCol, this.dayOffset);

  final String name;

  /// Column of day 1 (0 = شنبه ... 6 = جمعه).
  final int startCol;

  /// Days between 1 Aban 1405 and day 1 of this month.
  final int dayOffset;
}

const List<_MonthInfo> _months = <_MonthInfo>[
  _MonthInfo('مهر', 4, -30),
  _MonthInfo('آبان', 6, 0),
  _MonthInfo('آذر', 1, 30),
];

const List<String> _weekdays = <String>[
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
];

const Map<int, List<_Item>> _abanItems = <int, List<_Item>>{
  3: <_Item>[_Item(_Kind.task, 'تحویل طرح ۱۰:۰۰')],
  6: <_Item>[
    _Item(_Kind.payment, 'اجاره ۹٬۰۰۰٬۰۰۰'),
    _Item(_Kind.habit, 'مطالعه ✓'),
  ],
  9: <_Item>[_Item(_Kind.habit, 'پیاده‌روی ✓')],
  11: <_Item>[
    _Item(_Kind.task, 'مرور هفتگی ۰۹:۰۰'),
    _Item(_Kind.habit, 'مطالعه ✓'),
  ],
  13: <_Item>[
    _Item(_Kind.task, 'جلسه ۱۵:۰۰'),
    _Item(_Kind.payment, 'بیمه ۱۸:۰۰'),
    _Item(_Kind.payment, 'قسط ۴٬۲۰۰٬۰۰۰'),
    _Item(_Kind.habit, 'پیاده‌روی ✓'),
  ],
  16: <_Item>[_Item(_Kind.task, 'ارسال گزارش ۱۱:۰۰')],
  18: <_Item>[
    _Item(_Kind.payment, 'قبض برق ۸۵۰٬۰۰۰'),
    _Item(_Kind.task, 'دندان‌پزشک ۱۶:۳۰'),
  ],
  21: <_Item>[_Item(_Kind.habit, 'مراقبه ✓')],
  24: <_Item>[
    _Item(_Kind.task, 'جلسهٔ برنامه‌ریزی ۱۴:۰۰'),
    _Item(_Kind.payment, 'شهریه ۳٬۵۰۰٬۰۰۰'),
    _Item(_Kind.habit, 'پیاده‌روی ✓'),
  ],
  27: <_Item>[_Item(_Kind.payment, 'اینترنت ۴۲۰٬۰۰۰')],
  30: <_Item>[_Item(_Kind.task, 'بستن حساب ماه ۱۷:۰۰')],
};

List<_Item> _itemsFor(int month, int day) {
  if (month == 1) {
    return _abanItems[day] ?? const <_Item>[];
  }
  if (day % 5 == 0) {
    return const <_Item>[_Item(_Kind.payment, 'قسط ۴٬۲۰۰٬۰۰۰')];
  }
  if (day % 7 == 2) {
    return const <_Item>[
      _Item(_Kind.task, 'کار روزانه ۱۰:۰۰'),
      _Item(_Kind.habit, 'پیاده‌روی ✓'),
    ];
  }
  return const <_Item>[];
}

Color _kindColor(_Kind kind) => switch (kind) {
  _Kind.task => GlassPalette.mint,
  _Kind.payment => GlassPalette.amber,
  _Kind.habit => const Color(0xFFC2A8FF),
};

const Color _fridayRed = Color(0xFFFF9A9A);

/// Jalali month with a single glass lens that glides between days.
///
/// Layers: switcher capsule (shared backdrop group), detail panel (shared
/// backdrop group) and the lens (own layer + own backdrop so it magnifies the
/// day cells painted on the non-glass panel).
class MonthLensScreen extends StatefulWidget {
  const MonthLensScreen({super.key});

  @override
  State<MonthLensScreen> createState() => _MonthLensScreenState();
}

class _MonthLensScreenState extends State<MonthLensScreen> {
  static const double _cellH = 56;
  static const double _headH = 26;

  int _month = 1;
  int _day = 13;

  void _step(int delta) {
    final next = _month + delta;
    if (next < 0 || next >= _months.length) {
      return;
    }
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 54, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'تقویم',
                      style: glassText(36, weight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSwitcher(),
              ],
            ),
            const SizedBox(height: 14),
            _buildPanel(),
            const SizedBox(height: 12),
            _buildDetail(),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcher() {
    return GlassSection(
      child: SizedBox(
        width: 176,
        height: 46,
        child: GlassPiece(
          radius: 23,
          child: Row(
            children: <Widget>[
              _arrow(Icons.chevron_right_rounded, 'ماه قبل', -1),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[_month].name} ${fa('1405')}',
                    style: glassText(15, weight: FontWeight.w800),
                  ),
                ),
              ),
              _arrow(Icons.chevron_left_rounded, 'ماه بعد', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, String label, int delta) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _step(delta),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
            shadows: kTextShadow,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final info = _months[_month];
    return LayoutBuilder(
      builder: (context, box) {
        final inner = box.maxWidth - 16;
        final cw = inner / 7;
        Rect cellRect(int d) {
          final i = info.startCol + d - 1;
          return Rect.fromLTWH(
            inner - (i % 7 + 1) * cw,
            _headH + (i ~/ 7) * _cellH,
            cw,
            _cellH,
          );
        }

        final lensTarget = Rect.fromCenter(
          center: cellRect(_day).center,
          width: 58,
          height: 58,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x80070B1E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: inner,
              height: _headH + 6 * _cellH,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var c = 0; c < 7; c++)
                    Positioned.fromRect(
                      rect: Rect.fromLTWH(inner - (c + 1) * cw, 0, cw, _headH),
                      child: Center(
                        child: Text(
                          _weekdays[c],
                          style: glassText(
                            11,
                            opacity: 0.75,
                          ).copyWith(color: c == 6 ? _fridayRed : null),
                        ),
                      ),
                    ),
                  for (var d = 1; d <= 30; d++)
                    Positioned.fromRect(
                      rect: cellRect(d),
                      child: _DayCell(
                        key: ValueKey<String>('day-$d'),
                        day: d,
                        month: _month,
                        isFriday: (info.startCol + d - 1) % 7 == 6,
                        isToday: _month == 1 && d == 13,
                        selected: d == _day,
                        onTap: () => setState(() => _day = d),
                      ),
                    ),
                  LiquidFollower(
                    target: lensTarget,
                    builder: (context, rect) => LiquidGlass.withOwnLayer(
                      settings: allGlassSettings().copyWith(
                        refractionAmount: 95,
                      ),
                      appearance: const LiquidGlassAppearance.ios27RegularDark(
                        tint: Color(0x14FFFFFF),
                      ),
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: math.min(rect.width, rect.height) / 2,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    final items = _itemsFor(_month, _day);
    final info = _months[_month];
    final col = (info.startCol + _day - 1) % 7;
    final rows = math.max(items.length, 1);
    final height = 62.0 + rows * 30;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GlassSection(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: height),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, h, _) => SizedBox(
          height: math.max(h, 40),
          width: double.infinity,
          child: GlassPiece(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${fa('$_day')} ${info.name} · ${_weekdays[col]}',
                              style: glassText(16, weight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          items.isEmpty
                              ? 'آزاد'
                              : '${fa('${items.length}')} مورد',
                          style: glassText(12, opacity: 0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      SizedBox(
                        height: 30,
                        child: Text(
                          'برنامه‌ای برای این روز نیست',
                          style: glassText(14, opacity: 0.8),
                        ),
                      ),
                    for (final item in items)
                      SizedBox(
                        height: 30,
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kindColor(item.kind),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(item.text, style: glassText(14)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.isFriday,
    required this.isToday,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final int day;
  final int month;
  final bool isFriday;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = _months[month];
    final greg = DateTime.utc(
      2026,
      10,
      23,
    ).add(Duration(days: info.dayOffset + day - 1));
    final kinds = <_Kind>{for (final i in _itemsFor(month, day)) i.kind};
    final color = isFriday ? _fridayRed : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: DecoratedBox(
          decoration: isToday
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x80FFFFFF)),
                )
              : const BoxDecoration(),
          child: SizedBox(
            width: 42,
            height: 50,
            child: AnimatedScale(
              scale: selected ? 1.18 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    fa('$day'),
                    style: TextStyle(
                      fontFamily: kGlassFont,
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    fa('${greg.day}'),
                    style: TextStyle(
                      fontFamily: kGlassFont,
                      fontSize: 9.5,
                      height: 1.1,
                      color: color.withValues(alpha: 0.6),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final k in _Kind.values)
                          if (kinds.contains(k))
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kindColor(k),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
