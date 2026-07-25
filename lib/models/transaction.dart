import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// How coins entered or left the wallet. Drives the icon/colour in the ledger.
enum TxType {
  rewardedAd,
  offerwall,
  dailyBonus,
  streakBonus,
  referralBonus,
  referralShare,
  promocode,
  achievement,
  levelUp,
  redemption,
  adjustment, // admin credit/debit
  refund,
}

enum TxDirection { credit, debit }

/// An immutable ledger entry at `users/{uid}/transactions/{id}` (mirrored to a
/// top-level `transactions` collection for admin analytics). Written only by
/// Cloud Functions.
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    required this.title,
    required this.description,
    required this.referenceId,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final TxType type;
  final TxDirection direction;

  /// Always positive; [direction] indicates sign.
  final int amount;
  final int balanceAfter;
  final String title;
  final String description;

  /// Links to the source entity (offer id, redemption id, ad impression id, …).
  final String referenceId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  bool get isCredit => direction == TxDirection.credit;
  int get signedAmount => isCredit ? amount : -amount;

  factory WalletTransaction.fromMap(String id, Map<String, dynamic> map) {
    return WalletTransaction(
      id: id,
      type: Parse.enumFromName(map['type'], TxType.values, TxType.adjustment),
      direction: Parse.enumFromName(
          map['direction'], TxDirection.values, TxDirection.credit),
      amount: Parse.toInt(map['amount']),
      balanceAfter: Parse.toInt(map['balanceAfter']),
      title: Parse.toStr(map['title']),
      description: Parse.toStr(map['description']),
      referenceId: Parse.toStr(map['referenceId']),
      metadata: Parse.toMap(map['metadata']),
      createdAt: Parse.toDate(map['createdAt']),
    );
  }

  factory WalletTransaction.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      WalletTransaction.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, type, direction, amount, createdAt];
}
