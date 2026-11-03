import 'dart:typed_data';

import 'package:dashboard_shakhsi/features/legacy_import/application/legacy_file_picker.dart';
import 'package:file_picker/file_picker.dart';

final class FilePickerLegacyFilePicker implements LegacyFilePicker {
  const FilePickerLegacyFilePicker();

  @override
  Future<Uint8List?> pickJsonBytes() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'انتخاب فایل داده نسخه ۱',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
