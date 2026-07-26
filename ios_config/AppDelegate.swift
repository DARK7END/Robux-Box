import Flutter
import UIKit

// Firebase is initialised from Dart via `Firebase.initializeApp(options:
// DefaultFirebaseOptions.currentPlatform)` (see lib/bootstrap.dart), and all
// plugins (Firebase, Google Mobile Ads, Google Sign-In, local notifications)
// self-register through GeneratedPluginRegistrant — so the standard Flutter
// app delegate is all that's required here.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Present notifications while the app is in the foreground (iOS 10+).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
