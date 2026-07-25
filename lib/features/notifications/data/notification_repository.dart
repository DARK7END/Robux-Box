import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/app_notification.dart';

/// Reads and mutates the in-app notification centre
/// (`users/{uid}/notifications`).
class NotificationRepository {
  NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(FsPaths.users)
      .doc(uid)
      .collection(FsPaths.userNotifications);

  Stream<List<AppNotification>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> unreadCount(String uid) {
    return _col(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).set({'isRead': true}, SetOptions(merge: true));

  Future<void> markAllRead(String uid) async {
    final unread =
        await _col(uid).where('isRead', isEqualTo: false).limit(400).get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watch(auth.uid);
});

final unreadCountProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).unreadCount(auth.uid);
});
