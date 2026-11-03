import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Collects startup and runtime errors so the spike apps can show them on
/// screen instead of failing silently.
final ValueNotifier<List<String>> spikeErrors = ValueNotifier<List<String>>(
  const <String>[],
);

void recordSpikeError(String where, Object error, StackTrace? stack) {
  final text = '$where: $error\n${(stack ?? StackTrace.empty).toString().split('\n').take(6).join('\n')}';
  spikeErrors.value = <String>[...spikeErrors.value, text];
}

void installSpikeErrorHooks() {
  FlutterError.onError = (details) {
    recordSpikeError('FlutterError', details.exceptionAsString(), details.stack);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    recordSpikeError('PlatformDispatcher', error, stack);
    return true;
  };
}

/// MaterialApp.builder that overlays any recorded errors in red.
Widget spikeErrorOverlay(BuildContext context, Widget? child) {
  return Stack(
    textDirection: TextDirection.ltr,
    children: <Widget>[
      if (child != null) Positioned.fill(child: child),
      ValueListenableBuilder<List<String>>(
        valueListenable: spikeErrors,
        builder: (context, errors, _) {
          if (errors.isEmpty) {
            return const SizedBox.shrink();
          }
          return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xE6000000),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      errors.join('\n---\n'),
                      style: const TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
