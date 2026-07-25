import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../models/redemption.dart';
import '../../../models/reward.dart';

/// Reads the reward catalogue and the user's redemption history, and submits
/// redemption requests through the `requestRedemption` Cloud Function (which
/// atomically holds the coins and creates the request server-side).
class RedemptionRepository {
  RedemptionRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<Reward>> watchRewards({RewardKind? kind}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FsPaths.rewards)
        .where('isActive', isEqualTo: true);
    if (kind != null) {
      query = query.where('kind', isEqualTo: kind.name);
    }
    return query
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(Reward.fromDoc).toList());
  }

  Stream<List<Redemption>> watchRedemptions(String uid) {
    return _firestore
        .collection(FsPaths.redemptions)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(Redemption.fromDoc).toList());
  }

  Stream<Redemption?> watchRedemption(String id) {
    return _firestore
        .collection(FsPaths.redemptions)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Redemption.fromDoc(doc) : null);
  }

  /// Submits a redemption. Returns the created redemption id.
  Future<Result<String>> requestRedemption({
    required String rewardId,
    required String deliveryTarget,
  }) async {
    try {
      final res = await _functions
          .httpsCallable('requestRedemption')
          .call<Map<String, dynamic>>({
        'rewardId': rewardId,
        'deliveryTarget': deliveryTarget.trim(),
      });
      final id = (res.data['redemptionId'] ?? '').toString();
      return Result.success(id);
    } catch (e, s) {
      log.e('requestRedemption failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> cancelRedemption(String id) async {
    try {
      await _functions
          .httpsCallable('cancelRedemption')
          .call<Map<String, dynamic>>({'redemptionId': id});
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }
}

final redemptionRepositoryProvider = Provider<RedemptionRepository>((ref) {
  return RedemptionRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  );
});

final rewardsProvider =
    StreamProvider.family<List<Reward>, RewardKind?>((ref, kind) {
  return ref.watch(redemptionRepositoryProvider).watchRewards(kind: kind);
});

final redemptionsProvider = StreamProvider<List<Redemption>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const []);
  return ref.watch(redemptionRepositoryProvider).watchRedemptions(auth.uid);
});
