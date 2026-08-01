import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../models/app_user.dart';
import '../../../models/model_utils.dart';
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

/// One page of the all-users browser.
class AdminUsersPage {
  const AdminUsersPage(this.users, this.cursor, this.hasMore);
  final List<AppUser> users;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

/// One VIP purchase — coins or real money — normalised for the purchases log.
/// Coins-path rows come from `transactions` (`type == 'vipPurchase'`,
/// written by `purchaseVipWithCoins`); money-path rows come from
/// `vip_purchases` (written by `verifyVipPurchase`). Two different documents
/// shapes, one admin-facing record.
class VipPurchaseRecord {
  const VipPurchaseRecord({
    required this.id,
    required this.uid,
    required this.level,
    required this.isMoneyPurchase,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final VipLevel level;

  /// false = paid with coins, true = real-money store purchase.
  final bool isMoneyPurchase;

  /// "12,000 coins" for the coins path, "android · vip_gold_30d" for money.
  final String detail;
  final DateTime? createdAt;
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

  /// One page of every user, newest sign-up first. Pass the previous page's
  /// [AdminUsersPage.cursor] to fetch the next one — a plain `.get()` (not a
  /// live stream) since paging and `snapshots()` don't mix well, and an admin
  /// browsing the full user base doesn't need each page to update live.
  Future<AdminUsersPage> fetchUsersPage({
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int pageSize = 30,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection(FsPaths.users)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    return AdminUsersPage(
      snap.docs.map(AppUser.fromDoc).toList(),
      snap.docs.isEmpty ? cursor : snap.docs.last,
      snap.docs.length == pageSize,
    );
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

  // ------------------------------------------------------------ vip purchases
  /// Coins-path VIP purchases (`purchaseVipWithCoins`, logged as a wallet
  /// transaction — the level is its `referenceId`, the coins spent its
  /// `amount`).
  Stream<List<VipPurchaseRecord>> watchVipCoinPurchases() {
    return _db
        .collection(FsPaths.transactions)
        .where('type', isEqualTo: 'vipPurchase')
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final m = d.data();
              return VipPurchaseRecord(
                id: d.id,
                uid: Parse.toStr(m['uid']),
                level: Parse.enumFromName(
                    m['referenceId'], VipLevel.values, VipLevel.none),
                isMoneyPurchase: false,
                detail: '${Parse.toInt(m['amount'])} coins',
                createdAt: Parse.toDate(m['createdAt']),
              );
            }).toList());
  }

  /// Real-money VIP purchases, verified store receipts written by
  /// `verifyVipPurchase`.
  Stream<List<VipPurchaseRecord>> watchVipMoneyPurchases() {
    return _db
        .collection(FsPaths.vipPurchases)
        .orderBy('verifiedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final m = d.data();
              return VipPurchaseRecord(
                id: d.id,
                uid: Parse.toStr(m['uid']),
                level: Parse.enumFromName(
                    m['level'], VipLevel.values, VipLevel.none),
                isMoneyPurchase: true,
                detail:
                    '${Parse.toStr(m['platform'])} · ${Parse.toStr(m['productId'])}',
                createdAt: Parse.toDate(m['verifiedAt']),
              );
            }).toList());
  }

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
