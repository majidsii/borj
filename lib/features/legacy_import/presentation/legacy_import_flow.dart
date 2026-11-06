import 'dart:typed_data';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/core/providers/persistence_providers.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_dialogs.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Load bytes, parse, preview, confirm, import in one transaction, report.
/// Failures show a snackbar; nothing is written unless the user confirms.
Future<void> runLegacyImportFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Future<Uint8List?> Function() loadBytes,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final bytes = await loadBytes();
    if (bytes == null) return;

    final snapshot = await ref.read(legacyV1ParserProvider).parseBytes(bytes);
    final service = ref.read(legacyImportServiceProvider);
    final preview = await service.preview(snapshot);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => LegacyImportPreviewDialog(preview: preview),
    );
    if (confirmed != true) return;

    final report = await service.execute(snapshot);
    ref.invalidate(legacyBannerFileProvider);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => LegacyImportReportDialog(report: report),
    );
  } on AppFailure catch (failure) {
    messenger?.showSnackBar(SnackBar(content: Text(failure.userMessage)));
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('خواندن یا ورود فایل انجام نشد.')),
    );
  }
}
