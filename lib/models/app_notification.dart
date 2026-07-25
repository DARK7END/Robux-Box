import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

enum NotificationType {
  system,
  reward,
  redemption,
  referral,
  vip,
  promo,
  achievement,
  dailyReminder,
}

/// An in-app notification at `users/{uid}/notifications/{id}`. Push messages are
/// mirrored here so there's a persistent notification centre.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.deeplink,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String imageUrl;

  /// In-app route to open when tapped, e.g. `/rewards` or `/redemptions/{id}`.
  final String deeplink;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: Parse.enumFromName(
          map['type'], NotificationType.values, NotificationType.system),
      title: Parse.toStr(map['title']),
      body: Parse.toStr(map['body']),
      imageUrl: Parse.toStr(map['imageUrl']),
      deeplink: Parse.toStr(map['deeplink']),
      isRead: Parse.toBool(map['isRead']),
      createdAt: Parse.toDate(map['createdAt']),
    );
  }

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppNotification.fromMap(doc.id, doc.data() ?? const {});

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        imageUrl: imageUrl,
        deeplink: deeplink,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, type, isRead, createdAt];
}
