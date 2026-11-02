import 'dart:convert';
import 'dart:typed_data';

import 'package:dashboard_shakhsi/core/notifications/linux_bounded_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxBoundedOutputCollector', () {
    test('rejects a non-positive byte limit', () {
      expect(
        () => LinuxBoundedOutputCollector(limitBytes: 0),
        throwsArgumentError,
      );
      expect(
        () => LinuxBoundedOutputCollector(limitBytes: -1),
        throwsArgumentError,
      );
    });

    test('finishes an empty stream without truncation', () {
      final output = LinuxBoundedOutputCollector(limitBytes: 8).finish();

      expect(output.text, '');
      expect(output.totalBytes, 0);
      expect(output.retainedBytes, 0);
      expect(output.droppedBytes, 0);
      expect(output.truncated, isFalse);
      expect(output.malformedUtf8, isFalse);
    });

    test('retains all bytes below the limit', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(utf8.encode('hello'));

      final output = collector.finish();

      expect(output.text, 'hello');
      expect(output.totalBytes, 5);
      expect(output.retainedBytes, 5);
      expect(output.droppedBytes, 0);
      expect(output.truncated, isFalse);
      expect(output.malformedUtf8, isFalse);
    });

    test('retains all bytes exactly at the limit', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 5)
        ..add(utf8.encode('hello'));

      final output = collector.finish();

      expect(output.text, 'hello');
      expect(output.totalBytes, 5);
      expect(output.retainedBytes, 5);
      expect(output.droppedBytes, 0);
      expect(output.truncated, isFalse);
    });

    test('truncates one byte above the limit', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 5)
        ..add(utf8.encode('ABCDEF'));

      final output = collector.finish();

      expect(output.text, 'ABDEF');
      expect(output.totalBytes, 6);
      expect(output.retainedBytes, 5);
      expect(output.droppedBytes, 1);
      expect(output.truncated, isTrue);
    });

    test('retains exact prefix and suffix for an even limit', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(utf8.encode('0123456789'));

      final output = collector.finish();

      expect(output.text, '01236789');
      expect(output.totalBytes, 10);
      expect(output.retainedBytes, 8);
      expect(output.droppedBytes, 2);
      expect(output.truncated, isTrue);
    });

    test('assigns the extra retained byte to the suffix for an odd limit', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 5)
        ..add(utf8.encode('ABCDEFG'));

      final output = collector.finish();

      expect(output.text, 'ABEFG');
      expect(output.retainedBytes, 5);
      expect(output.droppedBytes, 2);
      expect(output.truncated, isTrue);
    });

    test('produces the same result across arbitrary chunk boundaries', () {
      final singleChunk = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(utf8.encode('0123456789'));

      final splitChunks = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(utf8.encode('01'))
        ..add(utf8.encode('23456'))
        ..add(utf8.encode('789'));

      final first = singleChunk.finish();
      final second = splitChunks.finish();

      expect(second.text, first.text);
      expect(second.totalBytes, first.totalBytes);
      expect(second.retainedBytes, first.retainedBytes);
      expect(second.droppedBytes, first.droppedBytes);
      expect(second.truncated, first.truncated);
      expect(second.malformedUtf8, first.malformedUtf8);
    });

    test('decodes a valid UTF-8 character split across chunks', () {
      final bytes = utf8.encode('A€B');
      final collector = LinuxBoundedOutputCollector(limitBytes: 16)
        ..add(bytes.sublist(0, 2))
        ..add(bytes.sublist(2, 3))
        ..add(bytes.sublist(3));

      final output = collector.finish();

      expect(output.text, 'A€B');
      expect(output.totalBytes, bytes.length);
      expect(output.malformedUtf8, isFalse);
    });

    test('replaces malformed UTF-8 and reports it', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(<int>[0x66, 0x80, 0x6f]);

      final output = collector.finish();

      expect(output.text, 'f\uFFFDo');
      expect(output.totalBytes, 3);
      expect(output.malformedUtf8, isTrue);
    });

    test('reports malformed UTF-8 created by a truncation boundary', () {
      final source = <int>[0x41, 0xE2, 0x82, 0xAC, 0x42, 0x43];
      final collector = LinuxBoundedOutputCollector(limitBytes: 4)..add(source);

      final output = collector.finish();

      expect(output.retainedBytes, 4);
      expect(output.droppedBytes, 2);
      expect(output.truncated, isTrue);
      expect(output.malformedUtf8, isTrue);
      expect(output.text, contains('\uFFFD'));
    });

    test('consumes input immediately and does not retain caller lists', () {
      final bytes = <int>[0x41, 0x42, 0x43];
      final collector = LinuxBoundedOutputCollector(limitBytes: 8)..add(bytes);

      bytes
        ..clear()
        ..addAll(<int>[0x58, 0x59, 0x5A]);

      expect(collector.finish().text, 'ABC');
    });

    test('rejects values outside the byte range', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 8);

      expect(() => collector.add(<int>[-1]), throwsArgumentError);
      expect(() => collector.add(<int>[256]), throwsArgumentError);
    });

    test('finish is idempotent and add after finish is rejected', () {
      final collector = LinuxBoundedOutputCollector(limitBytes: 8)
        ..add(utf8.encode('hello'));

      final first = collector.finish();
      final second = collector.finish();

      expect(identical(second, first), isTrue);
      expect(() => collector.add(utf8.encode(' later')), throwsStateError);
    });

    test('keeps retained output bounded for a very large stream', () {
      const limit = 256 * 1024;
      const chunkSize = 4096;
      const chunkCount = 1024;
      final chunk = Uint8List.fromList(
        List<int>.generate(chunkSize, (index) => index % 251, growable: false),
      );
      final collector = LinuxBoundedOutputCollector(limitBytes: limit);

      for (var index = 0; index < chunkCount; index++) {
        collector.add(chunk);
      }

      final output = collector.finish();

      expect(output.totalBytes, chunkSize * chunkCount);
      expect(output.retainedBytes, limit);
      expect(output.droppedBytes, output.totalBytes - limit);
      expect(output.truncated, isTrue);
    });
  });
}
