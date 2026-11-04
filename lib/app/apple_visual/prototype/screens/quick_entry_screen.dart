// SPIKE EXCEPTION: see ../all_glass_kit.dart (direct liquid_glass_renderer use).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../all_glass_kit.dart';
import 'glass_d_common.dart';
import 'quick_entry_parser.dart';

/// «ورود سریع»: natural Persian quick entry. Recognised tokens pop out of the
/// glass command field as chips that liquid-separate from it (same blend
/// layer) and merge back when the token is deleted.
///
/// Layers: 3 GlassSections (field+chips, result card, examples) sharing one
/// BackdropGroup, so one backdrop capture.
class QuickEntryScreen extends StatefulWidget {
  const QuickEntryScreen({super.key});

  @override
  State<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _Live {
  _Live(this.token, this.controller, this.origin);

  QuickToken token;
  final AnimationController controller;
  final Rect origin;
  bool exiting = false;
}

const double _fieldH = 60;
const double _chipH = 38;
const double _chipGap = 8;

const List<String> _examples = <String>[
  'ناهار با علی ۴۵۰ تومن از کارت ملت',
  'فردا ساعت ۱۰ دندانپزشکی',
  'هر ماه پنجم اجاره ۱۲ میلیون',
  '۲۰ دقیقه کتاب خواندم',
];

class _QuickEntryScreenState extends State<QuickEntryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _text = TextEditingController();
  final List<_Live> _live = <_Live>[];
  final List<AnimationController> _dead = <AnimationController>[];
  QuickEntry _entry = parseQuickEntry('');
  String? _saved;
  double _fieldWidth = 340;

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _text.addListener(_sync);
  }

  @override
  void dispose() {
    _text.dispose();
    for (final l in _live) {
      l.controller.dispose();
    }
    for (final c in _dead) {
      c.dispose();
    }
    super.dispose();
  }

  Rect _originFor(QuickToken t) {
    final len = math.max(1, _text.text.length);
    final frac = ((t.start + t.end) / 2) / len;
    final cx = _fieldWidth - 52 - frac * (_fieldWidth - 104);
    return Rect.fromCenter(
      center: Offset(cx, _fieldH / 2),
      width: 36,
      height: 22,
    );
  }

  void _sync() {
    final entry = parseQuickEntry(_text.text);
    final keys = <String>{};
    for (final t in entry.tokens) {
      if (!keys.add(t.key)) {
        continue;
      }
      final existing = _live.where((l) => l.token.key == t.key);
      if (existing.isNotEmpty) {
        final l = existing.first..token = t;
        if (l.exiting) {
          l.exiting = false;
          _run(l, forward: true);
        }
      } else {
        final c = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 560),
        );
        final l = _Live(t, c, _originFor(t));
        _live.add(l);
        _run(l, forward: true);
      }
    }
    for (final l in List<_Live>.of(_live)) {
      if (!keys.contains(l.token.key) && !l.exiting) {
        l.exiting = true;
        _run(l, forward: false);
      }
    }
    setState(() {
      _entry = entry;
      if (!entry.isEmpty) {
        _saved = null;
      }
    });
  }

  void _run(_Live l, {required bool forward}) {
    if (_reduced) {
      l.controller.value = forward ? 1 : 0;
      if (!forward) {
        _drop(l);
      }
      return;
    }
    if (forward) {
      l.controller.forward();
    } else {
      l.controller.reverse().whenCompleteOrCancel(() {
        if (mounted && l.exiting) {
          _drop(l);
          setState(() {});
        }
      });
    }
  }

  void _drop(_Live l) {
    // Disposed with the state: the merged AnimatedBuilder may still hold it.
    _live.remove(l);
    _dead.add(l.controller);
  }

  void _removeToken(QuickToken t) {
    final s = _text.text;
    if (t.end > s.length) {
      return;
    }
    final next = s.replaceRange(t.start, t.end, '').replaceAll('  ', ' ');
    _text.value = TextEditingValue(
      text: next.trim(),
      selection: TextSelection.collapsed(offset: next.trim().length),
    );
  }

  void _fill(String s) {
    HapticFeedback.selectionClick();
    _text.value = TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }

  void _submit() {
    if (_entry.isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    final label = '${quickKindLabel(_entry.kind)} · ${_entry.title}';
    _text.clear();
    setState(() => _saved = label);
  }

  static Color _typeColor(QuickTokenType t) => switch (t) {
    QuickTokenType.amount => GlassPalette.mint,
    QuickTokenType.date => GlassPalette.amber,
    QuickTokenType.time => GlassPalette.saffron,
    QuickTokenType.recurrence => const Color(0xFFC9B2FF),
    QuickTokenType.category => GlassPalette.turquoise,
    QuickTokenType.account => const Color(0xFF9DB4FF),
    QuickTokenType.duration => const Color(0xFFFFB4BF),
  };

  static IconData _typeIcon(QuickTokenType t) => switch (t) {
    QuickTokenType.amount => Icons.payments_rounded,
    QuickTokenType.date => Icons.event_rounded,
    QuickTokenType.time => Icons.schedule_rounded,
    QuickTokenType.recurrence => Icons.repeat_rounded,
    QuickTokenType.category => Icons.sell_rounded,
    QuickTokenType.account => Icons.credit_card_rounded,
    QuickTokenType.duration => Icons.timer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: glassText(14),
      child: BackdropGroup(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 62, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('ورود سریع', style: glassText(36, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'بنویس؛ هر تکه از جمله به یک چیپ شیشه‌ای تبدیل می‌شود.',
                style: glassText(13, opacity: 0.8),
              ),
              const SizedBox(height: 14),
              GlassSection(blend: 14, child: _buildMorph()),
              const SizedBox(height: 14),
              GlassSection(
                child: Column(
                  children: <Widget>[
                    _buildResultCard(),
                    kGap10,
                    _buildSubmit(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('نمونه‌ها', style: glassText(20, weight: FontWeight.w700)),
              kGap10,
              GlassSection(
                child: Column(
                  children: <Widget>[
                    for (final e in _examples) ...<Widget>[
                      _buildExample(e),
                      kGap10,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMorph() {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        _fieldWidth = w;
        final ordered = List<_Live>.of(_live)
          ..sort((a, b) => a.token.start.compareTo(b.token.start));
        // Flow the chips RTL (start = right edge) into rows below the field.
        final slots = <_Live, Rect>{};
        var x = w;
        var row = 0;
        for (final l in ordered) {
          final cw = math.min(w, 44.0 + l.token.label.runes.length * 8.4);
          if (x - cw < 0 && x != w) {
            row++;
            x = w;
          }
          final top = _fieldH + 14 + row * (_chipH + _chipGap);
          slots[l] = Rect.fromLTWH(x - cw, top, cw, _chipH);
          x -= cw + _chipGap;
        }
        final rows = ordered.isEmpty ? 0 : row + 1;
        final height =
            _fieldH + (rows == 0 ? 0 : 14 + rows * (_chipH + _chipGap) - 4);
        return AnimatedContainer(
          duration: _reduced
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: height,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              for (final l in ordered) l.controller,
            ]),
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: w,
                    height: _fieldH,
                    child: _buildField(),
                  ),
                  for (final l in ordered) _buildChip(l, slots[l]!),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildField() {
    return TintedGlass(
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            color: GlassPalette.amber,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _text,
              textDirection: TextDirection.rtl,
              cursorColor: Colors.white,
              style: glassText(17, weight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'مثلاً: ناهار ۴۵۰ تومن',
                hintStyle: glassText(16, opacity: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned _buildChip(_Live l, Rect slot) {
    final c = l.controller.value;
    final p = Curves.easeOutBack.transform(c);
    final pos = Curves.easeOutCubic.transform(c);
    final topLeft = Offset.lerp(l.origin.topLeft, slot.topLeft, pos)!;
    final size = Size.lerp(l.origin.size, slot.size, p.clamp(0.0, 1.2))!;
    final color = _typeColor(l.token.type);
    return Positioned(
      key: ValueKey<String>(l.token.key),
      left: topLeft.dx,
      top: topLeft.dy,
      width: math.max(1, size.width),
      height: math.max(1, size.height),
      child: GestureDetector(
        onTap: () => _removeToken(l.token),
        behavior: HitTestBehavior.opaque,
        child: TintedGlass(
          radius: 19,
          tint: color.withValues(alpha: 0.30),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Opacity(
            opacity: c.clamp(0.0, 1.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_typeIcon(l.token.type), size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    l.token.label,
                    style: glassText(13.5, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(k, style: glassText(13.5, opacity: 0.75)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: glassText(14.5, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final e = _entry;
    final rows = <Widget>[
      if (e.amountToman != null)
        _kv('مبلغ', '${faGrouped(e.amountToman!)} تومان', GlassPalette.mint),
      if (e.category != null) _kv('دسته', e.category!, GlassPalette.turquoise),
      if (e.account != null) _kv('حساب', e.account!, const Color(0xFF9DB4FF)),
      if (e.dateLabel != null) _kv('تاریخ', e.dateLabel!, GlassPalette.amber),
      if (e.timeLabel != null) _kv('ساعت', e.timeLabel!, GlassPalette.saffron),
      if (e.recurrenceLabel != null)
        _kv('تکرار', e.recurrenceLabel!, const Color(0xFFC9B2FF)),
      if (e.durationMinutes != null)
        _kv(
          'مدت',
          faDigits('${e.durationMinutes} دقیقه'),
          const Color(0xFFFFB4BF),
        ),
    ];
    return TintedGlass(
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: AnimatedSize(
        duration: _reduced ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: e.isEmpty
              ? Text(
                  _saved == null
                      ? 'تفسیر جمله اینجا ساخته می‌شود.'
                      : 'ثبت شد · $_saved',
                  style: glassText(
                    14.5,
                    weight: _saved == null ? FontWeight.w500 : FontWeight.w700,
                    opacity: _saved == null ? 0.7 : 1,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GlassPalette.amber.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            quickKindLabel(e.kind),
                            style: glassText(13, weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.title.isEmpty ? '—' : e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: glassText(16.5, weight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    ...rows,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubmit() {
    final enabled = !_entry.isEmpty;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'ثبت',
      child: GestureDetector(
        onTap: _submit,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: TintedGlass(
            radius: 27,
            tint: (enabled ? GlassPalette.turquoise : Colors.grey).withValues(
              alpha: enabled ? 0.55 : 0.2,
            ),
            child: Center(
              child: Text(
                'ثبت',
                style: glassText(
                  17,
                  weight: FontWeight.w800,
                  opacity: enabled ? 1 : 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExample(String s) {
    return GestureDetector(
      onTap: () => _fill(s),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: TintedGlass(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: GlassPalette.amber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassText(14.5, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
