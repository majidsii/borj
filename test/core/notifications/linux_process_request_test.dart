import 'dart:async';

import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_exception.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxProcessRequest', () {
    test('uses production-safe defaults', () {
      final request = LinuxProcessRequest(
        executable: 'systemctl',
        arguments: const <String>['--user'],
        environment: const <String, String>{},
      );

      expect(request.executable, 'systemctl');
      expect(request.arguments, const <String>['--user']);
      expect(request.environment, isEmpty);
      expect(request.timeout, const Duration(seconds: 15));
      expect(request.terminationGracePeriod, const Duration(seconds: 2));
      expect(request.stdoutLimitBytes, 256 * 1024);
      expect(request.stderrLimitBytes, 256 * 1024);
      expect(request.includeParentEnvironment, isTrue);
    });

    test('snapshots and protects arguments and environment', () {
      final arguments = <String>['--user'];
      final environment = <String, String>{'LC_ALL': 'C'};

      final request = LinuxProcessRequest(
        executable: 'systemctl',
        arguments: arguments,
        environment: environment,
      );

      arguments.add('daemon-reload');
      environment['LANG'] = 'C';

      expect(request.arguments, const <String>['--user']);
      expect(request.environment, const <String, String>{'LC_ALL': 'C'});
      expect(() => request.arguments.add('--no-pager'), throwsUnsupportedError);
      expect(() => request.environment['LANG'] = 'C', throwsUnsupportedError);
    });

    test('supports an absolute executable path and explicit options', () {
      final request = LinuxProcessRequest(
        executable: '/usr/bin/systemctl',
        arguments: const <String>['--user'],
        environment: const <String, String>{},
        timeout: const Duration(seconds: 4),
        terminationGracePeriod: Duration.zero,
        stdoutLimitBytes: 2048,
        stderrLimitBytes: 4096,
        includeParentEnvironment: false,
      );

      expect(request.executable, '/usr/bin/systemctl');
      expect(request.timeout, const Duration(seconds: 4));
      expect(request.terminationGracePeriod, Duration.zero);
      expect(request.stdoutLimitBytes, 2048);
      expect(request.stderrLimitBytes, 4096);
      expect(request.includeParentEnvironment, isFalse);
    });

    test('rejects invalid executable values', () {
      LinuxProcessRequest create(String executable) => LinuxProcessRequest(
        executable: executable,
        arguments: const <String>[],
        environment: const <String, String>{},
      );

      for (final executable in <String>[
        '',
        ' systemctl',
        'systemctl ',
        'systemctl --user',
        'systemctl;rm',
        'systemctl|cat',
        'systemctl&echo',
        'systemctl`id`',
        r'systemctl$(id)',
        'systemctl\n',
        'systemctl\u0000',
      ]) {
        expect(
          () => create(executable),
          throwsArgumentError,
          reason: 'expected executable to be rejected: $executable',
        );
      }
    });

    test('rejects NUL in arguments and environment', () {
      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>['--user\u0000'],
          environment: const <String, String>{},
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>[],
          environment: const <String, String>{'BAD\u0000KEY': 'value'},
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>[],
          environment: const <String, String>{'KEY': 'bad\u0000value'},
        ),
        throwsArgumentError,
      );
    });

    test('requires a positive timeout', () {
      for (final timeout in <Duration>[
        Duration.zero,
        const Duration(microseconds: -1),
      ]) {
        expect(
          () => LinuxProcessRequest(
            executable: 'systemctl',
            arguments: const <String>[],
            environment: const <String, String>{},
            timeout: timeout,
          ),
          throwsArgumentError,
        );
      }
    });

    test('requires a non-negative termination grace period', () {
      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>[],
          environment: const <String, String>{},
          terminationGracePeriod: const Duration(microseconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('requires output limits of at least two KiB', () {
      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>[],
          environment: const <String, String>{},
          stdoutLimitBytes: 2047,
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxProcessRequest(
          executable: 'systemctl',
          arguments: const <String>[],
          environment: const <String, String>{},
          stderrLimitBytes: 2047,
        ),
        throwsArgumentError,
      );
    });
  });

  group('LinuxCancellationSource', () {
    test('is pending until cancelled', () async {
      final source = LinuxCancellationSource();
      var completed = false;

      unawaited(
        source.token.whenCancelled.then((_) {
          completed = true;
        }),
      );

      await Future<void>.delayed(Duration.zero);

      expect(source.token.isCancelled, isFalse);
      expect(completed, isFalse);
    });

    test('cancels once and completes all observers', () async {
      final source = LinuxCancellationSource();
      final token = source.token;
      var observerCount = 0;

      final first = token.whenCancelled.then((_) => observerCount++);
      final second = token.whenCancelled.then((_) => observerCount++);

      expect(source.cancel(), isTrue);
      expect(source.cancel(), isFalse);

      await Future.wait<void>(<Future<void>>[first, second]);

      expect(token.isCancelled, isTrue);
      expect(observerCount, 2);
      expect(identical(source.token, token), isTrue);
    });

    test('late observers complete after cancellation', () async {
      final source = LinuxCancellationSource();

      source.cancel();

      await expectLater(source.token.whenCancelled, completes);
    });
  });

  group('LinuxBoundedOutput and LinuxProcessResult', () {
    const emptyOutput = LinuxBoundedOutput(
      text: '',
      totalBytes: 0,
      retainedBytes: 0,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    );

    test('exposes immutable output metadata', () {
      expect(emptyOutput.text, '');
      expect(emptyOutput.totalBytes, 0);
      expect(emptyOutput.retainedBytes, 0);
      expect(emptyOutput.droppedBytes, 0);
      expect(emptyOutput.truncated, isFalse);
      expect(emptyOutput.malformedUtf8, isFalse);
    });

    test('snapshots process arguments', () {
      final arguments = <String>['--user'];

      final result = LinuxProcessResult(
        executable: 'systemctl',
        arguments: arguments,
        pid: 42,
        exitCode: 0,
        duration: const Duration(milliseconds: 7),
        stdout: emptyOutput,
        stderr: emptyOutput,
      );

      arguments.add('daemon-reload');

      expect(result.executable, 'systemctl');
      expect(result.arguments, const <String>['--user']);
      expect(() => result.arguments.add('--no-pager'), throwsUnsupportedError);
      expect(result.pid, 42);
      expect(result.exitCode, 0);
      expect(result.duration, const Duration(milliseconds: 7));
      expect(identical(result.stdout, emptyOutput), isTrue);
      expect(identical(result.stderr, emptyOutput), isTrue);
    });
  });

  group('LinuxProcessException', () {
    test('snapshots safe command diagnostics without environment data', () {
      final arguments = <String>['--user'];
      final cause = StateError('spawn failed');
      final stackTrace = StackTrace.current;

      final exception = LinuxProcessStartException(
        executable: 'systemctl',
        arguments: arguments,
        cause: cause,
        stackTrace: stackTrace,
      );

      arguments.add('SECRET=value');

      expect(exception.executable, 'systemctl');
      expect(exception.arguments, const <String>['--user']);
      expect(
        () => exception.arguments.add('--no-pager'),
        throwsUnsupportedError,
      );
      expect(exception.cause, same(cause));
      expect(exception.stackTrace, same(stackTrace));
      expect(exception.toString(), contains('LinuxProcessStartException'));
      expect(exception.toString(), isNot(contains('SECRET=value')));
    });

    test('defines dedicated lifecycle exception types', () {
      expect(LinuxProcessStartException, isA<Type>());
      expect(LinuxProcessTimeoutException, isA<Type>());
      expect(LinuxProcessCancellationException, isA<Type>());
      expect(LinuxProcessStreamException, isA<Type>());
      expect(LinuxProcessTerminationException, isA<Type>());
    });
  });

  test('LinuxProcessRunner contract accepts cancellation', () async {
    const emptyOutput = LinuxBoundedOutput(
      text: '',
      totalBytes: 0,
      retainedBytes: 0,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    );
    final expected = LinuxProcessResult(
      executable: 'systemctl',
      arguments: const <String>['--user'],
      pid: 1,
      exitCode: 0,
      duration: Duration.zero,
      stdout: emptyOutput,
      stderr: emptyOutput,
    );
    final runner = _StaticLinuxProcessRunner(expected);
    final source = LinuxCancellationSource();
    final request = LinuxProcessRequest(
      executable: 'systemctl',
      arguments: const <String>['--user'],
      environment: const <String, String>{},
    );

    final actual = await runner.run(request, cancellationToken: source.token);

    expect(actual, same(expected));
    expect(runner.lastRequest, same(request));
    expect(runner.lastCancellationToken, same(source.token));
  });
}

final class _StaticLinuxProcessRunner implements LinuxProcessRunner {
  _StaticLinuxProcessRunner(this.result);

  final LinuxProcessResult result;
  LinuxProcessRequest? lastRequest;
  LinuxCancellationToken? lastCancellationToken;

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    lastRequest = request;
    lastCancellationToken = cancellationToken;
    return result;
  }
}
