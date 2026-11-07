import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_appearance_preferences_store.dart';
import '../domain/appearance_preferences.dart';

/// Overridden in `bootstrapApp` with the file store.
final appearancePreferencesStoreProvider = Provider<AppearancePreferencesStore>(
  (ref) => InMemoryAppearancePreferencesStore(),
);

/// Overridden in `bootstrapApp` with the value loaded before `runApp`.
final initialAppearancePreferencesProvider = Provider<AppearancePreferences>(
  (ref) => AppearancePreferences.defaults,
);

final appearancePreferencesProvider =
    NotifierProvider<AppearancePreferencesController, AppearancePreferences>(
      AppearancePreferencesController.new,
    );

final class AppearancePreferencesController
    extends Notifier<AppearancePreferences> {
  @override
  AppearancePreferences build() =>
      ref.watch(initialAppearancePreferencesProvider);

  Future<void> setMode(AppearanceMode mode) =>
      _update(state.copyWith(mode: mode));

  /// Updates the intensity in memory only. Call from the slider's `onChanged`.
  void previewGlassIntensity(double value) {
    state = state.copyWith(glassIntensity: value);
  }

  /// Saves the current state. Call from the slider's `onChangeEnd`.
  Future<void> commitGlassIntensity() => _save(state);

  /// Preview plus commit, for callers that are not a slider.
  Future<void> setGlassIntensity(double value) {
    previewGlassIntensity(value);
    return commitGlassIntensity();
  }

  Future<void> setReduceMotion(bool value) =>
      _update(state.copyWith(reduceMotion: value));

  Future<void> setReduceTransparency(bool value) =>
      _update(state.copyWith(reduceTransparency: value));

  Future<void> _update(AppearancePreferences next) async {
    state = next;
    await _save(next);
  }

  Future<void> _save(AppearancePreferences next) async {
    try {
      await ref.read(appearancePreferencesStoreProvider).save(next);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'appearance preferences',
          context: ErrorDescription('while saving appearance preferences'),
        ),
      );
    }
  }
}
