import 'package:borj/core/notifications/notification_platform_providers.dart';
import 'package:borj/core/notifications/notification_startup_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class NotificationStartupFailureReporter {
  void report(Object error, StackTrace stackTrace);
}

final class FlutterNotificationStartupFailureReporter
    implements NotificationStartupFailureReporter {
  const FlutterNotificationStartupFailureReporter();

  @override
  void report(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'borj.notifications',
        context: ErrorDescription(
          'while reconciling persisted notifications at application startup',
        ),
      ),
    );
  }
}

final class NotificationStartupBootstrap extends ConsumerStatefulWidget {
  const NotificationStartupBootstrap({
    required this.startupProvider,
    required this.child,
    this.reporter = const FlutterNotificationStartupFailureReporter(),
    super.key,
  });

  final ProviderListenable<NotificationStartup> startupProvider;
  final NotificationStartupFailureReporter reporter;
  final Widget child;

  @override
  ConsumerState<NotificationStartupBootstrap> createState() {
    return _NotificationStartupBootstrapState();
  }
}

final class _NotificationStartupBootstrapState
    extends ConsumerState<NotificationStartupBootstrap> {
  ProviderSubscription<AsyncValue<void>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(NotificationStartupBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.startupProvider != widget.startupProvider) {
      _subscription?.close();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = ref.listenManual<AsyncValue<void>>(
      notificationStartupProvider(widget.startupProvider),
      (previous, next) {
        if (next case AsyncError(:final error, :final stackTrace)) {
          widget.reporter.report(error, stackTrace);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
