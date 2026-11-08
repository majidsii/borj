import 'package:borj/app/design/design.dart';
import 'package:borj/app/router/app_router.dart';
import 'package:borj/core/date_time/persian_date_label.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Placeholder Today until the real page lands (Phase 3). In debug builds,
/// long-pressing the large title opens the glass review.
class TodayInterimPage extends ConsumerWidget {
  const TodayInterimPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: MediaQuery.paddingOf(context),
      children: [
        LargeTitleHeader(
          key: const ValueKey('today-title'),
          title: 'امروز',
          subtitle: PersianDateLabel.full(
            ref.watch(appClockProvider).nowLocal(),
          ),
          onTitleLongPress: kDebugMode
              ? () => context.go(AppRoutes.glassReview)
              : null,
        ),
        const LegacyImportBanner(),
        const EmptyState(
          icon: Icons.wb_sunny_outlined,
          title: 'صفحهٔ امروز در حال ساخت است',
          message: 'به‌زودی کارها و پول امروز اینجا می‌آیند',
        ),
      ],
    );
  }
}
