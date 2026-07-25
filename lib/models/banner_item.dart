import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// A promotional banner at `banners/{id}` shown in the home carousel. Managed
/// from the admin dashboard with scheduling and targeting.
class BannerItem extends Equatable {
  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradientColors,
    required this.deeplink,
    required this.isActive,
    required this.sortOrder,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  /// Optional hex colours (`#RRGGBB`) for a gradient when no image is set.
  final List<String> gradientColors;
  final String deeplink;
  final bool isActive;
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isLive {
    final now = DateTime.now();
    if (!isActive) return false;
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  factory BannerItem.fromMap(String id, Map<String, dynamic> map) {
    return BannerItem(
      id: id,
      title: Parse.toStr(map['title']),
      subtitle: Parse.toStr(map['subtitle']),
      imageUrl: Parse.toStr(map['imageUrl']),
      gradientColors: Parse.toStringList(map['gradientColors']),
      deeplink: Parse.toStr(map['deeplink']),
      isActive: Parse.toBool(map['isActive'], true),
      sortOrder: Parse.toInt(map['sortOrder']),
      startsAt: Parse.toDate(map['startsAt']),
      endsAt: Parse.toDate(map['endsAt']),
    );
  }

  factory BannerItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BannerItem.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, isActive, sortOrder];
}
