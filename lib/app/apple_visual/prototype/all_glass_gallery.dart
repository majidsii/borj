// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'all_glass_kit.dart';
import 'all_glass_prototype.dart';
import 'all_glass_wallpaper.dart';
import 'screens/envelopes_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/month_lens_screen.dart';
import 'screens/quick_entry_screen.dart';
import 'screens/rings_screen.dart';
import 'screens/season_forecast_screen.dart';
import 'screens/wallet_stack_screen.dart';

/// One entry of the all-glass gallery.
class _Entry {
  const _Entry(this.title, this.builder);

  final String title;
  final Widget Function(bool framed) builder;
}

Widget _onWallpaper(Widget screen) => Stack(
  children: <Widget>[
    const Positioned.fill(child: AllGlassWallpaper()),
    Positioned.fill(child: screen),
  ],
);

final List<_Entry> _entries = <_Entry>[
  _Entry(
    'امروز و پول',
    (framed) => AllGlassHomeApp(fake: false, framed: framed),
  ),
  _Entry('خلاصه', (_) => _onWallpaper(const RingsScreen())),
  _Entry('کیف پول', (_) => _onWallpaper(const WalletStackScreen())),
  _Entry('پاکت‌ها', (_) => _onWallpaper(const EnvelopesScreen())),
  _Entry('عادت‌ها', (_) => _onWallpaper(const HabitsScreen())),
  _Entry('تقویم', (_) => _onWallpaper(const MonthLensScreen())),
  _Entry('تمرکز', (_) => _onWallpaper(const FocusTimerScreen())),
  _Entry('ورود سریع', (_) => _onWallpaper(const QuickEntryScreen())),
  _Entry('فصل', (_) => _onWallpaper(const SeasonForecastScreen())),
];

/// Debug-only gallery of all-glass prototype screens.
///
/// Wide windows: a phone frame with a screen list beside it.
/// Narrow screens (a real phone): full screen with a small glass menu button.
class AllGlassGallery extends StatefulWidget {
  const AllGlassGallery({super.key});

  @override
  State<AllGlassGallery> createState() => _AllGlassGalleryState();
}

class _AllGlassGalleryState extends State<AllGlassGallery> {
  int _index = 0;
  bool _menu = false;

  void _select(int i) => setState(() {
    _index = i;
    _menu = false;
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFF05060F),
        child: DefaultTextStyle(
          style: glassText(14),
          child: LayoutBuilder(
            builder: (context, c) =>
                c.maxWidth > 700 ? _wide(context, c) : _narrow(context),
          ),
        ),
      ),
    );
  }

  Widget _screen(bool framed) => KeyedSubtree(
    key: ValueKey<int>(_index),
    child: _entries[_index].builder(framed),
  );

  Widget _wide(BuildContext context, BoxConstraints c) {
    final h = math.min(844.0, c.maxHeight - 24);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(width: 220, child: _list()),
        const SizedBox(width: 40),
        Container(
          width: 390,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: const Color(0xFF2A2D3E), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(size: Size(390, h), padding: EdgeInsets.zero),
              child: _screen(true),
            ),
          ),
        ),
        const SizedBox(width: 260),
      ],
    );
  }

  Widget _list() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, bottom: 12),
          child: Text(
            'نمایشگاه شیشه',
            style: glassText(20, weight: FontWeight.w800),
          ),
        ),
        for (var i = 0; i < _entries.length; i++)
          _ListButton(
            title: _entries[i].title,
            selected: i == _index,
            onTap: () => _select(i),
          ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _screen(false)),
        if (_menu)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _menu = false),
              child: ColoredBox(
                color: const Color(0xCC05060F),
                child: Center(child: SizedBox(width: 260, child: _list())),
              ),
            ),
          ),
        PositionedDirectional(
          top: top + 4,
          end: 12,
          child: Semantics(
            button: true,
            label: 'فهرست صفحه‌ها',
            child: GestureDetector(
              onTap: () => setState(() => _menu = !_menu),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x55000000),
                  border: Border.all(color: const Color(0x88FFFFFF)),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListButton extends StatelessWidget {
  const _ListButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0x33FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              title,
              style: glassText(
                16,
                weight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
