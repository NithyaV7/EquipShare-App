import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Paste your own values here. See FIREBASE_SETUP.md.
/// While any value still starts with PASTE, the app runs in local demo mode.
class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'PASTE_WEB_API_KEY',
    appId: 'PASTE_WEB_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    authDomain: 'PASTE_PROJECT_ID.firebaseapp.com',
  );

  static const android = FirebaseOptions(
    apiKey: 'PASTE_ANDROID_API_KEY',
    appId: 'PASTE_ANDROID_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
  );

  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;
  static bool get isConfigured => !currentPlatform.apiKey.startsWith('PASTE');
}
