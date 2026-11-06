import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_timer_status.dart';
import 'package:borj/core/notifications/linux_systemd_timer_status_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdTimerName', () {
    test('parses the exact app-generated timer pattern', () {
      final name = LinuxSystemdTimerName.parse(
        'borj-notification-0123456789abcdef.timer',
      );

      expect(name.value, 'borj-notification-0123456789abcdef.timer');
      expect(name.identityHex, '0123456789abcdef');
      expect(name.serviceName, 'borj-notification-0123456789abcdef.service');
      expect(name.toString(), name.value);
    });

    test('supports value equality and stable hashing', () {
      final first = LinuxSystemdTimerName.parse(
        'borj-notification-aaaaaaaaaaaaaaaa.timer',
      );
      final second = LinuxSystemdTimerName.parse(
        'borj-notification-aaaaaaaaaaaaaaaa.timer',
      );
      final different = LinuxSystemdTimerName.parse(
        'borj-notification-bbbbbbbbbbbbbbbb.timer',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    for (final invalid in <String>[
      '',
      ' borj-notification-0123456789abcdef.timer',
      'borj-notification-0123456789abcdef.timer ',
      'borj-notification-0123456789ABCDEf.timer',
      'borj-notification-0123456789abcde.timer',
      'borj-notification-0123456789abcdef0.timer',
      'borj-notification-0123456789abcdef.service',
      'other-notification-0123456789abcdef.timer',
      '../borj-notification-0123456789abcdef.timer',
      'borj-notification-0123456789abcdef.timer/extra',
      'borj-notification-0123456789abcdef.timer\n',
      'borj-notification-0123456789abcdef.timer\u0000',
    ]) {
      test('rejects invalid timer name ${invalid.runtimeType}: $invalid', () {
        expect(
          () => LinuxSystemdTimerName.parse(invalid),
          throwsA(isA<FormatException>()),
        );
        expect(LinuxSystemdTimerName.isValid(invalid), isFalse);
      });
    }
  });

  group('LinuxSystemdTimerStatusParser', () {
    const parser = LinuxSystemdTimerStatusParser();
    final expectedName = LinuxSystemdTimerName.parse(
      'borj-notification-0123456789abcdef.timer',
    );

    test('parses a healthy timer into typed state values', () {
      final status = parser.parse(
        expectedName: expectedName,
        output: _healthyOutput(),
      );

      expect(status.name, expectedName);
      expect(status.loadState, LinuxSystemdLoadState.loaded);
      expect(status.activeState, LinuxSystemdActiveState.active);
      expect(status.subState, LinuxSystemdTimerSubState.waiting);
      expect(status.unitFileState, LinuxSystemdUnitFileState.enabled);
      expect(status.result, LinuxSystemdUnitResult.success);
      expect(status.isInstalled, isTrue);
      expect(status.isEnabled, isTrue);
      expect(status.isActive, isTrue);
      expect(status.isWaiting, isTrue);
      expect(status.isHealthy, isTrue);
    });

    test('accepts CRLF and exactly one trailing newline', () {
      final output = _healthyOutput().replaceAll('\n', '\r\n');

      final status = parser.parse(expectedName: expectedName, output: output);

      expect(status.isHealthy, isTrue);
    });

    test('represents a disabled inactive timer without guessing health', () {
      final status = parser.parse(
        expectedName: expectedName,
        output: _statusOutput(
          activeState: 'inactive',
          subState: 'dead',
          unitFileState: 'disabled',
        ),
      );

      expect(status.isInstalled, isTrue);
      expect(status.isEnabled, isFalse);
      expect(status.isActive, isFalse);
      expect(status.isWaiting, isFalse);
      expect(status.isHealthy, isFalse);
    });

    test('supports enabled-runtime as an enabled state', () {
      final status = parser.parse(
        expectedName: expectedName,
        output: _statusOutput(unitFileState: 'enabled-runtime'),
      );

      expect(status.unitFileState, LinuxSystemdUnitFileState.enabledRuntime);
      expect(status.isEnabled, isTrue);
    });

    test('rejects empty output', () {
      _expectFailure(
        () => parser.parse(expectedName: expectedName, output: ''),
        LinuxSystemdTimerStatusParseFailure.emptyOutput,
      );
    });

    test('rejects a line without the key-value delimiter', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            'LoadState=loaded',
            'LoadState loaded',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.malformedLine,
        property: 'LoadState loaded',
        lineNumber: 2,
      );
    });

    test('rejects duplicate properties', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: '${_healthyOutput()}LoadState=loaded\n',
        ),
        LinuxSystemdTimerStatusParseFailure.duplicateProperty,
        property: 'LoadState',
      );
    });

    test('rejects unknown properties', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: '${_healthyOutput()}Description=unexpected\n',
        ),
        LinuxSystemdTimerStatusParseFailure.unknownProperty,
        property: 'Description',
      );
    });

    test('rejects a missing required property', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst('Result=success\n', ''),
        ),
        LinuxSystemdTimerStatusParseFailure.missingProperty,
        property: 'Result',
      );
    });

    test('rejects an unexpected timer id', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            expectedName.value,
            'borj-notification-fedcba9876543210.timer',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.unexpectedTimerName,
        property: 'Id',
      );
    });

    test('rejects an invalid timer id before comparing identity', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            expectedName.value,
            'unsafe.timer',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.invalidTimerName,
        property: 'Id',
      );
    });

    for (final entry in <MapEntry<String, String>>[
      const MapEntry<String, String>('LoadState', 'future-load-state'),
      const MapEntry<String, String>('ActiveState', 'future-active-state'),
      const MapEntry<String, String>('SubState', 'future-sub-state'),
      const MapEntry<String, String>('UnitFileState', 'future-unit-file-state'),
      const MapEntry<String, String>('Result', 'future-result'),
    ]) {
      test('rejects unknown ${entry.key} value', () {
        final original = switch (entry.key) {
          'LoadState' => 'loaded',
          'ActiveState' => 'active',
          'SubState' => 'waiting',
          'UnitFileState' => 'enabled',
          'Result' => 'success',
          _ => throw StateError('Unexpected property'),
        };

        _expectFailure(
          () => parser.parse(
            expectedName: expectedName,
            output: _healthyOutput().replaceFirst(
              '${entry.key}=$original',
              '${entry.key}=${entry.value}',
            ),
          ),
          LinuxSystemdTimerStatusParseFailure.invalidValue,
          property: entry.key,
          value: entry.value,
        );
      });
    }

    test('rejects blank property values', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst('Result=success', 'Result='),
        ),
        LinuxSystemdTimerStatusParseFailure.invalidValue,
        property: 'Result',
        value: '',
      );
    });

    test('rejects surrounding whitespace instead of normalizing it', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            'ActiveState=active',
            'ActiveState= active',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.invalidValue,
        property: 'ActiveState',
        value: ' active',
      );
    });

    test('rejects blank lines inside machine output', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            'ActiveState=active\n',
            'ActiveState=active\n\n',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.malformedLine,
      );
    });

    test('rejects control characters in machine output', () {
      _expectFailure(
        () => parser.parse(
          expectedName: expectedName,
          output: _healthyOutput().replaceFirst(
            'Result=success',
            'Result=success\u0000',
          ),
        ),
        LinuxSystemdTimerStatusParseFailure.controlCharacter,
      );
    });
  });
}

void _expectFailure(
  Object? Function() action,
  LinuxSystemdTimerStatusParseFailure failure, {
  String? property,
  String? value,
  int? lineNumber,
}) {
  var matcher = isA<LinuxSystemdTimerStatusParseException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );

  if (property != null) {
    matcher = matcher.having((error) => error.property, 'property', property);
  }

  if (value != null) {
    matcher = matcher.having((error) => error.value, 'value', value);
  }

  if (lineNumber != null) {
    matcher = matcher.having(
      (error) => error.lineNumber,
      'lineNumber',
      lineNumber,
    );
  }

  expect(action, throwsA(matcher));
}

String _healthyOutput() => _statusOutput();

String _statusOutput({
  String loadState = 'loaded',
  String activeState = 'active',
  String subState = 'waiting',
  String unitFileState = 'enabled',
  String result = 'success',
}) {
  return <String>[
    'Id=borj-notification-0123456789abcdef.timer',
    'LoadState=$loadState',
    'ActiveState=$activeState',
    'SubState=$subState',
    'UnitFileState=$unitFileState',
    'Result=$result',
    '',
  ].join('\n');
}
