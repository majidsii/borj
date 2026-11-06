import 'dart:math' as math;

import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/core/money/money.dart';
import 'package:borj/features/dashboard/presentation/widgets/finance_preview_models.dart'
    show FinancePreviewMath;
import 'package:borj/features/finance/application/finance_summary.dart';
import 'package:flutter/material.dart';

final class FinanceTrendChart extends StatelessWidget {
  const FinanceTrendChart({required this.points, super.key});

  final List<FinanceMonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return SizedBox(
      key: const ValueKey<String>('finance-trend-chart'),
      height: 252,
      child: CustomPaint(
        painter: _TrendPainter(points: points, palette: palette),
        child: const SizedBox.expand(),
      ),
    );
  }
}

final class FinanceDonutChart extends StatelessWidget {
  const FinanceDonutChart({
    required this.points,
    required this.currentMonthOnly,
    super.key,
  });

  final List<FinanceCategoryPoint> points;
  final bool currentMonthOnly;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final total = points.fold<Money>(
      Money.zeroIRT,
      (sum, point) => sum + point.value,
    );
    final colors = _categoryColors(palette);

    return Column(
      key: const ValueKey<String>('finance-donut-chart'),
      children: <Widget>[
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: SizedBox(
                  width: 240,
                  height: 200,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      points: points,
                      colors: colors,
                      palette: palette,
                    ),
                  ),
                ),
              ),
              if (total.isZero)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    currentMonthOnly
                        ? 'در این ماه هزینه‌ای ثبت نشده'
                        : 'هنوز هزینه‌ای ثبت نشده',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.faint,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (total.isPositive) ...<Widget>[
          const SizedBox(height: 2),
          ...points.indexed.map((entry) {
            final color = colors[entry.$1 % colors.length];
            final percentage = total.isPositive
                ? entry.$2.value.percentOf(total)
                : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      entry.$2.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${FinancePreviewMath.money(entry.$2.value)} تومان',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '٪${FinancePreviewMath.fa(percentage)}',
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: palette.faint,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

final class FinanceWeekChart extends StatelessWidget {
  const FinanceWeekChart({required this.points, super.key});

  final List<FinanceDayPoint> points;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final hasData = points.any((point) => point.value.isPositive);
    return SizedBox(
      key: const ValueKey<String>('finance-week-chart'),
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            painter: _WeekPainter(points: points, palette: palette),
            child: const SizedBox.expand(),
          ),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'در ۷ روز اخیر هزینه‌ای ثبت نشده',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.faint,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points, required this.palette});

  final List<FinanceMonthPoint> points;
  final OriginalPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 90 || size.height <= 90) return;

    const left = 52.0;
    final right = size.width - 16;
    const top = 18.0;
    final bottom = size.height - 40;
    final plot = Rect.fromLTRB(left, top, right, bottom);
    final maximum = points.fold<int>(
      0,
      (value, point) => math.max(
        value,
        math.max(point.income.minorUnits, point.expense.minorUnits),
      ),
    );
    final scaleTop = _niceMaximum(maximum);

    for (var index = 0; index <= 4; index++) {
      final y = bottom - plot.height * index / 4;
      if (index == 0) {
        canvas.drawLine(
          Offset(left, y),
          Offset(right, y),
          Paint()
            ..color = palette.line
            ..strokeWidth = 1.4,
        );
      } else {
        _drawDashedLine(
          canvas,
          Offset(left, y),
          Offset(right, y),
          Paint()
            ..color = palette.line
            ..strokeWidth = 1,
        );
      }
      _drawText(
        canvas,
        FinancePreviewMath.compact(
          Money(
            minorUnits: (scaleTop * index / 4).round(),
            currencyCode: Money.tomanCurrencyCode,
            scale: Money.financeScale,
          ),
        ),
        Offset(left - 8, y + 4),
        color: palette.faint,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        anchor: _TextAnchor.end,
      );
    }

    final incomePoints = <Offset>[];
    final expensePoints = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? plot.center.dx
          : left + plot.width * index / (points.length - 1);
      double y(Money value) =>
          bottom - plot.height * value.minorUnits / scaleTop;
      incomePoints.add(Offset(x, y(points[index].income)));
      expensePoints.add(Offset(x, y(points[index].expense)));

      _drawText(
        canvas,
        points[index].label,
        Offset(x, size.height - 16),
        color: palette.faint,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        anchor: _TextAnchor.center,
      );
    }

    _drawSeries(
      canvas,
      points: expensePoints,
      color: palette.expense,
      plot: plot,
    );
    _drawSeries(
      canvas,
      points: incomePoints,
      color: palette.income,
      plot: plot,
    );
  }

  void _drawSeries(
    Canvas canvas, {
    required List<Offset> points,
    required Color color,
    required Rect plot,
  }) {
    final line = _smoothPath(points);
    final area = Path.from(line)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: .28),
            color.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.palette != palette;
  }
}

