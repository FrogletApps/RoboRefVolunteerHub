import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options for RoboRef Volunteer Hub.
///
/// You can either:
/// 1. Run `flutterfire configure` inside `app/` to overwrite this file with
///    generated platform options, OR
/// 2. Supply `--dart-define=FIREBASE_API_KEY=...`, `FIREBASE_PROJECT_ID=...`,
///    `FIREBASE_APP_ID=...`, `FIREBASE_MESSAGING_SENDER_ID=...`, and
///    `FIREBASE_AUTH_DOMAIN=...` at build time (`flutter build web`).
class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'app.roboref.roborefVolunteerHub',
  );

  /// Returns true when Firebase project credentials have been configured.
  static bool get isConfigured =>
      _apiKey.isNotEmpty && _projectId.isNotEmpty && _appId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain.isNotEmpty
            ? _authDomain
            : '$_projectId.firebaseapp.com',
        storageBucket: _storageBucket.isNotEmpty ? _storageBucket : null,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isNotEmpty ? _storageBucket : null,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isNotEmpty ? _storageBucket : null,
        iosBundleId: _iosBundleId,
      );
}
