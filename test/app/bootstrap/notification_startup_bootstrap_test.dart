import 'dart:async';

import 'package:dashboard_shakhsi/app/bootstrap/notification_startup_bootstrap.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_platform_providers.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_startup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationStartupProvider', () {
    test(
      'repeated reads share one startup future in one provider scope',
      () async {
        final startup = _ControlledStartup();
        final startupProvider = Provider<NotificationStartup>((ref) => startup);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final first = container.read(
          notificationStartupProvider(startupProvider).future,
        );
        final second = container.read(
          notificationStartupProvider(startupProvider).future,
        );

        expect(identical(first, second), isTrue);

        await Future<void>.delayed(Duration.zero);
        expect(startup.calls, 1);

        startup.complete();
        await Future.wait<void>(<Future<void>>[first, second]);

        expect(startup.calls, 1);
      },
    );

    test('a new provider scope can retry a failed startup', () async {
      final startup = _RetryingStartup();
      final startupProvider = Provider<NotificationStartup>((ref) => startup);

      final firstContainer = ProviderContainer();
      await expectLater(
        firstContainer.read(
          notificationStartupProvider(startupProvider).future,
        ),
        throwsStateError,
      );
      firstContainer.dispose();

      final secondContainer = ProviderContainer();
      addTearDown(secondContainer.dispose);

      await secondContainer.read(
        notificationStartupProvider(startupProvider).future,
      );

      expect(startup.calls, 2);
    });
  });

  group('NotificationStartupBootstrap', () {
    testWidgets('renders the application while reconciliation is pending', (
      tester,
    ) async {
      final startup = _ControlledStartup();
      final startupProvider = Provider<NotificationStartup>((ref) => startup);
      final reporter = _RecordingReporter();

      await tester.pumpWidget(
        ProviderScope(
          child: NotificationStartupBootstrap(
            startupProvider: startupProvider,
            reporter: reporter,
            child: const MaterialApp(
              home: Scaffold(body: Text('dashboard-ready')),
            ),
          ),
        ),
      );

      expect(find.text('dashboard-ready'), findsOneWidget);
      expect(startup.calls, 1);
      expect(reporter.failures, isEmpty);

      startup.complete();
      await tester.pump();
    });

    testWidgets('keeps the application rendered after startup failure', (
      tester,
    ) async {
      final error = StateError('PRIVATE_RECONCILIATION_FAILURE');
      final stackTrace = StackTrace.fromString('reconcile-stack-marker');
      final startup = _FailingStartup(error, stackTrace);
      final startupProvider = Provider<NotificationStartup>((ref) => startup);
      final reporter = _RecordingReporter();

      await tester.pumpWidget(
        ProviderScope(
          child: NotificationStartupBootstrap(
            startupProvider: startupProvider,
            reporter: reporter,
            child: const MaterialApp(
              home: Scaffold(body: Text('dashboard-still-ready')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('dashboard-still-ready'), findsOneWidget);
      expect(reporter.failures, hasLength(1));
      expect(reporter.failures.single.error, same(error));
      expect(
        reporter.failures.single.stackTrace.toString(),
        contains('reconcile-stack-marker'),
      );
    });

    testWidgets('rebuilds do not start duplicate reconciliation', (
      tester,
    ) async {
      final startup = _ControlledStartup();
      final startupProvider = Provider<NotificationStartup>((ref) => startup);
      final reporter = _RecordingReporter();
      var generation = 0;
      late StateSetter rebuild;

      await tester.pumpWidget(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NotificationStartupBootstrap(
                key: ValueKey<int>(generation),
                startupProvider: startupProvider,
                reporter: reporter,
                child: const MaterialApp(
                  home: Scaffold(body: Text('stable-dashboard')),
                ),
              );
            },
          ),
        ),
      );

      expect(startup.calls, 1);

      rebuild(() {
        generation += 1;
      });
      await tester.pump();

      expect(find.text('stable-dashboard'), findsOneWidget);
      expect(startup.calls, 1);

      startup.complete();
      await tester.pump();
    });

    testWidgets('reports one failure despite repeated widget rebuilds', (
      tester,
    ) async {
      final error = StateError('PRIVATE_RECONCILIATION_FAILURE');
      final stackTrace = StackTrace.fromString('single-report-stack');
      final startup = _FailingStartup(error, stackTrace);
      final startupProvider = Provider<NotificationStartup>((ref) => startup);
      final reporter = _RecordingReporter();
      late StateSetter rebuild;

      await tester.pumpWidget(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NotificationStartupBootstrap(
                startupProvider: startupProvider,
                reporter: reporter,
                child: const MaterialApp(
                  home: Scaffold(body: Text('report-once-dashboard')),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      rebuild(() {});
      await tester.pump();

      expect(find.text('report-once-dashboard'), findsOneWidget);
      expect(reporter.failures, hasLength(1));
    });

    testWidgets('changing startup provider subscribes to the new scope work', (
      tester,
    ) async {
      final first = _ControlledStartup();
      final second = _ControlledStartup();
      final firstProvider = Provider<NotificationStartup>((ref) => first);
      final secondProvider = Provider<NotificationStartup>((ref) => second);
      final reporter = _RecordingReporter();
      var activeProvider = firstProvider;
      late StateSetter switchProvider;

      await tester.pumpWidget(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              switchProvider = setState;
              return NotificationStartupBootstrap(
                startupProvider: activeProvider,
                reporter: reporter,
                child: const MaterialApp(
                  home: Scaffold(body: Text('switchable-dashboard')),
                ),
              );
            },
          ),
        ),
      );

      expect(first.calls, 1);
      expect(second.calls, 0);

      switchProvider(() {
        activeProvider = secondProvider;
      });
      await tester.pump();

      expect(first.calls, 1);
      expect(second.calls, 1);

      first.complete();
      second.complete();
      await tester.pump();
    });
  });
}

final class _ControlledStartup implements NotificationStartup {
  final Completer<void> _completer = Completer<void>();
  int calls = 0;

  @override
  Future<void> initialize() {
    calls += 1;
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

final class _RetryingStartup implements NotificationStartup {
  int calls = 0;

  @override
  Future<void> initialize() async {
    calls += 1;
    if (calls == 1) {
      throw StateError('first startup failed');
    }
  }
}

final class _FailingStartup implements NotificationStartup {
  _FailingStartup(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
  int calls = 0;

  @override
  Future<void> initialize() {
    calls += 1;
    return Future<void>.error(error, stackTrace);
  }
}

final class _Failure {
  const _Failure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

final class _RecordingReporter implements NotificationStartupFailureReporter {
  final List<_Failure> failures = <_Failure>[];

  @override
  void report(Object error, StackTrace stackTrace) {
    failures.add(_Failure(error, stackTrace));
  }
}
