import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';

final class RecordedLinuxProcessCall {
  const RecordedLinuxProcessCall({
    required this.sequence,
    required this.request,
    required this.cancellationToken,
  });

  final int sequence;
  final LinuxProcessRequest request;
  final LinuxCancellationToken? cancellationToken;
}

final class RecordingLinuxProcessRunner implements LinuxProcessRunner {
  RecordingLinuxProcessRunner(this._delegate);

  final LinuxProcessRunner _delegate;
  final List<RecordedLinuxProcessCall> _calls = <RecordedLinuxProcessCall>[];

  int _nextSequence = 0;

  List<RecordedLinuxProcessCall> get calls =>
      List<RecordedLinuxProcessCall>.unmodifiable(_calls);

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) {
    final snapshot = LinuxProcessRequest(
      executable: request.executable,
      arguments: request.arguments,
      environment: request.environment,
      timeout: request.timeout,
      terminationGracePeriod: request.terminationGracePeriod,
      stdoutLimitBytes: request.stdoutLimitBytes,
      stderrLimitBytes: request.stderrLimitBytes,
      includeParentEnvironment: request.includeParentEnvironment,
    );

    _calls.add(
      RecordedLinuxProcessCall(
        sequence: _nextSequence++,
        request: snapshot,
        cancellationToken: cancellationToken,
      ),
    );

    return _delegate.run(request, cancellationToken: cancellationToken);
  }
}
