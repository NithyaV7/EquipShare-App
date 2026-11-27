import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// If any value starts with PASTE, that platform runs in local demo mode.
class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAbNuPhXYvo9DsCpH_jLwzmnhvvOeMWOZc',
    appId: '1:734166719333:web:039c4ff9248822ae761f8c',
    messagingSenderId: '734166719333',
    projectId: 'equipshare-b8836',
    authDomain: 'equipshare-b8836.firebaseapp.com',
    storageBucket: 'equipshare-b8836.firebasestorage.app',
  );

  // From google-services.json for package lk.equishare.equishare.
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDajCcFZXrEBT1rNRxFWJ3AUwrBv437rUs',
    appId: '1:734166719333:android:5b5200db17642a9d761f8c',
    messagingSenderId: '734166719333',
    projectId: 'equipshare-b8836',
    storageBucket: 'equipshare-b8836.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;
  static bool get isConfigured => !currentPlatform.apiKey.startsWith('PASTE');
}
