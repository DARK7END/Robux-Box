import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'app_user.dart';
import 'model_utils.dart';
import 'reward.dart';

/// Lifecycle of a redemption request.
enum RedemptionStatus { pending, approved, rejected, paid, cancelled }

/// A redemption request at `redemptions/{id}`.
///
/// Created by the `requestRedemption` Cloud Function, which atomically debits
/// the wallet into `pendingCoins`. Admins move it through
/// pending → approved → paid (or rejected, which refunds the hold).
class Redemption extends Equatable {
  const Redemption({
    required this.id,
    required this.uid,
    required this.rewardId,
    required this.kind,
    required this.title,
    required this.coinCost,
    required this.faceValue,
    required this.currency,
    required this.status,
    required this.priority,
    required this.vipLevel,
    required this.deliveryTarget,
    required this.deliveredCode,
    required this.rejectionReason,
    required this.createdAt,
    required this.processedAt,
    required this.processedBy,
  });

  final String id;
  final String uid;
  final String rewardId;
  final RewardKind kind;
  final String title;
  final int coinCost;
  final double faceValue;
  final String currency;
  final RedemptionStatus status;

  /// Set server-side (`requestRedemption`) when the requester was Gold/Diamond
  /// VIP at request time — a paid benefit: these sort first for admins.
  final bool priority;

  /// The requester's effective VIP tier at request time (`none` if not VIP),
  /// set server-side alongside [priority] — lets admins tell every tier apart,
  /// not just priority/not.
  final VipLevel vipLevel;

  /// Where to deliver: Roblox username, email or phone depending on [kind].
  final String deliveryTarget;

  /// The gift-card/digital code once fulfilled (empty until paid).
  final String deliveredCode;
  final String rejectionReason;

  final DateTime? createdAt;
  final DateTime? processedAt;
  final String processedBy;

  bool get isTerminal =>
      status == RedemptionStatus.paid ||
      status == RedemptionStatus.rejected ||
      status == RedemptionStatus.cancelled;

  factory Redemption.fromMap(String id, Map<String, dynamic> map) {
    return Redemption(
      id: id,
      uid: Parse.toStr(map['uid']),
      rewardId: Parse.toStr(map['rewardId']),
      kind:
          Parse.enumFromName(map['kind'], RewardKind.values, RewardKind.robux),
      title: Parse.toStr(map['title']),
      coinCost: Parse.toInt(map['coinCost']),
      faceValue: Parse.toDouble(map['faceValue']),
      currency: Parse.toStr(map['currency'], 'USD'),
      status: Parse.enumFromName(
          map['status'], RedemptionStatus.values, RedemptionStatus.pending),
      priority: Parse.toBool(map['priority']),
      vipLevel:
          Parse.enumFromName(map['vipLevel'], VipLevel.values, VipLevel.none),
      deliveryTarget: Parse.toStr(map['deliveryTarget']),
      deliveredCode: Parse.toStr(map['deliveredCode']),
      rejectionReason: Parse.toStr(map['rejectionReason']),
      createdAt: Parse.toDate(map['createdAt']),
      processedAt: Parse.toDate(map['processedAt']),
      processedBy: Parse.toStr(map['processedBy']),
    );
  }

  factory Redemption.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Redemption.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, uid, status, coinCost, createdAt];
}
