import 'dart:io';

import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:dashboard_shakhsi/features/legacy_import/data/file_picker_legacy_file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final legacyFilePickerProvider = Provider<LegacyFilePicker>((ref) {
  return const FilePickerLegacyFilePicker();
});

/// v1's `data.json` on this desktop, if it exists.
final legacyDetectedFileProvider = FutureProvider<File?>((ref) {
  return ref.watch(legacyV1SourceLocatorProvider).detect();
});

/// The detected file, but only while nothing has been imported yet.
final legacyBannerFileProvider = FutureProvider<File?>((ref) async {
  final file = await ref.watch(legacyDetectedFileProvider.future);
  if (file == null) return null;
  final imported = await ref.watch(legacyImportLedgerProvider).hasAnyRecords();
  return imported ? null : file;
});

/// "Later" on the banner. Session only: no settings store exists yet.
final legacyBannerDismissedProvider = StateProvider<bool>((ref) => false);
