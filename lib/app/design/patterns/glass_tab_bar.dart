import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/app_icon.dart';
import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/design/patterns/sliding_lens.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/shell/shell_destinations.dart';
import 'package:flutter/material.dart';

/// The phone's floating tab bar (boards `Main`, `PhoneTasks`, `PhoneMoney`):
/// a glass capsule 62 tall with one item per destination and a flat lens on
/// the selected one, plus a 62 pt glass search circle on its leading side
/// (left in RTL). Build it inside the shell's chrome `GlassScope`.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSearch,
    super.key,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;

  static const double height = 62;
  static const double _padding = 4;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Expanded(
          child: AppGlass(
            key: const ValueKey('tab-bar'),
            role: GlassRole.chrome,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / destinations.length;
                    final logical = isRtl
                        ? constraints.maxWidth - (selectedIndex + 1) * itemWidth
                        : selectedIndex * itemWidth;
                    return Stack(
                      children: [
                        SlidingLens(
                          key: const ValueKey('tab-lens'),
                          target: Rect.fromLTWH(
                            logical,
                            0,
                            itemWidth,
                            height - 2 * _padding,
                          ),
                          axis: Axis.horizontal,
                          shape: const AppleGlassShape.capsule(),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: _Tab(
                                  destination: destinations[i],
                                  selected: i == selectedIndex,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          key: const ValueKey('tab-search'),
          width: height,
          height: height,
          child: Pressable(
            onPressed: onSearch,
            semanticLabel: 'جست‌وجو',
            dimsGlass: true,
            child: const AppGlass(
              role: GlassRole.chrome,
              shape: AppleGlassShape.circle(),
              child: Center(child: AppIcon(Icons.search, size: 24)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = selected ? AppTextTone.link : AppTextTone.primary;
    // The keyed Semantics container is the node the key resolves to; Pressable's
    // button semantics merge into it.
    return Semantics(
      key: ValueKey('tab-${destination.section.name}'),
      container: true,
      child: Pressable(
        selected: selected,
        onPressed: onTap,
        semanticLabel: destination.label,
        child: SizedBox(
          // Pressable's Stack loosens width; fill the cell so content centres.
          width: double.infinity,
          height: GlassTabBar.height - 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(destination.icon, size: 24, tone: tone),
              const SizedBox(height: 1),
              AppText(
                destination.label,
                role: AppTextRole.caption2,
                tone: tone,
                weight: FontWeight.w800,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
