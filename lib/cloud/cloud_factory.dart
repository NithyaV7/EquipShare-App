import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'cloud.dart';
import 'firebase_cloud.dart';

/// Uses Firebase when firebase_options.dart is filled in, otherwise local demo mode.
Future<Cloud> createCloud() async {
  if (!DefaultFirebaseOptions.isConfigured) return LocalCloud();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return FirebaseCloud();
  } catch (_) {
    return LocalCloud();
  }
}
