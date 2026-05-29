import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCzHhAOnm9IgbH7B-IkkZat-ak3iy4ZgtI',
        authDomain: 'caller-adcf8.firebaseapp.com',
        projectId: 'caller-adcf8',
        storageBucket: 'caller-adcf8.firebasestorage.app',
        messagingSenderId: '912566889368',
        appId: '1:912566889368:web:0eacd37a7f60560c4899ed',
      );
    }
    
    // For Android, we use native automatic configuration via google-services.json.
    // If you prefer to declare it explicitly here, you can fill in the Android Firebase Options.
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform. '
      'For Android, please place the "google-services.json" file in the "android/app" directory, '
      'and initialize Firebase using "await Firebase.initializeApp();" without passing options.',
    );
  }
}
