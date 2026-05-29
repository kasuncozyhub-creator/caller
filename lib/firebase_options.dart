import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

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
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCzHhAOnm9IgbH7B-IkkZat-ak3iy4ZgtI',
          appId: '1:912566889368:android:3e0ab2ce72f057864899ed',
          messagingSenderId: '912566889368',
          projectId: 'caller-adcf8',
          storageBucket: 'caller-adcf8.firebasestorage.app',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }
}
