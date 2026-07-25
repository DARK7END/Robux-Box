import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/providers.dart';
import '../constants/firestore_paths.dart';
import '../utils/logger.dart';

/// Background isolate handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is initialised by the SDK for background isolates automatically on
  // recent versions; we simply log. Persisting to Firestore is done by the
  // Cloud Function that sent the push, so no client write is needed here.
  log.i('BG push: ${message.messageId}');
}

/// Handles push (FCM) and local notifications, and keeps the FCM token synced to
/// the user's device record so the backend can target reminders
/// (daily / reward / VIP / referral).
class NotificationService {
  NotificationService(this._messaging, this._firestore, this._auth);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final _tapController = StreamController<String>.broadcast();

  /// Emits the deeplink of a tapped notification so the router can navigate.
  Stream<String> get onTapDeeplink => _tapController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'robuxbox_default',
    'Robux Box',
    description: 'Rewards, reminders and updates',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(payload);
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → show a local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // App opened from a background push.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final link = m.data['deeplink'];
      if (link is String && link.isNotEmpty) _tapController.add(link);
    });
    // App opened from terminated state.
    final initial = await _messaging.getInitialMessage();
    final initialLink = initial?.data['deeplink'];
    if (initialLink is String && initialLink.isNotEmpty) {
      _tapController.add(initialLink);
    }

    // Keep token synced.
    await syncToken();
    _messaging.onTokenRefresh.listen((_) => syncToken());
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handlePayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final link = data['deeplink'];
      if (link is String && link.isNotEmpty) _tapController.add(link);
    } catch (_) {
      /* ignore malformed payloads */
    }
  }

  /// Writes the current FCM token onto the user's device document so backend
  /// reminder functions can target it. Topics are used for broadcast campaigns.
  Future<void> syncToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _firestore
          .collection(FsPaths.users)
          .doc(uid)
          .collection(FsPaths.userDevices)
          .doc(token.substring(0, token.length.clamp(0, 40)))
          .set({
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Broadcast topic for campaign pushes.
      await _messaging.subscribeToTopic('all');
    } catch (e, s) {
      log.w('syncToken failed', e, s);
    }
  }

  Future<void> setReminderTopics({
    required bool daily,
    required bool rewards,
    required bool vip,
    required bool referral,
  }) async {
    Future<void> apply(String topic, bool on) =>
        on ? _messaging.subscribeToTopic(topic) : _messaging.unsubscribeFromTopic(topic);
    await Future.wait([
      apply('reminder_daily', daily),
      apply('reminder_rewards', rewards),
      apply('reminder_vip', vip),
      apply('reminder_referral', referral),
    ]);
  }

  void dispose() => _tapController.close();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    ref.watch(messagingProvider),
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
