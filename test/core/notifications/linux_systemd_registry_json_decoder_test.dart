import 'package:borj/core/notifications/linux_systemd_registry_json_decoder.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdRegistryJsonDecoder', () {
    const decoder = LinuxSystemdRegistryJsonDecoder();

    test('decodes nested ordinary JSON values', () {
      expect(
        decoder.decode('{"a":1,"b":{"c":true},"d":[null,"x",-12.5e2]}'),
        equals(<String, Object?>{
          'a': 1,
          'b': <String, Object?>{'c': true},
          'd': <Object?>[null, 'x', -1250.0],
        }),
      );
    });

    test('decodes all JSON string escapes', () {
      expect(decoder.decode(r'"\"\\\/\b\f\n\r\t"'), '"\\/\b\f\n\r\t');
    });

    test('decodes basic Unicode escapes and surrogate pairs', () {
      expect(decoder.decode(r'"\u06F1"'), '۱');
      expect(decoder.decode(r'"\uD83D\uDE00"'), '😀');
    });

    test('preserves integer and fractional number categories', () {
      expect(decoder.decode('0'), isA<int>());
      expect(decoder.decode('-42'), -42);
      expect(decoder.decode('1.0'), isA<double>());
      expect(decoder.decode('1e2'), 100.0);
      expect(decoder.decode('-2.5E-1'), -0.25);
    });

    test('accepts JSON whitespace around one value', () {
      expect(decoder.decode(' \t\r\n {"value": true} \n'), <String, Object?>{
        'value': true,
      });
    });

    test('rejects duplicate top-level object keys', () {
      _expectMalformed(() => decoder.decode('{"a":1,"a":2}'));
    });

    test('rejects duplicate nested object keys', () {
      _expectMalformed(() => decoder.decode('{"outer":{"x":1,"x":2}}'));
    });

    test('allows the same key in separate sibling objects', () {
      expect(decoder.decode('[{"x":1},{"x":2}]'), <Object?>[
        <String, Object?>{'x': 1},
        <String, Object?>{'x': 2},
      ]);
    });

    for (final source in <String>[
      '',
      '   ',
      '{',
      '[',
      '{"a"}',
      '{"a":}',
      '{"a":1,}',
      '[1,]',
      '{"a":1} trailing',
      '"unterminated',
      r'"\x"',
      r'"\u12"',
      r'"\uZZZZ"',
      r'"\uD83D"',
      r'"\uD83D\u0041"',
      r'"\uDE00"',
      '01',
      '-01',
      '+1',
      '1.',
      '1e',
      '1e+',
      'NaN',
      'Infinity',
      'true false',
    ]) {
      test('rejects malformed JSON: $source', () {
        _expectMalformed(() => decoder.decode(source));
      });
    }

    test('rejects unescaped control characters in strings', () {
      _expectMalformed(() => decoder.decode('"line\nbreak"'));
      _expectMalformed(
        () => decoder.decode(String.fromCharCodes(<int>[0x22, 0x01, 0x22])),
      );
    });

    test('safe diagnostics never include source JSON', () {
      const secret = 'TOP_SECRET_JSON_VALUE';

      try {
        decoder.decode('{"secret":"$secret",}');
        fail('Expected malformed JSON.');
      } on LinuxSystemdScheduleRegistryException catch (error) {
        expect(error.operation, LinuxSystemdScheduleRegistryOperation.decode);
        expect(
          error.failure,
          LinuxSystemdScheduleRegistryFailure.malformedJson,
        );
        expect(error.toString(), isNot(contains(secret)));
      }
    });
  });
}

void _expectMalformed(Object? Function() action) {
  expect(
    action,
    throwsA(
      isA<LinuxSystemdScheduleRegistryException>()
          .having(
            (error) => error.operation,
            'operation',
            LinuxSystemdScheduleRegistryOperation.decode,
          )
          .having(
            (error) => error.failure,
            'failure',
            LinuxSystemdScheduleRegistryFailure.malformedJson,
          ),
    ),
  );
}
