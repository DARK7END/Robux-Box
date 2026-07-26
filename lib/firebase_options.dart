// Firebase client configuration for the `robux-box` project.
//
// The Android values below are the REAL client identifiers for this project
// (package `com.robuxbox.app`), taken from google-services.json. Firebase
// client API keys are safe to embed in the app — access is controlled by
// Firebase App Check and Firestore security rules, not by hiding these keys.
//
// iOS / Web are NOT registered yet: run `flutterfire configure` (or add those
// apps in the Firebase console) to fill their appId/apiKey before building for
// those platforms.
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
    apiKey: 'AIzaSyDldo6qSLZI-JS-2Mmx8O_Tw43EJaJ1jm4',
    appId: '1:218872107846:android:2098c1145b2fe12b0fcb47',
    messagingSenderId: '218872107846',
    projectId: 'robux-box',
    storageBucket: 'robux-box.firebasestorage.app',
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
