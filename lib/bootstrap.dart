import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/providers.dart';
import 'core/services/ads_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_service.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';

/// Single, hardened entry point used by `main.dart`.
///
/// Order matters: Firebase → App Check (before any Firestore/Functions call) →
/// Crashlytics/error handlers → providers → services → runApp. Everything is
/// wrapped in a guarded zone so no unhandled error can crash the launch.
Future<void> bootstrap() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final config = AppConfig.fromEnvironment();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check must be activated before Firestore/Functions traffic so the
    // backend can enforce that requests originate from a genuine app instance.
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          config.isProd ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider:
          config.isProd ? AppleProvider.appAttest : AppleProvider.debug,
    );

    // Crash reporting (disabled in debug).
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Optionally point at local emulators for development.
    if (config.useEmulators) {
      _connectEmulators(container);
    }

    // Kick off async service init without blocking first frame.
    unawaited(_initServices(container));

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const RobuxBoxApp(),
      ),
    );
  }, (error, stack) {
    log.e('Uncaught zone error', error, stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _initServices(ProviderContainer container) async {
  try {
    await container.read(adsServiceProvider).init();
  } catch (e, s) {
    log.w('Ads init failed', e, s);
  }
  try {
    await container.read(notificationServiceProvider).init();
  } catch (e, s) {
    log.w('Notifications init failed', e, s);
  }
}

void _connectEmulators(ProviderContainer container) {
  const host = 'localhost';
  try {
    container.read(firebaseAuthProvider).useAuthEmulator(host, 9099);
    container.read(firestoreProvider).useFirestoreEmulator(host, 8080);
    container.read(functionsProvider).useFunctionsEmulator(host, 5001);
    container.read(storageProvider).useStorageEmulator(host, 9199);
    log.i('Connected to Firebase emulators');
  } catch (e, s) {
    log.w('Emulator connection failed', e, s);
  }
}
