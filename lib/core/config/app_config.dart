import 'package:flutter/foundation.dart';

/// Build flavour. Controls emulator usage, test-ad units and API endpoints.
enum AppFlavor { dev, staging, prod }

/// Immutable, compile-time configuration resolved from `--dart-define` values
/// so no secrets are hard-coded in source. Sensible defaults keep local dev
/// frictionless while production overrides come from the CI build command.
///
/// Example:
/// ```
/// flutter build appbundle \
///   --dart-define=FLAVOR=prod \
///   --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=OFFERWALL_APP_ID=zzz
/// ```
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.useEmulators,
    required this.admobRewardedAndroid,
    required this.admobRewardedInterstitialAndroid,
    required this.admobAppOpenAndroid,
    required this.offerwallAppId,
    required this.offerwallBaseUrl,
    required this.supportEmail,
    required this.privacyUrl,
    required this.termsUrl,
    required this.minWithdrawCoins,
    required this.appStoreId,
  });

  final AppFlavor flavor;
  final bool useEmulators;

  // AdMob unit ids. Defaults are Google's official TEST unit ids so the app is
  // never shipped serving live ads by accident in dev/staging.
  final String admobRewardedAndroid;
  final String admobRewardedInterstitialAndroid;
  final String admobAppOpenAndroid;

  // Offerwall (e.g. AdGate / Bitlabs / OfferToro). The signed URL is built by a
  // Cloud Function; the client only needs the public app id + base url.
  final String offerwallAppId;
  final String offerwallBaseUrl;

  final String supportEmail;
  final String privacyUrl;
  final String termsUrl;
  final int minWithdrawCoins;
  final String appStoreId;

  bool get isProd => flavor == AppFlavor.prod;
  bool get isDev => flavor == AppFlavor.dev;

  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedInterstitial =
      'ca-app-pub-3940256099942544/5354046379';
  static const _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';

  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final flavor = AppFlavor.values.firstWhere(
      (f) => f.name == flavorName,
      orElse: () => AppFlavor.dev,
    );
    final isProd = flavor == AppFlavor.prod;

    return AppConfig(
      flavor: flavor,
      useEmulators: const bool.fromEnvironment('USE_EMULATORS',
              defaultValue: false) &&
          !isProd,
      admobRewardedAndroid: const String.fromEnvironment(
        'ADMOB_REWARDED_ANDROID',
        defaultValue: _testRewarded,
      ),
      admobRewardedInterstitialAndroid: const String.fromEnvironment(
        'ADMOB_REWARDED_INTERSTITIAL_ANDROID',
        defaultValue: _testRewardedInterstitial,
      ),
      admobAppOpenAndroid: const String.fromEnvironment(
        'ADMOB_APP_OPEN_ANDROID',
        defaultValue: _testAppOpen,
      ),
      offerwallAppId:
          const String.fromEnvironment('OFFERWALL_APP_ID', defaultValue: ''),
      offerwallBaseUrl: const String.fromEnvironment(
        'OFFERWALL_BASE_URL',
        defaultValue: 'https://wall.example.com',
      ),
      supportEmail: const String.fromEnvironment(
        'SUPPORT_EMAIL',
        defaultValue: 'support@robuxbox.app',
      ),
      // Served by Firebase Hosting from public/ (see tool/build_legal_pages.py).
      // Google Play requires a publicly reachable privacy-policy URL, and this
      // domain exists as soon as `firebase deploy --only hosting` has run — no
      // custom domain purchase needed. Override via --dart-define once a
      // branded domain is pointed at the same Hosting site.
      privacyUrl: const String.fromEnvironment(
        'PRIVACY_URL',
        defaultValue: 'https://robux-box.web.app/privacy',
      ),
      termsUrl: const String.fromEnvironment(
        'TERMS_URL',
        defaultValue: 'https://robux-box.web.app/terms',
      ),
      minWithdrawCoins:
          const int.fromEnvironment('MIN_WITHDRAW_COINS', defaultValue: 1000),
      appStoreId:
          const String.fromEnvironment('APP_STORE_ID', defaultValue: ''),
    );
  }
}
