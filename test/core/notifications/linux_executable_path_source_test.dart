import 'package:borj/core/notifications/linux_executable_path_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidatedLinuxExecutablePathSource', () {
    test(
      'returns an absolute path when file verification is unavailable',
      () async {
        final source = _Source('/opt/borj/borj');
        final validated = ValidatedLinuxExecutablePathSource(source: source);

        expect(await validated.resolve(), '/opt/borj/borj');
        expect(source.resolveCount, 1);
      },
    );

    for (final invalid in <String>[
      '',
      'relative/borj',
      ' /opt/borj',
      '/opt/borj ',
      '/opt/bor\u0000j',
      '/opt/bor\nj',
      '/opt/bor\rj',
    ]) {
      test('rejects unsafe path code units: ${invalid.codeUnits}', () async {
        final validated = ValidatedLinuxExecutablePathSource(
          source: _Source(invalid),
        );

        await expectLater(
          validated.resolve(),
          throwsA(
            isA<LinuxExecutablePathException>().having(
              (error) => error.failure,
              'failure',
              LinuxExecutablePathFailure.invalidPath,
            ),
          ),
        );
      });
    }

    test('rejects a missing path reported by the verifier', () async {
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source('/opt/borj'),
        verifier: _Verifier(
          const LinuxExecutableFileStatus(
            exists: false,
            isRegularFile: false,
            isExecutable: false,
          ),
        ),
      );

      await expectLater(
        validated.resolve(),
        throwsA(
          isA<LinuxExecutablePathException>().having(
            (error) => error.failure,
            'failure',
            LinuxExecutablePathFailure.notFound,
          ),
        ),
      );
    });

    test('rejects a directory reported by the verifier', () async {
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source('/opt/borj'),
        verifier: _Verifier(
          const LinuxExecutableFileStatus(
            exists: true,
            isRegularFile: false,
            isExecutable: true,
          ),
        ),
      );

      await expectLater(
        validated.resolve(),
        throwsA(
          isA<LinuxExecutablePathException>().having(
            (error) => error.failure,
            'failure',
            LinuxExecutablePathFailure.notRegularFile,
          ),
        ),
      );
    });

    test('rejects a regular non-executable file', () async {
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source('/opt/borj'),
        verifier: _Verifier(
          const LinuxExecutableFileStatus(
            exists: true,
            isRegularFile: true,
            isExecutable: false,
          ),
        ),
      );

      await expectLater(
        validated.resolve(),
        throwsA(
          isA<LinuxExecutablePathException>().having(
            (error) => error.failure,
            'failure',
            LinuxExecutablePathFailure.notExecutable,
          ),
        ),
      );
    });

    test('accepts a verified regular executable file', () async {
      final verifier = _Verifier(
        const LinuxExecutableFileStatus(
          exists: true,
          isRegularFile: true,
          isExecutable: true,
        ),
      );
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source('/opt/borj'),
        verifier: verifier,
      );

      expect(await validated.resolve(), '/opt/borj');
      expect(verifier.paths, <String>['/opt/borj']);
    });

    test('wraps source failure with its original cause and stack', () async {
      final cause = StateError('PRIVATE_SOURCE_FAILURE');
      final stackTrace = StackTrace.fromString('source-stack-marker');
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source.failure(cause, stackTrace),
      );

      LinuxExecutablePathException? actual;
      try {
        await validated.resolve();
      } on LinuxExecutablePathException catch (error) {
        actual = error;
      }

      final exception = actual!;
      expect(exception.failure, LinuxExecutablePathFailure.resolutionFailed);
      expect(exception.cause, same(cause));
      expect(
        exception.causeStackTrace.toString(),
        contains('source-stack-marker'),
      );
      expect(exception.toString(), isNot(contains('PRIVATE_SOURCE_FAILURE')));
    });

    test('wraps verifier failure without exposing path or message', () async {
      const path = '/private/user/location/borj';
      final cause = StateError('PRIVATE_VERIFIER_FAILURE');
      final stackTrace = StackTrace.fromString('verifier-stack-marker');
      final validated = ValidatedLinuxExecutablePathSource(
        source: _Source(path),
        verifier: _Verifier.failure(cause, stackTrace),
      );

      LinuxExecutablePathException? actual;
      try {
        await validated.resolve();
      } on LinuxExecutablePathException catch (error) {
        actual = error;
      }

      final exception = actual!;
      expect(exception.failure, LinuxExecutablePathFailure.verificationFailed);
      expect(exception.cause, same(cause));
      expect(
        exception.causeStackTrace.toString(),
        contains('verifier-stack-marker'),
      );
      expect(exception.toString(), isNot(contains(path)));
      expect(exception.toString(), isNot(contains('PRIVATE_VERIFIER_FAILURE')));
    });
  });
}

final class _Source implements LinuxExecutablePathSource {
  _Source(this.path) : error = null, errorStackTrace = null;

  _Source.failure(this.error, this.errorStackTrace) : path = null;

  final String? path;
  final Object? error;
  final StackTrace? errorStackTrace;
  int resolveCount = 0;

  @override
  Future<String> resolve() async {
    resolveCount += 1;
    final configuredError = error;
    if (configuredError != null) {
      Error.throwWithStackTrace(
        configuredError,
        errorStackTrace ?? StackTrace.current,
      );
    }
    return path!;
  }
}

final class _Verifier implements LinuxExecutableFileVerifier {
  _Verifier(this.result) : error = null, errorStackTrace = null;

  _Verifier.failure(this.error, this.errorStackTrace) : result = null;

  final LinuxExecutableFileStatus? result;
  final Object? error;
  final StackTrace? errorStackTrace;
  final List<String> paths = <String>[];

  @override
  Future<LinuxExecutableFileStatus> status(String path) async {
    paths.add(path);
    final configuredError = error;
    if (configuredError != null) {
      Error.throwWithStackTrace(
        configuredError,
        errorStackTrace ?? StackTrace.current,
      );
    }
    return result!;
  }
}
