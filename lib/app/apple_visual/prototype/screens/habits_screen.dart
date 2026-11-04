// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../all_glass_kit.dart';

class _Habit {
  _Habit({
    required this.name,
    required this.unit,
    required this.goal,
    required this.value,
    required this.streak,
    required this.icon,
    required this.history,
    this.missed = false,
  });

  final String name;
  final String unit;
  final int goal;
  int value;
  int streak;
  final IconData icon;
  final bool missed;

  /// Completion 0..1 for Aban 1..12; today (13) is derived from [value].
  final List<double> history;

  bool get done => value >= goal;
  double get frac => value / goal;
  Color get color => GlassPalette.turquoise;

  String get subtitle {
    if (goal == 1) {
      if (done) {
        return fa('انجام شد · $streak روز پیاپی');
      }
      return missed ? 'دیروز انجام نشد' : fa('$streak روز پیاپی');
    }
    return fa('$value از $goal $unit');
  }
}

/// «عادت‌ها»: glass habit capsules with liquid "drop" completion, and a Jalali
/// month heat-map for the selected habit on one big glass panel.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _Bead {
  _Bead(this.id, this.habit);
  final int id;
  final int habit;
}

class _HabitsScreenState extends State<HabitsScreen> {
  final List<_Habit> _habits = <_Habit>[
    _Habit(
      name: 'پیاده‌روی',
      unit: '',
      goal: 1,
      value: 0,
      streak: 12,
      icon: Icons.directions_walk_rounded,
      history: <double>[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ),
    _Habit(
      name: 'کتاب',
      unit: 'دقیقه',
      goal: 20,
      value: 15,
      streak: 4,
      icon: Icons.menu_book_rounded,
      history: <double>[0.5, 1, 0, 0.75, 1, 0.25, 1, 1, 0, 0.5, 1, 1],
    ),
    _Habit(
      name: 'آب',
      unit: 'لیوان',
      goal: 8,
      value: 4,
      streak: 2,
      icon: Icons.water_drop_rounded,
      history: <double>[
        0.5,
        0.625,
        0.75,
        0.5,
        1,
        0.875,
        0.375,
        1,
        0.75,
        0.625,
        1,
        0.875,
      ],
    ),
    _Habit(
      name: 'مدیتیشن',
      unit: '',
      goal: 1,
      value: 0,
      streak: 0,
      missed: true,
      icon: Icons.self_improvement_rounded,
      history: <double>[1, 0, 1, 1, 0, 0, 1, 0.0, 1, 1, 1, 0],
    ),
  ];

  int _selected = 0;
  int _beadId = 0;
  final List<_Bead> _beads = <_Bead>[];
  final Map<int, int> _pending = <int, int>{};

  void _complete(int i) {
    final h = _habits[i];
    final left = h.goal - h.value - (_pending[i] ?? 0);
    if (left <= 0) {
      return;
    }
    _pending[i] = (_pending[i] ?? 0) + 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _land(i);
      return;
    }
    setState(() => _beads.add(_Bead(_beadId++, i)));
  }

