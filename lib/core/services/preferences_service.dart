import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences] for non-sensitive local settings
/// (theme, locale, onboarding-seen flags). Secrets/tokens use
/// `SecureStorageService` instead.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'pref_theme_mode';
  static const _kLocale = 'pref_locale';
  static const _kOnboardingSeen = 'pref_onboarding_seen';
  static const _kTrackingAsked = 'pref_tracking_asked';

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  String? get locale => _prefs.getString(_kLocale);
  Future<void> setLocale(String? value) => value == null
      ? _prefs.remove(_kLocale)
      : _prefs.setString(_kLocale, value);

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);

  bool get trackingAsked => _prefs.getBool(_kTrackingAsked) ?? false;
  Future<void> setTrackingAsked(bool value) =>
      _prefs.setBool(_kTrackingAsked, value);
}

/// Overridden in `main()` after `SharedPreferences.getInstance()` resolves.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final preferencesProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});
