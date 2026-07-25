import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// The kind of catalogue item a user can redeem.
enum RewardKind { robux, giftCard, digitalCode }

/// A catalogue reward at `rewards/{id}` — a Robux package, a gift card
/// denomination or a digital code. Managed from the admin dashboard.
class Reward extends Equatable {
  const Reward({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.coinCost,
    required this.faceValue,
    required this.currency,
    required this.provider,
    required this.stock,
    required this.isActive,
    required this.minVipLevel,
    required this.sortOrder,
    required this.badge,
  });

  final String id;
  final RewardKind kind;
  final String title;
  final String subtitle;
  final String imageUrl;

  /// Price in app coins.
  final int coinCost;

  /// Nominal value delivered (e.g. 400 Robux, or 10.00 for a $10 card).
  final double faceValue;
  final String currency;

  /// Fulfilment provider key (e.g. `manual`, `reloadly`, `roblox_gift`).
  final String provider;

  /// -1 means unlimited stock.
  final int stock;
  final bool isActive;

  /// Minimum VIP level required to redeem (0 == none).
  final int minVipLevel;
  final int sortOrder;

  /// Optional marketing badge, e.g. "Popular", "Best value".
  final String badge;

  bool get inStock => stock != 0;

  factory Reward.fromMap(String id, Map<String, dynamic> map) {
    return Reward(
      id: id,
      kind: Parse.enumFromName(map['kind'], RewardKind.values, RewardKind.robux),
      title: Parse.toStr(map['title']),
      subtitle: Parse.toStr(map['subtitle']),
      imageUrl: Parse.toStr(map['imageUrl']),
      coinCost: Parse.toInt(map['coinCost']),
      faceValue: Parse.toDouble(map['faceValue']),
      currency: Parse.toStr(map['currency'], 'USD'),
      provider: Parse.toStr(map['provider'], 'manual'),
      stock: map['stock'] == null ? -1 : Parse.toInt(map['stock'], -1),
      isActive: Parse.toBool(map['isActive'], true),
      minVipLevel: Parse.toInt(map['minVipLevel']),
      sortOrder: Parse.toInt(map['sortOrder']),
      badge: Parse.toStr(map['badge']),
    );
  }

  factory Reward.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Reward.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, kind, coinCost, isActive, stock];
}
