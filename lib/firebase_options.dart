// Firebase client configuration for the `robux-box1` project.
//
// The Android values below are the REAL client identifiers for this project
// (package `com.robuxbox.app`), taken from google-services.json. Firebase
// client API keys are safe to embed in the app — access is controlled by
// Firebase App Check and Firestore security rules, not by hiding these keys.
//
// iOS / Web are STALE: they're still registered against the old `robux-box`
// project (never migrated to `robux-box1`). Do not build for those platforms
// until they're re-registered — run `flutterfire configure` (or add those
// apps in the Firebase console) against `robux-box1` to get fresh appId/
// apiKey values; a projectId/storageBucket edited by hand without matching
// apiKey/appId will just fail to authenticate.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform. Run `flutterfire configure` to add it.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOuRGpgYkQ3-N7eKPfu_zsgi3n2zuVyGI',
    appId: '1:878768707356:android:9fad7a36fb0c6a30d5ccd9',
    messagingSenderId: '878768707356',
    projectId: 'robux-box1',
    storageBucket: 'robux-box1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDQVXGiMS8NukkWzO_itTpU8JCcMqiCm8c',
    appId: '1:218872107846:ios:0239ae994e936ee20fcb47',
    messagingSenderId: '218872107846',
    projectId: 'robux-box',
    storageBucket: 'robux-box.firebasestorage.app',
    iosBundleId: 'com.robuxbox.app',
    iosClientId:
        '218872107846-csphovmpqp9rfgj3i3er0m5suesropvs.apps.googleusercontent.com',
  );

  // Web not registered yet — replace appId/apiKey via `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '218872107846',
    projectId: 'robux-box',
    authDomain: 'robux-box.firebaseapp.com',
    storageBucket: 'robux-box.firebasestorage.app',
  );
}
