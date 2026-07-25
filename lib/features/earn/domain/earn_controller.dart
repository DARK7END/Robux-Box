import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/services/ads_service.dart';
import '../data/earn_repository.dart';

/// Orchestrates the full rewarded-ad flow across [AdsService] and
/// [EarnRepository]:
///   begin (server nonce) → show ad (AdMob) → confirm (server credit).
///
/// Every step is server-authoritative; the UI only reflects progress and the
/// final [EarnResult].
class EarnController extends AsyncNotifier<EarnResult?> {
  @override
  Future<EarnResult?> build() async => null;

  Future<Result<EarnResult>> watchRewardedAd() async {
    state = const AsyncLoading();
    final repo = ref.read(earnRepositoryProvider);
    final ads = ref.read(adsServiceProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;

    if (uid == null) {
      const f = AuthFailure('Please sign in first.', code: 'auth/required');
      state = AsyncError(f, StackTrace.current);
      return const Result.failure(f);
    }

    // 1) Server issues a single-use nonce bound to this user + device.
    final begin = await repo.beginRewardedAd();
    if (begin case Err(:final failure)) {
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }
    final nonce = (begin as Success<String>).value;

    // 2) Show the ad, passing the nonce as SSV custom data.
    final shown = await ads.show(userId: uid, verificationNonce: nonce);
    if (shown case Err(:final failure)) {
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    // 3) Confirm server-side; the backend decides the tier-adjusted amount.
    final confirmed = await repo.confirmRewardedAd(nonce);
    return confirmed.when(
      success: (result) {
        state = AsyncData(result);
        return Result.success(result);
      },
      failure: (f) {
        state = AsyncError(f, StackTrace.current);
        return Result.failure(f);
      },
    );
  }

  Future<Result<EarnResult>> claimDaily() =>
      _wrap(() => ref.read(earnRepositoryProvider).claimDailyReward());

  Future<Result<EarnResult>> redeemPromocode(String code) =>
      _wrap(() => ref.read(earnRepositoryProvider).redeemPromocode(code));

  Future<Result<EarnResult>> _wrap(
      Future<Result<EarnResult>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.when(
      success: (r) {
        state = AsyncData(r);
        return Result.success(r);
      },
      failure: (f) {
        state = AsyncError(f, StackTrace.current);
        return Result.failure(f);
      },
    );
  }
}

final earnControllerProvider =
    AsyncNotifierProvider<EarnController, EarnResult?>(EarnController.new);

/// Streams whether a rewarded ad is currently loaded and ready to show.
final adReadyProvider = StreamProvider<bool>((ref) {
  final ads = ref.watch(adsServiceProvider);
  return ads.readyStream;
});
