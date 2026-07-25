// GENERATED TEMPLATE — replace by running `flutterfire configure`.
//
// This file provides the per-platform Firebase client configuration. The values
// below are TEMPLATE identifiers for the `robux-box` project layout; they are
// NOT secrets (Firebase API keys are safe to embed in client apps — access is
// controlled by Firebase App Check and Firestore security rules, not by hiding
// these keys). Run `flutterfire configure --project=<your-project-id>` to
// overwrite this file with your project's real identifiers before shipping.
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
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'robux-box',
    storageBucket: 'robux-box.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'robux-box',
    storageBucket: 'robux-box.appspot.com',
    iosBundleId: 'app.robuxbox.robuxBox',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'robux-box',
    authDomain: 'robux-box.firebaseapp.com',
    storageBucket: 'robux-box.appspot.com',
  );
}
