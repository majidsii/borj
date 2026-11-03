import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_flow.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LegacyImportSection extends ConsumerWidget {
  const LegacyImportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = OriginalPalette.of(context);
    final detected = ref.watch(legacyDetectedFileProvider).asData?.value;
    final picker = ref.watch(legacyFilePickerProvider);

    return OriginalGlass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ورود اطلاعات از نسخه ۱',
            style: TextStyle(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'فایل data.json نسخه ۱ یا فایل خروجی JSON آن را انتخاب کنید. '
            'پیش از ورود، پیش‌نمایش را می‌بینید و فایل شما تغییر نمی‌کند.',
            style: TextStyle(color: palette.muted, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              if (detected != null)
                OriginalPrimaryButton(
                  key: const ValueKey<String>('legacy-import-use-detected'),
                  label: 'بررسی فایل پیدا‌شده',
                  onPressed: () => runLegacyImportFlow(
                    context: context,
                    ref: ref,
                    loadBytes: detected.readAsBytes,
                  ),
                ),
              OriginalGhostButton(
                key: const ValueKey<String>('legacy-import-pick-file'),
                label: 'انتخاب فایل داده',
                icon: Icons.folder_open_outlined,
                onPressed: () => runLegacyImportFlow(
                  context: context,
                  ref: ref,
                  loadBytes: picker.pickJsonBytes,
                ),
              ),
            ],
          ),
          if (detected != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              detected.path,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: palette.faint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
