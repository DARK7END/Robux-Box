import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../models/app_user.dart';
import '../../../models/promocode.dart';
import '../../../models/redemption.dart';
import '../../../models/reward.dart';
import '../../../models/wallet.dart';

/// A user + wallet pair returned to the admin user detail view.
class AdminUserBundle {
  const AdminUserBundle(this.user, this.wallet);
  final AppUser user;
  final Wallet wallet;
}

/// Admin-only data access. Every mutating call goes through the same
/// server-authoritative Cloud Functions the security model relies on — the
/// admin app never writes wallets/redemptions directly. Reads use the
/// admin-scoped Firestore collections (allowed by `firestore.rules` only when
/// the caller holds the `admin` custom claim).
class AdminRepository {
  AdminRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  // ---------------------------------------------------------------- redemptions
  Stream<List<Redemption>> watchRedemptions({RedemptionStatus? status}) {
    Query<Map<String, dynamic>> q = _db.collection(FsPaths.redemptions);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) {
      final items = s.docs.map(Redemption.fromDoc).toList();
      // Gold/Diamond's paid-for priority benefit: their requests float to the
      // top of the queue, newest-first within each priority tier.
      items.sort((a, b) => a.priority != b.priority
          ? (a.priority ? -1 : 1)
          : (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Future<Result<void>> processRedemption(
    String id,
    String action, {
    String code = '',
    String reason = '',
  }) =>
      _call('processRedemption', {
        'redemptionId': id,
        'action': action,
        'code': code,
        'reason': reason,
      });

  // ---------------------------------------------------------------------- users
  Future<AdminUserBundle?> findUserByEmail(String email) async {
    final snap = await _db
        .collection(FsPaths.users)
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _bundle(snap.docs.first.id, AppUser.fromDoc(snap.docs.first));
  }

  Future<AdminUserBundle?> getUser(String uid) async {
    final doc = await _db.collection(FsPaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return _bundle(uid, AppUser.fromDoc(doc));
  }

  Stream<List<AppUser>> watchRecentUsers() {
    return _db
        .collection(FsPaths.users)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AppUser.fromDoc).toList());
  }

  Future<AdminUserBundle> _bundle(String uid, AppUser user) async {
    final w = await _db.collection(FsPaths.wallets).doc(uid).get();
    return AdminUserBundle(
        user, w.exists ? Wallet.fromDoc(w) : Wallet.empty(uid));
  }

  Future<Result<void>> adjustCoins(String uid, int amount, String reason) =>
      _call('adjustCoins', {'uid': uid, 'amount': amount, 'reason': reason});

  Future<Result<void>> setAccountStatus(String uid, String status) =>
      _call('setAccountStatus', {'uid': uid, 'status': status});

  Future<Result<void>> setVipLevel(String uid, String level) =>
      _call('setVipLevel', {'uid': uid, 'level': level});

  // ----------------------------------------------------------------- promocodes
  Stream<List<Promocode>> watchPromocodes() {
    return _db
        .collection(FsPaths.promocodes)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Promocode.fromDoc).toList());
  }

  Future<Result<void>> upsertPromocode({
    required String code,
    required int rewardCoins,
    required int maxRedemptions,
    required int perUserLimit,
    required bool isActive,
  }) =>
      _call('upsertPromocode', {
        'code': code,
        'rewardCoins': rewardCoins,
        'maxRedemptions': maxRedemptions,
        'perUserLimit': perUserLimit,
        'isActive': isActive,
      });

  // -------------------------------------------------------------------- rewards
  Stream<List<Reward>> watchAllRewards() {
    return _db
        .collection(FsPaths.rewards)
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(Reward.fromDoc).toList());
  }

  /// Rewards are a public catalogue that admins may write directly (allowed by
  /// rules), so this is a plain Firestore upsert rather than a function.
  Future<Result<void>> saveReward(String? id, Map<String, dynamic> data) async {
    try {
      final ref = id == null
          ? _db.collection(FsPaths.rewards).doc()
          : _db.collection(FsPaths.rewards).doc(id);
      await ref.set(data, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e, s) {
      log.e('saveReward failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> setRewardActive(String id, bool active) async {
    try {
      await _db
          .collection(FsPaths.rewards)
          .doc(id)
          .set({'isActive': active}, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  // --------------------------------------------------------------------- notify
  Future<Result<void>> broadcast({
    required String title,
    required String body,
    required String topic,
    String deeplink = '',
  }) =>
      _call('broadcastNotification', {
        'title': title,
        'body': body,
        'topic': topic,
        'deeplink': deeplink,
      });

  // ---------------------------------------------------------------------- admins
  Stream<List<Map<String, dynamic>>> watchAdmins() {
    return _db
        .collection('admins')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Future<Result<void>> setAdmin(String email, bool makeAdmin) =>
      _call('setAdminClaim', {'email': email.trim(), 'admin': makeAdmin});

  // ------------------------------------------------------------------- analytics
  Stream<Map<String, dynamic>?> watchAnalytics() {
    return _db
        .doc('analytics/summary')
        .snapshots()
        .map((d) => d.exists ? d.data() : null);
  }

  Future<Result<void>> refreshAnalytics() => _call('refreshAnalytics', {});

  // --------------------------------------------------------------------- reports
  Stream<List<Map<String, dynamic>>> watchReports() {
    return _db
        .collection(FsPaths.reports)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // -------------------------------------------------------------------- helpers
  Future<Result<void>> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call<dynamic>(data);
      return const Result.success(null);
    } catch (e, s) {
      log.e('$name failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  );
});
