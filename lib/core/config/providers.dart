import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Dependency-injection root.
///
/// Firebase singletons are exposed as Riverpod providers so features never call
/// `FirebaseX.instance` directly. This makes every repository trivially testable
/// by overriding these providers with fakes (`fake_cloud_firestore`,
/// `firebase_auth_mocks`) in tests.

/// Overridden in `main()` once [AppConfig.fromEnvironment] is resolved.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in main()');
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final functionsProvider = Provider<FirebaseFunctions>((ref) {
  // Cloud Functions are deployed to us-central1 by default; change here if you
  // deploy to another region.
  return FirebaseFunctions.instanceFor(region: 'us-central1');
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Streams the raw Firebase auth state (fires on sign-in/out/token refresh).
///
/// The *first* event is bounded by a timeout that falls back to "logged out":
/// on some devices (Play Services issues, flaky network, a debug-signed build
/// whose SHA-1 isn't registered) the very first `authStateChanges()` event can
/// be delayed far longer than a splash screen should ever wait. Without this,
/// the router's redirect — which only proceeds once this provider leaves
/// `AsyncLoading` — would leave the user stuck on the splash screen
/// indefinitely. Once the first event (real or fallback) has landed, every
/// later event forwards untouched with no further timeout — a steady-state
/// idle gap (e.g. a logged-in user just sitting on a screen) must never be
/// mistaken for a hang and silently sign them out.
final authStateProvider = StreamProvider<User?>((ref) {
  return _firstEventBounded(
    ref.watch(firebaseAuthProvider).authStateChanges(),
    const Duration(seconds: 8),
  );
});

Stream<T?> _firstEventBounded(Stream<T?> source, Duration timeout) {
  final controller = StreamController<T?>();
  var settled = false;
  Timer? timer;
  late final StreamSubscription<T?> sub;

  sub = source.listen(
    (event) {
      settled = true;
      timer?.cancel();
      controller.add(event);
    },
    onError: controller.addError,
    onDone: controller.close,
  );
  timer = Timer(timeout, () {
    if (!settled) {
      settled = true;
      controller.add(null);
    }
  });
  controller.onCancel = () {
    timer?.cancel();
    sub.cancel();
  };
  return controller.stream;
}
