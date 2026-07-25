import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../config/providers.dart';
import '../error/failure.dart';
import '../error/result.dart';
import '../utils/logger.dart';

/// Manages Google AdMob rewarded ads.
///
/// Responsibilities:
///  * Preload a rewarded ad so "Watch ad" is instant.
///  * Surface load/ready state to the UI.
///  * Report the AdMob `RewardItem` **and** the server-side verification SSV
///    identifier so the backend, not the client, decides the payout. The client
///    never credits coins directly — it calls a Cloud Function with the ad's
///    verification data.
class AdsService {
  AdsService(this._config);

  final AppConfig _config;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  DateTime? _lastShownAt;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get readyStream => _readyController.stream;
  bool get isReady => _rewardedAd != null;

  /// Initialise the Mobile Ads SDK. Called once from bootstrap.
  Future<void> init() async {
    await MobileAds.instance.initialize();
    // In non-prod flavours restrict to test devices so we never risk policy
    // strikes from clicking live ads during QA.
    if (!_config.isProd) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: const ['EMULATOR']),
      );
    }
    unawaited(load());
  }

  /// Preloads a rewarded ad. Safe to call repeatedly; no-ops while one is loaded
  /// or loading.
  Future<void> load() async {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _config.admobRewardedAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          _readyController.add(true);
          _attachFullScreenCallbacks(ad);
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          log.w('Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
          _isLoading = false;
          _readyController.add(false);
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  void _attachFullScreenCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _readyController.add(false);
        unawaited(load()); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log.w('Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _readyController.add(false);
        unawaited(load());
      },
    );
  }

  /// Sets the Server-Side Verification options so AdMob calls our Cloud Function
  /// callback with the reward. [userId] and [customData] let the backend
  /// attribute and validate the impression (the [customData] carries a signed,
  /// single-use nonce issued by `beginRewardedAd`).
  void _setSsv(RewardedAd ad, String userId, String customData) {
    ad.setServerSideOptions(
      ServerSideVerificationOptions(userId: userId, customData: customData),
    );
  }

  /// Shows the loaded ad. Resolves with the earned [RewardItem] once the user
  /// legitimately completes it. The caller then confirms with the backend.
  Future<Result<AdReward>> show({
    required String userId,
    required String verificationNonce,
    Duration cooldown = const Duration(seconds: 30),
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      unawaited(load());
      return const Result.failure(
        OperationFailure('No ad available right now. Please try again.',
            code: 'ads/not-ready'),
      );
    }
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < cooldown) {
      final remaining =
          cooldown - DateTime.now().difference(_lastShownAt!);
      return Result.failure(
        OperationFailure('Please wait ${remaining.inSeconds}s before the next ad.',
            code: 'ads/cooldown'),
      );
    }

    _setSsv(ad, userId, verificationNonce);
    final completer = Completer<Result<AdReward>>();

    _rewardedAd = null; // consume — callbacks manage disposal/reload
    await ad.show(
      onUserEarnedReward: (adWithoutView, reward) {
        _lastShownAt = DateTime.now();
        completer.complete(
          Result.success(
            AdReward(
              amount: reward.amount.toInt(),
              type: reward.type,
              nonce: verificationNonce,
            ),
          ),
        );
      },
    );

    // If the ad is dismissed without a reward, the future would hang; guard it.
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => const Result.failure(
        OperationFailure('Ad was not completed.', code: 'ads/incomplete'),
      ),
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _readyController.close();
  }
}

/// The reward the client observed; the authoritative amount is still decided by
/// the backend during SSV/confirmation.
class AdReward {
  const AdReward({
    required this.amount,
    required this.type,
    required this.nonce,
  });

  final int amount;
  final String type;
  final String nonce;
}

final adsServiceProvider = Provider<AdsService>((ref) {
  final service = AdsService(ref.watch(appConfigProvider));
  ref.onDispose(service.dispose);
  return service;
});
