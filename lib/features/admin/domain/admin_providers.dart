import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../models/promocode.dart';
import '../../../models/redemption.dart';
import '../../../models/reward.dart';
import '../data/admin_repository.dart';

/// Whether the signed-in user holds the `admin` custom claim. Read from the
/// Firebase ID token (set server-side by `setAdminClaim`). Re-evaluated on auth
/// changes; force-refreshes the token so a freshly-granted claim is picked up.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  final token = await user.getIdTokenResult(true);
  return token.claims?['admin'] == true;
});

final adminRedemptionsProvider =
    StreamProvider.family<List<Redemption>, RedemptionStatus?>((ref, status) {
  return ref.watch(adminRepositoryProvider).watchRedemptions(status: status);
});

final adminPromocodesProvider = StreamProvider<List<Promocode>>((ref) {
  return ref.watch(adminRepositoryProvider).watchPromocodes();
});

final adminRewardsProvider = StreamProvider<List<Reward>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllRewards();
});

final adminVipCoinPurchasesProvider =
    StreamProvider<List<VipPurchaseRecord>>((ref) {
  return ref.watch(adminRepositoryProvider).watchVipCoinPurchases();
});

final adminVipMoneyPurchasesProvider =
    StreamProvider<List<VipPurchaseRecord>>((ref) {
  return ref.watch(adminRepositoryProvider).watchVipMoneyPurchases();
});

/// Both purchase paths merged, newest first. Reads the two live streams above
/// rather than a stream of its own, so a partial load (one side still
/// fetching) never blanks out the side that already arrived.
final adminVipPurchasesProvider = Provider<List<VipPurchaseRecord>>((ref) {
  final coins =
      ref.watch(adminVipCoinPurchasesProvider).valueOrNull ?? const [];
  final money =
      ref.watch(adminVipMoneyPurchasesProvider).valueOrNull ?? const [];
  final merged = [...coins, ...money];
  merged.sort((a, b) =>
      (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  return merged;
});

final adminReportsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchReports();
});

final adminsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAdmins();
});

final analyticsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(adminRepositoryProvider).watchAnalytics();
});

/// Live count of pending redemptions — surfaced as a badge on the dashboard.
final pendingRedemptionsCountProvider = Provider<int>((ref) {
  return ref
          .watch(adminRedemptionsProvider(RedemptionStatus.pending))
          .valueOrNull
          ?.length ??
      0;
});
