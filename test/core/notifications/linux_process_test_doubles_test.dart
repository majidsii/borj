import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_process_runner.dart';
import '../../support/recording_linux_process_runner.dart';

void main() {
  group('FakeLinuxProcessRunner', () {
    test('returns queued results in FIFO order', () async {
      final runner = FakeLinuxProcessRunner();
      final first = _result('first');
      final second = _result('second');

      runner
        ..enqueueResult(first)
        ..enqueueResult(second);

      expect(runner.pendingResponseCount, 2);
      await expectLater(runner.run(_request('one')), completion(same(first)));
      await expectLater(runner.run(_request('two')), completion(same(second)));
      expect(runner.pendingResponseCount, 0);
    });

    test('throws queued failures in FIFO order', () async {
      final runner = FakeLinuxProcessRunner();
      final first = StateError('first failure');
      final second = ArgumentError('second failure');

      runner
        ..enqueueFailure(first, StackTrace.current)
        ..enqueueFailure(second, StackTrace.current);

      await expectLater(runner.run(_request('one')), throwsA(same(first)));
      await expectLater(runner.run(_request('two')), throwsA(same(second)));
      expect(runner.pendingResponseCount, 0);
    });

    test('rejects an invocation without a queued response', () async {
      final runner = FakeLinuxProcessRunner();

      await expectLater(
        runner.run(_request('missing')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('No fake Linux process response'),
          ),
        ),
      );
    });

    test('controlled call waits for explicit completion', () async {
      final runner = FakeLinuxProcessRunner();
      final controlled = runner.enqueueControlled();
      final request = _request('controlled');
      final source = LinuxCancellationSource();
      var completed = false;

      final future = runner.run(request, cancellationToken: source.token).then((
        value,
      ) {
        completed = true;
        return value;
      });

      final invocation = await controlled.invocation;
      expect(invocation.request, same(request));
      expect(invocation.cancellationToken, same(source.token));

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      final expected = _result('controlled');
      expect(controlled.complete(expected), isTrue);
      expect(controlled.complete(expected), isFalse);

      await expectLater(future, completion(same(expected)));
      expect(completed, isTrue);
    });

    test('controlled call can fail exactly once', () async {
      final runner = FakeLinuxProcessRunner();
      final controlled = runner.enqueueControlled();
      final error = StateError('controlled failure');
      final future = runner.run(_request('controlled'));

      await controlled.invocation;

      final errorExpectation = expectLater(future, throwsA(same(error)));

      expect(controlled.fail(error, StackTrace.current), isTrue);
      expect(controlled.fail(error, StackTrace.current), isFalse);

      await errorExpectation;
    });

    test(
      'controlled call observes cancellation from the supplied token',
      () async {
        final runner = FakeLinuxProcessRunner();
        final controlled = runner.enqueueControlled();
        final source = LinuxCancellationSource();
        final future = runner.run(
          _request('cancel'),
          cancellationToken: source.token,
        );

        await controlled.invocation;
        expect(source.cancel(), isTrue);
        await expectLater(controlled.whenCancellationObserved, completes);

        controlled.complete(_result('cancel'));
        await expectLater(future, completes);
      },
    );

    test('controlled calls remain assigned by invocation order', () async {
      final runner = FakeLinuxProcessRunner();
      final firstControlled = runner.enqueueControlled();
      final secondControlled = runner.enqueueControlled();

      final firstFuture = runner.run(_request('first'));
      final secondFuture = runner.run(_request('second'));

      final firstInvocation = await firstControlled.invocation;
      final secondInvocation = await secondControlled.invocation;

      expect(firstInvocation.request.arguments, const <String>['first']);
      expect(secondInvocation.request.arguments, const <String>['second']);

      final secondResult = _result('second');
      final firstResult = _result('first');

      secondControlled.complete(secondResult);
      firstControlled.complete(firstResult);

      await expectLater(firstFuture, completion(same(firstResult)));
      await expectLater(secondFuture, completion(same(secondResult)));
    });
  });

  group('RecordingLinuxProcessRunner', () {
    test(
      'records an immutable request before the delegate completes',
      () async {
        final fake = FakeLinuxProcessRunner();
        final controlled = fake.enqueueControlled();
        final runner = RecordingLinuxProcessRunner(fake);
        final request = _request('recorded');
        final source = LinuxCancellationSource();

        final future = runner.run(request, cancellationToken: source.token);

        await controlled.invocation;

        expect(runner.calls, hasLength(1));
        final recorded = runner.calls.single;

        expect(recorded.sequence, 0);
        expect(recorded.request, isNot(same(request)));
        expect(recorded.request.executable, request.executable);
        expect(recorded.request.arguments, request.arguments);
        expect(recorded.request.environment, request.environment);
        expect(recorded.request.timeout, request.timeout);
        expect(
          recorded.request.terminationGracePeriod,
          request.terminationGracePeriod,
        );
        expect(recorded.request.stdoutLimitBytes, request.stdoutLimitBytes);
        expect(recorded.request.stderrLimitBytes, request.stderrLimitBytes);
        expect(
          recorded.request.includeParentEnvironment,
          request.includeParentEnvironment,
        );
        expect(recorded.cancellationToken, same(source.token));
        expect(() => runner.calls.add(recorded), throwsUnsupportedError);

        final expected = _result('recorded');
        controlled.complete(expected);
        await expectLater(future, completion(same(expected)));
      },
    );

    test('records failed delegate invocations', () async {
      final fake = FakeLinuxProcessRunner();
      final runner = RecordingLinuxProcessRunner(fake);
      final error = StateError('delegate failed');

      fake.enqueueFailure(error, StackTrace.current);

      await expectLater(runner.run(_request('failed')), throwsA(same(error)));

      expect(runner.calls, hasLength(1));
      expect(runner.calls.single.sequence, 0);
      expect(runner.calls.single.request.arguments, const <String>['failed']);
    });

    test('assigns monotonic sequence numbers to concurrent calls', () async {
      final fake = FakeLinuxProcessRunner();
      final firstControlled = fake.enqueueControlled();
      final secondControlled = fake.enqueueControlled();
      final runner = RecordingLinuxProcessRunner(fake);

      final firstFuture = runner.run(_request('first'));
      final secondFuture = runner.run(_request('second'));

      await Future.wait<void>(<Future<void>>[
        firstControlled.invocation.then((_) {}),
        secondControlled.invocation.then((_) {}),
      ]);

      expect(
        runner.calls.map((call) => call.sequence),
        orderedEquals(<int>[0, 1]),
      );
      expect(
        runner.calls.map((call) => call.request.arguments.single),
        orderedEquals(<String>['first', 'second']),
      );

      firstControlled.complete(_result('first'));
      secondControlled.complete(_result('second'));

      await Future.wait<LinuxProcessResult>(<Future<LinuxProcessResult>>[
        firstFuture,
        secondFuture,
      ]);
    });

    test('delegates the original request and cancellation token', () async {
      final fake = FakeLinuxProcessRunner();
      final controlled = fake.enqueueControlled();
      final runner = RecordingLinuxProcessRunner(fake);
      final request = _request('delegate');
      final source = LinuxCancellationSource();

      final future = runner.run(request, cancellationToken: source.token);

      final delegated = await controlled.invocation;

      expect(delegated.request, same(request));
      expect(delegated.cancellationToken, same(source.token));

      controlled.complete(_result('delegate'));
      await expectLater(future, completes);
    });
  });
}

LinuxProcessRequest _request(String marker) {
  return LinuxProcessRequest(
    executable: 'systemctl',
    arguments: <String>[marker],
    environment: <String, String>{'MARKER': marker},
    timeout: const Duration(seconds: 3),
    terminationGracePeriod: const Duration(milliseconds: 250),
    stdoutLimitBytes: 4096,
    stderrLimitBytes: 8192,
    includeParentEnvironment: false,
  );
}

LinuxProcessResult _result(String marker) {
  return LinuxProcessResult(
    executable: 'systemctl',
    arguments: <String>[marker],
    pid: marker.hashCode,
    exitCode: 0,
    duration: const Duration(milliseconds: 1),
    stdout: LinuxBoundedOutput(
      text: marker,
      totalBytes: marker.length,
      retainedBytes: marker.length,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    ),
    stderr: const LinuxBoundedOutput(
      text: '',
      totalBytes: 0,
      retainedBytes: 0,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    ),
  );
}
