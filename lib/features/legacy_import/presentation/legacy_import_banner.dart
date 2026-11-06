import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/original_glass.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_flow.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offers the import once: only while a v1 file was auto-detected and the
/// ledger is empty. "Later" hides it for the current session.
final class LegacyImportBanner extends ConsumerWidget {
  const LegacyImportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(legacyBannerDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final file = ref.watch(legacyBannerFileProvider).asData?.value;
    if (file == null) return const SizedBox.shrink();

    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OriginalGlass(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(Icons.download_outlined, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'فایل داده‌های نسخه ۱ روی این دستگاه پیدا شد. وارد شود؟',
                style: TextStyle(color: palette.ink, fontSize: 13.5),
              ),
            ),
            TextButton(
              key: const ValueKey<String>('legacy-banner-dismiss'),
              onPressed: () =>
                  ref.read(legacyBannerDismissedProvider.notifier).state = true,
              child: const Text('بعداً'),
            ),
            FilledButton(
              key: const ValueKey<String>('legacy-banner-import'),
              onPressed: () => runLegacyImportFlow(
                context: context,
                ref: ref,
                loadBytes: file.readAsBytes,
              ),
              child: const Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
