import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Firebase settings are NOT stored in this repository.
// Copy firebase_config.example.json to firebase_config.json, fill in the
// values from your own Firebase project, then run:
//   flutter run --dart-define-from-file=firebase_config.json
const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
const String _messagingSenderId =
    String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const String _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

class DefaultFirebaseOptions {
  static bool get isConfigured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  // The same Web config is used on all platforms.
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
    measurementId: _measurementId,
  );
}