final class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.points,
    required this.colors,
    required this.palette,
  });

  final List<FinanceCategoryPoint> points;
  final List<Color> colors;
  final OriginalPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 66.0;
    const strokeWidth = 24.0;
    final total = points.fold<Money>(
      Money.zeroIRT,
      (sum, point) => sum + point.value,
    );
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total.isZero) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = palette.track
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    var start = -math.pi / 2;
    final gap = points.length > 1 ? .055 : 0.0;
    for (var index = 0; index < points.length; index++) {
      final sweep =
          points[index].value.minorUnits / total.minorUnits * math.pi * 2;
      final visibleSweep = math.max(.012, sweep - gap);
      canvas.drawArc(
        rect,
        start + gap / 2,
        visibleSweep,
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = points.length > 1 ? StrokeCap.round : StrokeCap.butt,
      );
      start += sweep;
    }

    _drawText(
      canvas,
      FinancePreviewMath.compact(total),
      Offset(center.dx, center.dy - 3),
      color: palette.ink,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      anchor: _TextAnchor.center,
    );
    _drawText(
      canvas,
      'تومان',
      Offset(center.dx, center.dy + 16),
      color: palette.faint,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      anchor: _TextAnchor.center,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colors != colors ||
        oldDelegate.palette != palette;
  }
}

final class _WeekPainter extends CustomPainter {
  const _WeekPainter({required this.points, required this.palette});

  final List<FinanceDayPoint> points;
  final OriginalPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 14.0;
    final right = size.width - 14;
    const top = 16.0;
    final bottom = size.height - 34;
    final maximum = points.fold<int>(
      0,
      (value, point) => math.max(value, point.value.minorUnits),
    );
    final scaleTop = _niceMaximum(maximum);

    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      Paint()
        ..color = palette.line
        ..strokeWidth = 1.4,
    );

    final slot = (right - left) / points.length;
    final barWidth = math.min(26.0, slot * .52);
    final barRect = Rect.fromLTRB(left, top, right, bottom);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[palette.accent, palette.accent2.withValues(alpha: .55)],
    ).createShader(barRect);

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = left + slot * index + slot / 2;
      var height = maximum == 0
          ? 0.0
          : (bottom - top) * point.value.minorUnits / scaleTop;
      if (point.value.isPositive && height < 4) height = 4;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          bottom - height,
          barWidth,
          height,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = point.isToday
              ? Colors.white
              : palette.faint.withValues(alpha: .5)
          ..shader = point.isToday ? gradient : null,
      );
      _drawText(
        canvas,
        point.label,
        Offset(centerX, size.height - 14),
        color: point.isToday ? palette.ink : palette.faint,
        fontSize: 11.5,
        fontWeight: point.isToday ? FontWeight.w800 : FontWeight.w600,
        anchor: _TextAnchor.center,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeekPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.palette != palette;
  }
}

List<Color> _categoryColors(OriginalPalette palette) {
  return <Color>[
    palette.expense,
    palette.amber,
    palette.violet,
    palette.accent,
    palette.income,
    const Color(0xFFFF6B9A),
    const Color(0xFF64D2FF),
    const Color(0xFFFFD60A),
  ];
}

double _niceMaximum(int value) {
  if (value <= 0) {
    return 4 * 100000000;
  }
  final power = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  final normalized = value / power;
  final multiplier = switch (normalized) {
    <= 1 => 1.0,
    <= 2 => 2.0,
    <= 2.5 => 2.5,
    <= 4 => 4.0,
    <= 5 => 5.0,
    <= 8 => 8.0,
    _ => 10.0,
  };
  return multiplier * power;
}

Path _smoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) return path;
  for (var index = 0; index < points.length - 1; index++) {
    final p0 = points[math.max(0, index - 1)];
    final p1 = points[index];
    final p2 = points[index + 1];
    final p3 = points[math.min(points.length - 1, index + 2)];
    final control1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
    );
    final control2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
    );
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      p2.dx,
      p2.dy,
    );
  }
  return path;
}

void _drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dash = 3,
  double gap = 5,
}) {
  final distance = (end - start).distance;
  final direction = (end - start) / distance;
  var offset = 0.0;
  while (offset < distance) {
    final segmentEnd = math.min(offset + dash, distance);
    canvas.drawLine(
      start + direction * offset,
      start + direction * segmentEnd,
      paint,
    );
    offset += dash + gap;
  }
}

enum _TextAnchor { start, center, end }

void _drawText(
  Canvas canvas,
  String value,
  Offset position, {
  required Color color,
  required double fontSize,
  required FontWeight fontWeight,
  required _TextAnchor anchor,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontFamily: 'Vazirmatn',
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  final dx = switch (anchor) {
    _TextAnchor.start => position.dx,
    _TextAnchor.center => position.dx - painter.width / 2,
    _TextAnchor.end => position.dx - painter.width,
  };
  painter.paint(canvas, Offset(dx, position.dy - painter.height));
}
