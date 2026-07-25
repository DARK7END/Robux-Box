import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/preferences_service.dart';

/// The locales the app ships translations for. English is the base; Arabic is
/// fully translated. Add a new `app_<code>.arb` and list its [Locale] here to
/// support more languages — the rest of the app needs no changes.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ar'),
];

/// Controls the active locale.
///
/// `null` means "follow the device language": Flutter resolves the best match
/// from [kSupportedLocales] against the platform locales, falling back to
/// English. A user can override this in Settings, and the choice is persisted.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final saved = ref.watch(preferencesProvider).locale;
    if (saved == null) return null; // follow device
    return Locale(saved);
  }

  Future<void> setLocale(Locale? locale) async {
    await ref.read(preferencesProvider).setLocale(locale?.languageCode);
    state = locale;
  }

  /// Resolves the effective locale for RTL checks etc., accounting for the
  /// device fallback when [state] is null.
  Locale effectiveLocale() {
    if (state != null) return state!;
    final device = PlatformDispatcher.instance.locale;
    final match = kSupportedLocales.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => const Locale('en'),
    );
    return match;
  }

  bool get isRtl => _rtlLanguages.contains(effectiveLocale().languageCode);

  static const Set<String> _rtlLanguages = {'ar', 'he', 'fa', 'ur'};
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
