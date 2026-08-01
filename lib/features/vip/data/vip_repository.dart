import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../models/app_user.dart';
import 'vip_iap_service.dart';

/// A store-purchase outcome, surfaced asynchronously since
/// [VipRepository.buyWithMoney] only starts the store flow — the actual
/// result (success/failure) arrives later via the purchase stream.
sealed class VipPurchaseUpdate {
  const VipPurchaseUpdate();
}

class VipPurchaseSucceeded extends VipPurchaseUpdate {
  const VipPurchaseSucceeded(this.level, this.vipExpiresAt);
  final VipLevel level;
  final DateTime vipExpiresAt;
}

class VipPurchaseFailed extends VipPurchaseUpdate {
  const VipPurchaseFailed(this.message);
  final String message;
}

/// Handles both ways to acquire VIP: spending coins (Bronze/Silver only,
/// instant — see `purchaseVipWithCoins`) and real-money store purchases (all
/// four tiers — see `verifyVipPurchase`). The store path only ever starts the
/// purchase here; [purchaseEvents] reports how it eventually resolved once
/// the backend has verified the receipt.
class VipRepository {
  VipRepository(this._functions, this._iap) {
    _sub = _iap.purchaseUpdates.listen(_onPurchaseUpdate);
  }

  final FirebaseFunctions _functions;
  final VipIapService _iap;
  late final StreamSubscription<List<PurchaseDetails>> _sub;

  final _events = StreamController<VipPurchaseUpdate>.broadcast();
  Stream<VipPurchaseUpdate> get purchaseEvents => _events.stream;

  /// Instantly buys/renews Bronze or Silver with coins.
  Future<Result<void>> purchaseWithCoins(VipLevel level) async {
    try {
      await _functions
          .httpsCallable('purchaseVipWithCoins')
          .call<Map<String, dynamic>>({'level': level.name});
      return const Result.success(null);
    } catch (e, s) {
      log.e('purchaseVipWithCoins failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Loads the store's localized price for a tier, or null if the store
  /// hasn't been configured with that product yet (see docs/DEPLOYMENT.md).
  Future<ProductDetails?> loadProduct(VipLevel level) async {
    final productId = AppConstants.vipIapProductIds[level.name];
    if (productId == null) return null;
    final products = await _iap.loadProducts({productId});
    for (final p in products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  /// Starts the real-money store purchase flow for any tier. The result
  /// (success/failure) is reported later on [purchaseEvents], once the store
  /// confirms the purchase and the backend has verified it.
  Future<Result<void>> buyWithMoney(VipLevel level) async {
    try {
      if (!await _iap.isAvailable) {
        return const Result.failure(
          OperationFailure(
            'In-app purchases are not available on this device.',
            code: 'iap/unavailable',
          ),
        );
      }
      final product = await loadProduct(level);
      if (product == null) {
        return const Result.failure(
          OperationFailure(
            'This VIP plan is not set up in the store yet.',
            code: 'iap/not-found',
          ),
        );
      }
      await _iap.buy(product);
      return const Result.success(null);
    } catch (e, s) {
      log.e('VIP buyWithMoney failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.canceled:
          await _iap.completePurchase(purchase);
        case PurchaseStatus.error:
          _events.add(
            VipPurchaseFailed(purchase.error?.message ?? 'Purchase failed.'),
          );
          await _iap.completePurchase(purchase);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verify(purchase);
          await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verify(PurchaseDetails purchase) async {
    final level = _levelForProductId(purchase.productID);
    if (level == null) return;
    try {
      final res = await _functions
          .httpsCallable('verifyVipPurchase')
          .call<Map<String, dynamic>>({
        'level': level.name,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
      });
      final expiresAtMs = res.data['vipExpiresAt'] as int?;
      _events.add(
        VipPurchaseSucceeded(
          level,
          expiresAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
              : DateTime.now()
                  .add(const Duration(days: AppConstants.vipDurationDays)),
        ),
      );
    } catch (e, s) {
      log.e('verifyVipPurchase failed', e, s);
      _events.add(VipPurchaseFailed(FirebaseErrorMapper.map(e, s).message));
    }
  }

  VipLevel? _levelForProductId(String productId) {
    for (final entry in AppConstants.vipIapProductIds.entries) {
      if (entry.value != productId) continue;
      for (final level in VipLevel.values) {
        if (level.name == entry.key) return level;
      }
    }
    return null;
  }

  void dispose() {
    _sub.cancel();
    _events.close();
  }
}

final vipRepositoryProvider = Provider<VipRepository>((ref) {
  final repo = VipRepository(
    ref.watch(functionsProvider),
    ref.watch(vipIapServiceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// UI-facing stream of how a store purchase eventually resolved (crediting
/// itself already happened server-side by the time this fires — see
/// `VipRepository._verify` — this is purely so the open screen can react).
final vipPurchaseEventsProvider = StreamProvider<VipPurchaseUpdate>((ref) {
  return ref.watch(vipRepositoryProvider).purchaseEvents;
});
