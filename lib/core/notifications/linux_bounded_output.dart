import 'dart:convert';

final class LinuxBoundedOutput {
  const LinuxBoundedOutput({
    required this.text,
    required this.totalBytes,
    required this.retainedBytes,
    required this.droppedBytes,
    required this.truncated,
    required this.malformedUtf8,
  }) : assert(totalBytes >= 0),
       assert(retainedBytes >= 0),
       assert(droppedBytes >= 0),
       assert(totalBytes == retainedBytes + droppedBytes),
       assert(truncated == (droppedBytes > 0));

  final String text;
  final int totalBytes;
  final int retainedBytes;
  final int droppedBytes;
  final bool truncated;
  final bool malformedUtf8;
}

final class LinuxBoundedOutputCollector {
  LinuxBoundedOutputCollector({required this.limitBytes})
    : _prefixLimitBytes = limitBytes ~/ 2,
      _suffixLimitBytes = limitBytes - (limitBytes ~/ 2) {
    if (limitBytes <= 0) {
      throw ArgumentError.value(
        limitBytes,
        'limitBytes',
        'must be greater than zero',
      );
    }

    _suffixRing = List<int>.filled(_suffixLimitBytes, 0, growable: false);
  }

  final int limitBytes;
  final int _prefixLimitBytes;
  final int _suffixLimitBytes;

  final List<int> _prefixBytes = <int>[];
  late final List<int> _suffixRing;

  int _suffixCount = 0;
  int _suffixWriteIndex = 0;
  int _totalBytes = 0;
  LinuxBoundedOutput? _finishedOutput;

  void add(List<int> bytes) {
    if (_finishedOutput != null) {
      throw StateError(
        'Cannot add bytes after bounded output has been finished.',
      );
    }

    _validateBytes(bytes);

    for (final byte in bytes) {
      _totalBytes++;

      if (_prefixBytes.length < _prefixLimitBytes) {
        _prefixBytes.add(byte);
        continue;
      }

      _suffixRing[_suffixWriteIndex] = byte;
      _suffixWriteIndex = (_suffixWriteIndex + 1) % _suffixLimitBytes;

      if (_suffixCount < _suffixLimitBytes) {
        _suffixCount++;
      }
    }
  }

  LinuxBoundedOutput finish() {
    final existing = _finishedOutput;
    if (existing != null) {
      return existing;
    }

    final retainedBytes = <int>[..._prefixBytes, ..._orderedSuffixBytes()];
    final droppedBytes = _totalBytes - retainedBytes.length;

    var malformedUtf8 = false;
    late final String text;

    try {
      text = utf8.decode(retainedBytes, allowMalformed: false);
    } on FormatException {
      malformedUtf8 = true;
      text = utf8.decode(retainedBytes, allowMalformed: true);
    }

    final output = LinuxBoundedOutput(
      text: text,
      totalBytes: _totalBytes,
      retainedBytes: retainedBytes.length,
      droppedBytes: droppedBytes,
      truncated: droppedBytes > 0,
      malformedUtf8: malformedUtf8,
    );

    _finishedOutput = output;
    return output;
  }

  List<int> _orderedSuffixBytes() {
    if (_suffixCount == 0) {
      return const <int>[];
    }

    if (_suffixCount < _suffixLimitBytes) {
      return List<int>.unmodifiable(_suffixRing.take(_suffixCount));
    }

    return List<int>.unmodifiable(<int>[
      ..._suffixRing.skip(_suffixWriteIndex),
      ..._suffixRing.take(_suffixWriteIndex),
    ]);
  }

  static void _validateBytes(List<int> bytes) {
    for (var index = 0; index < bytes.length; index++) {
      final byte = bytes[index];
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(
          byte,
          'bytes[$index]',
          'must be in the inclusive range 0..255',
        );
      }
    }
  }
}
