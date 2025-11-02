import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../data/datasources/remote/firebase_config.dart';

/// Initialize Firebase for all platforms
class FirebaseInitializer {
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web platform
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          authDomain: FirebaseConfig.authDomain,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          appId: FirebaseConfig.appId,
        ),
      );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
             // Desktop platforms need explicit options
              await Firebase.initializeApp(
                options: FirebaseOptions(
                 apiKey: FirebaseConfig.apiKey,
                  authDomain: FirebaseConfig.authDomain,
                  projectId: FirebaseConfig.projectId,
                  storageBucket: FirebaseConfig.storageBucket,
                  messagingSenderId: FirebaseConfig.messagingSenderId,
                 appId: FirebaseConfig.appId,
                ),
               );
    } else {
      // Mobile and desktop platforms (uses google-services.json / GoogleService-Info.plist)
      await Firebase.initializeApp();
    }
  }
}
