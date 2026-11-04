// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'all_glass_chrome.dart';
import 'all_glass_kit.dart';
import 'all_glass_money.dart';
import 'all_glass_today.dart';
import 'all_glass_wallpaper.dart';

/// Debug-only "everything is Liquid Glass" mobile prototype (RTL, Persian).
///
/// Layering per screen: scrolling content sections share one BackdropGroup
/// (one backdrop read); the root chrome (top bar, tab bar, +) is a second
/// group above it; the sheet has its own captures.
class AllGlassPrototype extends StatelessWidget {
  const AllGlassPrototype({this.fakeGlass = false, super.key});

  /// Force FakeGlass (tests, platforms without Impeller shader filters).
  final bool fakeGlass;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFF05060F),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 500;
            final app = _AllGlassApp(fake: fakeGlass, framed: wide);
            if (!wide) {
              return app;
            }
            final h = math.min(844.0, c.maxHeight - 24);
            return Center(
              child: Container(
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
                    child: app,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AllGlassApp extends StatefulWidget {
  const _AllGlassApp({required this.fake, required this.framed});

  final bool fake;
  final bool framed;

  @override
  State<_AllGlassApp> createState() => _AllGlassAppState();
}

class _AllGlassAppState extends State<_AllGlassApp> {
  int _tab = 0;
  bool _sheet = false;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = widget.framed ? 52.0 : mq.padding.top + 8;
    final bottomInset = widget.framed ? 18.0 : mq.padding.bottom;
    final topPad = topInset + 46 + 14;
    final bottomPad = bottomInset + 12 + AllGlassChrome.barH + 90;
    final sections = switch (_tab) {
      0 => buildTodaySections(fake: widget.fake),
      2 => buildMoneySections(fake: widget.fake),
      _ => <Widget>[_Placeholder(title: kAllGlassTabs[_tab].$1)],
    };
    return DefaultTextStyle(
      style: glassText(14),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: AllGlassWallpaper()),
          Positioned.fill(
            child: BackdropGroup(
              child: CustomScrollView(
                key: ValueKey<int>(_tab),
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, topPad, 16, bottomPad),
                    sliver: SliverList.list(children: sections),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropGroup(
              child: AllGlassChrome(
                fake: widget.fake,
                tab: _tab,
                onTab: (i) => setState(() => _tab = i),
                onAdd: () => setState(() => _sheet = true),
                topInset: topInset,
                bottomInset: bottomInset,
                showAdd: !_sheet,
              ),
            ),
          ),
          if (_sheet)
            Positioned.fill(
              child: AllGlassSheet(
                fake: widget.fake,
                bottomInset: bottomInset,
                onClose: () => setState(() => _sheet = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: glassText(36, weight: FontWeight.w800)),
        kGap10,
        GlassSection(
          fake: false,
          child: SizedBox(
            height: 90,
            child: GlassPiece(
              radius: 34,
              child: Center(
                child: Text(
                  'این صفحه در نمونهٔ اولیه نیست',
                  style: glassText(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
