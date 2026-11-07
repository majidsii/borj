import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingStore implements AppearancePreferencesStore {
  @override
  Future<AppearancePreferences> load() async => AppearancePreferences.defaults;

  @override
  Future<void> save(AppearancePreferences value) async =>
      throw StateError('disk full');
}

void main() {
  test('starts from the loaded preferences and persists changes', () async {
    final store = InMemoryAppearancePreferencesStore();
    final container = ProviderContainer(
      overrides: [
        appearancePreferencesStoreProvider.overrideWithValue(store),
        initialAppearancePreferencesProvider.overrideWithValue(
          const AppearancePreferences(mode: AppearanceMode.dark),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appearancePreferencesProvider).mode,
      AppearanceMode.dark,
    );

    final controller = container.read(appearancePreferencesProvider.notifier);
    await controller.setMode(AppearanceMode.light);
    await controller.setGlassIntensity(0.9);
    await controller.setReduceMotion(true);
    await controller.setReduceTransparency(true);

    const expected = AppearancePreferences(
      mode: AppearanceMode.light,
      glassIntensity: 0.9,
      reduceMotion: true,
      reduceTransparency: true,
    );
    expect(container.read(appearancePreferencesProvider), expected);
    expect(await store.load(), expected);
  });

  test('a failed save keeps the new state and reports the error', () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    final container = ProviderContainer(
      overrides: [
        appearancePreferencesStoreProvider.overrideWithValue(_FailingStore()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appearancePreferencesProvider.notifier)
        .setMode(AppearanceMode.dark);

    expect(
      container.read(appearancePreferencesProvider).mode,
      AppearanceMode.dark,
    );
    expect(errors.single.exception, isA<StateError>());
  });

  group('glass intensity persistence', () {
    late InMemoryAppearancePreferencesStore store;
    late ProviderContainer container;

    setUp(() {
      store = InMemoryAppearancePreferencesStore();
      container = ProviderContainer(
        overrides: [
          appearancePreferencesStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
    });

    test('preview changes state without saving; commit persists', () async {
      final controller = container.read(appearancePreferencesProvider.notifier);

      controller.previewGlassIntensity(0.9);

      expect(container.read(appearancePreferencesProvider).glassIntensity, 0.9);
      expect((await store.load()).glassIntensity, 0.5);

      await controller.commitGlassIntensity();

      expect((await store.load()).glassIntensity, 0.9);
    });

    test('setGlassIntensity previews and commits', () async {
      await container
          .read(appearancePreferencesProvider.notifier)
          .setGlassIntensity(0.2);

      expect(container.read(appearancePreferencesProvider).glassIntensity, 0.2);
      expect((await store.load()).glassIntensity, 0.2);
    });
  });
}
