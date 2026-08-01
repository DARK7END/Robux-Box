import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/utils/logger.dart';

/// Thin wrapper around the platform store (Google Play Billing / StoreKit) for
/// the VIP subscription products. The client never decides a purchase is
/// valid — it only initiates the store flow here and hands the resulting
/// receipt to `VipRepository`, which forwards it to the `verifyVipPurchase`
/// Cloud Function for server-side verification and crediting.
class VipIapService {
  VipIapService() {
    _sub = _iap.purchaseStream.listen(
      _controller.add,
      onError: (Object e) => log.w('IAP purchase stream error', e),
    );
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  /// Completed/errored/pending purchase updates from the store.
  Stream<List<PurchaseDetails>> get purchaseUpdates => _controller.stream;

  Future<bool> get isAvailable => _iap.isAvailable();

  /// Loads store product details (including the store's own localized price)
  /// for the given product ids.
  Future<List<ProductDetails>> loadProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      log.w('IAP queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      log.w('IAP products not found in store: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  /// Starts the store purchase flow. The outcome arrives asynchronously via
  /// [purchaseUpdates], not this future — subscriptions especially may need
  /// external confirmation (e.g. a parental-consent prompt) before resolving.
  Future<void> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Must be called once a purchase update has been fully handled (verified
  /// or rejected) so the store stops redelivering it on the next launch.
  Future<void> completePurchase(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      return _iap.completePurchase(purchase);
    }
    return Future.value();
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

final vipIapServiceProvider = Provider<VipIapService>((ref) {
  final service = VipIapService();
  ref.onDispose(service.dispose);
  return service;
});
