import '../domain/appearance_preferences.dart';

/// Non-persistent store used when nothing overrides the provider (tests).
final class InMemoryAppearancePreferencesStore
    implements AppearancePreferencesStore {
  InMemoryAppearancePreferencesStore([
    this._value = AppearancePreferences.defaults,
  ]);

  AppearancePreferences _value;

  @override
  Future<AppearancePreferences> load() async => _value;

  @override
  Future<void> save(AppearancePreferences value) async => _value = value;
}
