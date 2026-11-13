import 'dart:async';

import 'package:borj/app/design/design.dart';
import 'package:borj/features/tasks/application/tasks_screen_providers.dart';
import 'package:flutter/widgets.dart';

void _report(Object error, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'tasks screen',
    ),
  );
}

/// Commits [handle] and reports a failure to Flutter's error log.
void commitDeletion(PendingDeletion handle) {
  unawaited(handle.commit().catchError(_report));
}

/// Shows the undo toast of a deferred delete: undo shows the tasks again, the
/// toast going away commits the delete. Without a mounted [context] there is
/// nowhere to show the toast, so the delete commits at once. A null or empty
/// [handle] shows nothing.
void showDeletionUndoToast(
  BuildContext context,
  PendingDeletion? handle, {
  required String message,
}) {
  if (handle == null || handle.tasks.isEmpty) return;
  if (!context.mounted) {
    commitDeletion(handle);
    return;
  }
  showUndoToast(
    context,
    message: message,
    onUndo: handle.undo,
    onDismissed: () => commitDeletion(handle),
  );
}
