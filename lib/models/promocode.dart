import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// A promo code at `promocodes/{code}`. Redemption is validated and applied by
/// the `redeemPromocode` Cloud Function (single-use per user, global cap,
/// expiry — all enforced server-side).
class Promocode extends Equatable {
  const Promocode({
    required this.code,
    required this.rewardCoins,
    required this.maxRedemptions,
    required this.redemptionCount,
    required this.perUserLimit,
    required this.isActive,
    required this.expiresAt,
  });

  final String code;
  final int rewardCoins;
  final int maxRedemptions; // -1 unlimited
  final int redemptionCount;
  final int perUserLimit;
  final bool isActive;
  final DateTime? expiresAt;

  bool get isExhausted =>
      maxRedemptions >= 0 && redemptionCount >= maxRedemptions;
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isRedeemable => isActive && !isExhausted && !isExpired;

  factory Promocode.fromMap(String code, Map<String, dynamic> map) {
    return Promocode(
      code: code,
      rewardCoins: Parse.toInt(map['rewardCoins']),
      maxRedemptions:
          map['maxRedemptions'] == null ? -1 : Parse.toInt(map['maxRedemptions'], -1),
      redemptionCount: Parse.toInt(map['redemptionCount']),
      perUserLimit: Parse.toInt(map['perUserLimit'], 1),
      isActive: Parse.toBool(map['isActive'], true),
      expiresAt: Parse.toDate(map['expiresAt']),
    );
  }

  factory Promocode.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Promocode.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [code, rewardCoins, isActive, redemptionCount];
}