  void _land(int i, [_Bead? bead]) {
    setState(() {
      if (bead != null) {
        _beads.remove(bead);
      }
      _pending[i] = math.max(0, (_pending[i] ?? 1) - 1);
      final h = _habits[i];
      final step = h.goal == 1 ? 1 : (h.goal >= 20 ? 5 : 1);
      h.value = math.min(h.goal, h.value + step);
      if (h.goal == 1 && h.done) {
        h.streak += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habits[_selected];
    return DefaultTextStyle(
      style: glassText(14),
      child: BackdropGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 62, 16, 124),
          children: <Widget>[
            Text('عادت‌ها', style: glassText(36, weight: FontWeight.w800)),
            const SizedBox(height: 14),
            GlassSection(
              blend: 14,
              child: _HabitRows(
                habits: _habits,
                selected: _selected,
                beads: _beads,
                onSelect: (i) => setState(() => _selected = i),
                onComplete: _complete,
                onLand: _land,
              ),
            ),
            const SizedBox(height: 22),
            GlassSection(
              child: GlassPiece(
                radius: 34,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: _HeatPanel(habit: habit, index: _selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

const double _rowH = 84;
const double _rowGap = 12;
const double _btn = 60;
const double _btnGap = 10;
const double _padX = 18;

class _HabitRows extends StatelessWidget {
  const _HabitRows({
    required this.habits,
    required this.selected,
    required this.beads,
    required this.onSelect,
    required this.onComplete,
    required this.onLand,
  });

  final List<_Habit> habits;
  final int selected;
  final List<_Bead> beads;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onComplete;
  final void Function(int, [_Bead?]) onLand;

  @override
  Widget build(BuildContext context) {
    final noAnim = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final trackW = w - (_btn + _btnGap) - _padX * 2;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              children: <Widget>[
                for (var i = 0; i < habits.length; i++) ...<Widget>[
                  SizedBox(
                    height: _rowH,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(i),
                            child: GlassPiece(
                              radius: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: _padX,
                              ),
                              child: _RowBody(
                                habit: habits[i],
                                selected: i == selected,
                                noAnim: noAnim,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: _btnGap),
                        SizedBox(
                          width: _btn,
                          height: _btn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onComplete(i),
                            child: Semantics(
                              button: true,
                              label: 'انجام ${habits[i].name}',
                              child: GlassPiece(
                                circle: true,
                                child: Center(
                                  child: Icon(
                                    habits[i].done
                                        ? Icons.check_circle_rounded
                                        : (habits[i].goal == 1
                                              ? Icons.check_rounded
                                              : Icons.add_rounded),
                                    size: 28,
                                    color: habits[i].done
                                        ? GlassPalette.mint
                                        : Colors.white,
                                    shadows: kTextShadow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != habits.length - 1) const SizedBox(height: _rowGap),
                ],
              ],
            ),
            for (final b in beads)
              _BeadWidget(
                key: ValueKey<int>(b.id),
                from: Offset(_btn / 2, b.habit * (_rowH + _rowGap) + _rowH / 2),
                to: Offset(
                  w -
                      _padX -
                      trackW *
                          math.min(
                            1.0,
                            (habits[b.habit].value + _stepOf(habits[b.habit])) /
                                habits[b.habit].goal,
                          ),
                  b.habit * (_rowH + _rowGap) + _rowH - 17,
                ),
                onDone: () => onLand(b.habit, b),
              ),
          ],
        );
      },
    );
  }

  static int _stepOf(_Habit h) => h.goal == 1 ? 1 : (h.goal >= 20 ? 5 : 1);
}

class _RowBody extends StatelessWidget {
  const _RowBody({
    required this.habit,
    required this.selected,
    required this.noAnim,
  });

  final _Habit habit;
  final bool selected;
  final bool noAnim;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: <Widget>[
            AnimatedContainer(
              duration: noAnim
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.color.withValues(alpha: 0.9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: selected ? 0.95 : 0),
                  width: 2.4,
                ),
              ),
              child: Icon(habit.icon, size: 20, color: const Color(0xFF0B2E2A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    habit.name,
                    style: glassText(16, weight: FontWeight.w700, height: 1.2),
                  ),
                  Text(
                    habit.subtitle,
                    style: glassText(12, height: 1.2, opacity: 0.85).copyWith(
                      color: habit.missed && !habit.done
                          ? GlassPalette.amber
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: habit.frac),
          duration: noAnim ? Duration.zero : const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) =>
              GlassProgressTrack(value: v, color: GlassPalette.mint, height: 6),
        ),
      ],
    );
  }
}

/// A glass bead that splits off the button and merges into the row progress.
class _BeadWidget extends StatefulWidget {
  const _BeadWidget({
    required this.from,
    required this.to,
    required this.onDone,
    super.key,
  });

  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<_BeadWidget> createState() => _BeadWidgetState();
}

class _BeadWidgetState extends State<_BeadWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        // Swells while pinching off, shrinks as it is absorbed.
        final size = 12 + 14 * math.sin(math.pi * _c.value.clamp(0.0, 1.0));
        final p = Offset.lerp(widget.from, widget.to, t)!;
        final arc = -26 * math.sin(math.pi * t);
        return Positioned(
          left: p.dx - size / 2,
          top: p.dy + arc - size / 2,
          width: size,
          height: size,
          child: const GlassPiece(circle: true, child: SizedBox.expand()),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

const List<String> _weekdays = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

class _HeatPanel extends StatelessWidget {
  const _HeatPanel({required this.habit, required this.index});

  final _Habit habit;
  final int index;

  @override
  Widget build(BuildContext context) {
    final noAnim = MediaQuery.disableAnimationsOf(context);
    final values = <double>[...habit.history, habit.frac];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'آبان ۱۴۰۵ · ${habit.name}',
          style: glassText(17, weight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            for (final d in _weekdays)
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: glassText(12, opacity: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: noAnim ? Duration.zero : const Duration(milliseconds: 380),
          child: SizedBox(
            key: ValueKey<int>(index),
            height: _HeatPainter.rows * _HeatPainter.step,
            width: double.infinity,
            child: CustomPaint(painter: _HeatPainter(values)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('کمتر', style: glassText(11, opacity: 0.75)),
            const SizedBox(width: 8),
            for (final v in const <double>[0, 0.25, 0.5, 0.75, 1])
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _HeatPainter.ramp(v),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            const SizedBox(width: 8),
            Text('بیشتر', style: glassText(11, opacity: 0.75)),
          ],
        ),
      ],
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.values);

  /// Completion for days 1..13 (today is the last entry).
  final List<double> values;

  static const double step = 46;
  static const int rows = 6;
  static const int firstColumn = 6; // 1 Aban 1405 is a Friday (Sat = 0)
  static const int today = 13;

  static Color ramp(double v) {
    if (v <= 0) {
      return Colors.white.withValues(alpha: 0.12);
    }
    const dark = Color(0xFF14736B);
    const mid = Color(0xFF2FC4B0);
    const light = Color(0xFFA6FFE8);
    return v < 0.5
        ? Color.lerp(dark, mid, v * 2)!
        : Color.lerp(mid, light, (v - 0.5) * 2)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 40.0;
    final colW = size.width / 7;
    for (var day = 1; day <= 30; day++) {
      final slot = firstColumn + day - 1;
      final col = slot % 7;
      final row = slot ~/ 7;
      final cx = size.width - (col + 0.5) * colW; // RTL: Saturday on the right
      final cy = row * step + step / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: cell, height: cell),
        const Radius.circular(13),
      );
      final future = day > today;
      final v = future ? 0.0 : values[day - 1];
      if (future) {
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.2),
        );
      } else {
        canvas.drawRRect(rect, Paint()..color = ramp(v));
      }
      if (day == today) {
        canvas.drawRRect(
          rect.inflate(3.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = Colors.white,
        );
      }
      final dark = v > 0.7;
      final tp = TextPainter(
        text: TextSpan(
          text: fa('$day'),
          style: TextStyle(
            fontFamily: kGlassFont,
            fontSize: 12,
            fontWeight: day == today ? FontWeight.w800 : FontWeight.w500,
            color: dark
                ? const Color(0xFF063B36)
                : Colors.white.withValues(alpha: future ? 0.55 : 0.92),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) {
    if (old.values.length != values.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) {
        return true;
      }
    }
    return false;
  }
}
