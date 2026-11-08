import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const String _hint = 'جست‌وجو';

const Widget _soon = EmptyState(
  icon: Icons.search,
  title: 'جست‌وجو به‌زودی',
  message: 'جست‌وجوی کارها و تراکنش‌ها در مرحلهٔ خودش ساخته می‌شود',
);

/// The compact search page (`/search`, pushed as a `GlassPushPage`): a back
/// circle, a focused field and the "coming soon" state. Search itself ships in
/// its own phase.
class SearchShellScreen extends StatefulWidget {
  const SearchShellScreen({super.key});

  @override
  State<SearchShellScreen> createState() => _SearchShellScreenState();
}

class _SearchShellScreenState extends State<SearchShellScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AppBackground(
      kind: AppBackgroundKind.phone,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: pad + const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GlassButton(
                    icon: Icons.arrow_back,
                    semanticLabel: 'بازگشت',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _controller,
                      hint: _hint,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              const Expanded(child: Center(child: _soon)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the desktop search overlay (Ctrl+K, toolbar capsule) on the root
/// navigator. It appears on the next frame: no transition, and no fade over
/// its glass.
Future<void> showSearchOverlay(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'بستن',
    barrierColor: AppTheme.of(context).colors.scrim,
    transitionDuration: Duration.zero,
    transitionBuilder: (context, animation, secondary, child) => child,
    pageBuilder: (context, animation, secondary) => const _SearchOverlay(),
  );
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay();

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Material(
        type: MaterialType.transparency,
        child: GlassOverlayContent(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 96),
              child: SizedBox(
                width: 560,
                child: AppGlass(
                  role: GlassRole.sheet,
                  shape: const AppleGlassShape.rounded(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassTextField(
                          controller: _controller,
                          hint: _hint,
                          autofocus: true,
                        ),
                        const SizedBox(height: 24),
                        _soon,
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
