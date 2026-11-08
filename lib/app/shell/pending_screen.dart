import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A page for a destination whose feature ships in a later phase. It keeps the
/// route resolvable (notifications, deep links) with a back button.
class PendingScreen extends StatelessWidget {
  const PendingScreen({required this.title, this.message, Key? key})
    : super(key: key ?? const ValueKey('pending-screen'));

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: pad + const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.construction_outlined,
                  title: title,
                  message: message ?? 'این بخش در مرحله‌های بعدی ساخته می‌شود',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The router's error page: unknown locations land here.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({Key? key})
    : super(key: key ?? const ValueKey('route-error'));

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      kind: AppBackgroundKind.phone,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'این صفحه پیدا نشد',
            actionLabel: 'رفتن به امروز',
            onAction: () => context.go('/'),
          ),
        ),
      ),
    );
  }
}
