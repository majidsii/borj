import 'dart:typed_data';

abstract interface class LegacyFilePicker {
  /// Lets the user pick a v1 `.json` file and returns its bytes, or `null`
  /// when the dialog was cancelled.
  Future<Uint8List?> pickJsonBytes();
}
