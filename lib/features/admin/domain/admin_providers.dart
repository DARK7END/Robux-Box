import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../models/app_user.dart';
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

final adminRecentUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(adminRepositoryProvider).watchRecentUsers();
});

final adminReportsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchReports();
});

/// Live count of pending redemptions — surfaced as a badge on the dashboard.
final pendingRedemptionsCountProvider = Provider<int>((ref) {
  return ref
          .watch(adminRedemptionsProvider(RedemptionStatus.pending))
          .valueOrNull
          ?.length ??
      0;
});
