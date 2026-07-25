import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// Authoritative balance document at `wallets/{uid}`.
///
/// This document is **read-only for clients** (see `firestore.rules`); every
/// mutation flows through a Cloud Function inside a Firestore transaction, which
/// is the single source of truth for the point economy and the core anti-fraud
/// guarantee.
class Wallet extends Equatable {
  const Wallet({
    required this.uid,
    required this.coins,
    required this.pendingCoins,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    required this.adsWatchedToday,
    required this.adsWatchedTotal,
    required this.offersCompletedTotal,
    required this.lastEarnAt,
    required this.dailyResetAt,
    required this.updatedAt,
  });

  final String uid;

  /// Spendable balance.
  final int coins;

  /// Coins locked while a redemption is under review or an offer is in a
  /// provider hold window.
  final int pendingCoins;

  final int lifetimeEarned;
  final int lifetimeSpent;

  final int adsWatchedToday;
  final int adsWatchedTotal;
  final int offersCompletedTotal;

  final DateTime? lastEarnAt;
  final DateTime? dailyResetAt;
  final DateTime? updatedAt;

  int get available => coins;
  int get total => coins + pendingCoins;

  factory Wallet.fromMap(String uid, Map<String, dynamic> map) {
    return Wallet(
      uid: uid,
      coins: Parse.toInt(map['coins']),
      pendingCoins: Parse.toInt(map['pendingCoins']),
      lifetimeEarned: Parse.toInt(map['lifetimeEarned']),
      lifetimeSpent: Parse.toInt(map['lifetimeSpent']),
      adsWatchedToday: Parse.toInt(map['adsWatchedToday']),
      adsWatchedTotal: Parse.toInt(map['adsWatchedTotal']),
      offersCompletedTotal: Parse.toInt(map['offersCompletedTotal']),
      lastEarnAt: Parse.toDate(map['lastEarnAt']),
      dailyResetAt: Parse.toDate(map['dailyResetAt']),
      updatedAt: Parse.toDate(map['updatedAt']),
    );
  }

  factory Wallet.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Wallet.fromMap(doc.id, doc.data() ?? const {});

  static Wallet empty(String uid) => Wallet(
        uid: uid,
        coins: 0,
        pendingCoins: 0,
        lifetimeEarned: 0,
        lifetimeSpent: 0,
        adsWatchedToday: 0,
        adsWatchedTotal: 0,
        offersCompletedTotal: 0,
        lastEarnAt: null,
        dailyResetAt: null,
        updatedAt: null,
      );

  @override
  List<Object?> get props =>
      [uid, coins, pendingCoins, lifetimeEarned, adsWatchedToday];
}
