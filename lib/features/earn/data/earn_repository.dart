import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/services/geo_tier_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/utils/logger.dart';

/// The authoritative result of an earn action, returned by the backend.
class EarnResult {
  const EarnResult({
    required this.coinsCredited,
    required this.newBalance,
    required this.xpGained,
    required this.message,
    this.prizeIndex,
  });

  final int coinsCredited;
  final int newBalance;
  final int xpGained;
  final String message;

  /// For daily games: the winning segment index the wheel/chest should land on.
  final int? prizeIndex;

  factory EarnResult.fromMap(Map<String, dynamic> map) => EarnResult(
        coinsCredited: (map['coinsCredited'] as num?)?.toInt() ?? 0,
        newBalance: (map['newBalance'] as num?)?.toInt() ?? 0,
        xpGained: (map['xpGained'] as num?)?.toInt() ?? 0,
        message: (map['message'] ?? '').toString(),
        prizeIndex: (map['prizeIndex'] as num?)?.toInt(),
      );
}

/// All coin-earning calls go through Cloud Functions. The client never writes to
/// the wallet directly — it can only *request* a credit, which the backend
/// validates (rate limits, tier, device integrity, ad SSV) before applying it
/// inside a transaction. This is the core of the anti-fraud design.
class EarnRepository {
  EarnRepository(this._functions, this._security, this._geo);

  final FirebaseFunctions _functions;
  final SecurityService _security;
  final GeoTierService _geo;

  /// Step 1 of a rewarded-ad session: ask the backend for a single-use,
  /// server-signed nonce to attach to the AdMob SSV callback. This binds the
  /// impression to this user + device and prevents reward replay.
  Future<Result<String>> beginRewardedAd() async {
    try {
      final device = await _security.collect();
      final res = await _functions
          .httpsCallable('beginRewardedAd')
          .call<Map<String, dynamic>>({'device': device.toMap()});
      final nonce = (res.data['nonce'] ?? '').toString();
      return nonce.isEmpty
          ? const Result.failure(
              OperationFailure('Could not start ad session.',
                  code: 'ads/no-nonce'))
          : Result.success(nonce);
    } catch (e, s) {
      log.e('beginRewardedAd failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Step 2: confirm the completed impression. The backend cross-checks the
  /// AdMob server-side verification, the geo-tier and rate limits, then credits
  /// the tier-adjusted amount.
  Future<Result<EarnResult>> confirmRewardedAd(String nonce) async {
    try {
      final geo = await _geo.resolve();
      final signed = await _security.signEarn(
        action: 'rewarded_ad',
        payload: {'nonce': nonce, 'geo': geo.toRequest()},
      );
      final res = await _functions
          .httpsCallable('confirmRewardedAd')
          .call<Map<String, dynamic>>(signed.toMap());
      return Result.success(EarnResult.fromMap(res.data));
    } catch (e, s) {
      log.e('confirmRewardedAd failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<EarnResult>> claimDailyReward() async {
    try {
      final signed = await _security.signEarn(action: 'daily_claim', payload: {});
      final res = await _functions
          .httpsCallable('claimDailyReward')
          .call<Map<String, dynamic>>(signed.toMap());
      return Result.success(EarnResult.fromMap(res.data));
    } catch (e, s) {
      log.e('claimDailyReward failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<EarnResult>> redeemPromocode(String code) async {
    try {
      final res = await _functions
          .httpsCallable('redeemPromocode')
          .call<Map<String, dynamic>>({'code': code.trim().toUpperCase()});
      return Result.success(EarnResult.fromMap(res.data));
    } catch (e, s) {
      log.e('redeemPromocode failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Plays a daily free game ('spin' or 'chest'); the backend awards the prize
  /// and returns the winning segment index for the animation.
  Future<Result<EarnResult>> playDailyGame(String game) async {
    try {
      final res = await _functions
          .httpsCallable('playDailyGame')
          .call<Map<String, dynamic>>({'game': game});
      return Result.success(EarnResult.fromMap(res.data));
    } catch (e, s) {
      log.e('playDailyGame failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Reports the resolved geo-tier so the backend can update the account's
  /// country of record (used to validate all future earns).
  Future<Result<void>> reportTier() async {
    try {
      final geo = await _geo.resolve();
      await _functions
          .httpsCallable('resolveTier')
          .call<Map<String, dynamic>>(geo.toRequest());
      return const Result.success(null);
    } catch (e, s) {
      log.w('reportTier failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }
}

final earnRepositoryProvider = Provider<EarnRepository>((ref) {
  return EarnRepository(
    ref.watch(functionsProvider),
    ref.watch(securityServiceProvider),
    ref.watch(geoTierServiceProvider),
  );
});
