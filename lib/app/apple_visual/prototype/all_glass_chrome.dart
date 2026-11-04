// SPIKE EXCEPTION: see all_glass_kit.dart.
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'all_glass_kit.dart';

const List<(String, IconData)> kAllGlassTabs = <(String, IconData)>[
  ('امروز', Icons.today_rounded),
  ('کارها', Icons.task_alt_rounded),
  ('پول', Icons.account_balance_wallet_rounded),
  ('عادت‌ها', Icons.local_fire_department_rounded),
];

/// Top bar + floating tab bar + «+» button: ONE glass layer (6 shapes) that
/// shares one backdrop with the rest of the root chrome.
class AllGlassChrome extends StatelessWidget {
  const AllGlassChrome({
    required this.fake,
    required this.tab,
    required this.onTab,
    required this.onAdd,
    required this.topInset,
    required this.bottomInset,
    required this.showAdd,
    super.key,
  });

  final bool fake;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;
  final double topInset;
  final double bottomInset;
  final bool showAdd;

  static const double barH = 66;

  @override
  Widget build(BuildContext context) {
    return GlassSection(
      fake: fake,
      blend: 14,
      child: Stack(
        children: <Widget>[
          PositionedDirectional(
            start: 16,
            end: 16,
            top: topInset,
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GlassIconButton(
                  icon: Icons.person_rounded,
                  label: 'پروفایل',
                  onTap: () {},
                ),
                SizedBox(
                  width: 112,
                  height: 40,
                  child: GlassPiece(
                    radius: 20,
                    child: Center(
                      child: Text(
                        kAllGlassTabs[tab].$1,
                        style: glassText(14, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                GlassIconButton(
                  icon: Icons.notifications_rounded,
                  label: 'اعلان‌ها',
                  onTap: () {},
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: bottomInset + 12,
            height: barH,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GlassPiece(
                    radius: barH / 2,
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: <Widget>[
                        for (var i = 0; i < kAllGlassTabs.length; i++)
                          Expanded(
                            child: _TabItem(
                              label: kAllGlassTabs[i].$1,
                              icon: kAllGlassTabs[i].$2,
                              selected: i == tab,
                              onTap: () => onTab(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GlassIconButton(
                  icon: Icons.search_rounded,
                  label: 'جست‌وجو',
                  size: barH,
                  onTap: () {},
                ),
              ],
            ),
          ),
          if (showAdd)
            PositionedDirectional(
              end: 16,
              bottom: bottomInset + 12 + barH + 14,
              child: GlassIconButton(
                icon: Icons.add_rounded,
                label: 'افزودن',
                size: 58,
                onTap: onAdd,
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          // Selection indicator is a plain tinted capsule, not glass.
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 22, color: Colors.white, shadows: kTextShadow),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: glassText(
                  10.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass bottom sheet «کار جدید». Panel layer + form layer (field, chips and
/// buttons) sit in one LiquidGlassCapture so the form refracts the panel
/// without two screen-size backdrop reads.
class AllGlassSheet extends StatelessWidget {
  const AllGlassSheet({
    required this.fake,
    required this.onClose,
    required this.bottomInset,
    super.key,
  });

  final bool fake;
  final VoidCallback onClose;
  final double bottomInset;

  static const List<(String, IconData)> _chips = <(String, IconData)>[
    ('امروز ۱۸:۰۰', Icons.schedule_rounded),
    ('۳۰ دقیقه قبل', Icons.notifications_active_rounded),
    ('تکرار', Icons.repeat_rounded),
    ('اولویت', Icons.flag_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Color(0x59000000)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: reduce ? 0 : 1, end: 0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) =>
                FractionalTranslation(translation: Offset(0, t), child: child),
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
              child: SizedBox(
                height: 372,
                child: LiquidGlassCapture(
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: GlassSection(
                          fake: fake,
                          backdropGroup: false,
                          child: const GlassPiece(
                            radius: 40,
                            child: SizedBox.expand(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: GlassSection(
                          fake: fake,
                          backdropGroup: false,
                          settings: allGlassSettings().copyWith(
                            refractionHeight: 16,
                            frost: 2,
                          ),
                          child: _SheetForm(onClose: onClose),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetForm extends StatelessWidget {
  const _SheetForm({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('کار جدید', style: glassText(24, weight: FontWeight.w800)),
        const SizedBox(height: 14),
        SizedBox(
          height: 58,
          child: GlassPiece(
            radius: 29,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                style: glassText(16),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'چه کاری باید انجام شود؟',
                  hintStyle: glassText(16, opacity: 0.6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: <Widget>[
            for (final c in AllGlassSheet._chips)
              SizedBox(
                height: 42,
                child: IntrinsicWidth(
                  child: GlassPiece(
                    radius: 21,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: <Widget>[
                        Icon(c.$2, size: 17, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          c.$1,
                          style: glassText(13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 54,
                  child: GlassPiece(
                    radius: 27,
                    child: Center(
                      child: Text(
                        'انصراف',
                        style: glassText(16, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 54,
                  child: GlassPiece(
                    radius: 27,
                    child: Center(
                      child: Text(
                        'افزودن کار',
                        style: glassText(16, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
