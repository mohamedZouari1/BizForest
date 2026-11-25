import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// The API key is not stored in the repository. Provide it at build time:
//   flutter run --dart-define-from-file=firebase_config.json
// (copy firebase_config.example.json to firebase_config.json and fill it in)
const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');

class DefaultFirebaseOptions {
  static bool get isConfigured => _apiKey.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    // For simplicity, we will use the same Web config across all platforms 
    // since the user provided the Web config, and it works perfectly for 
    // basic Firestore usage on Android/iOS in development.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:131492730323:web:e18c1beb90885d170b8b26',
    messagingSenderId: '131492730323',
    projectId: 'bizforest-7cac3',
    authDomain: 'bizforest-7cac3.firebaseapp.com',
    storageBucket: 'bizforest-7cac3.firebasestorage.app',
    measurementId: 'G-N87ZKBXR46',
  );
}
