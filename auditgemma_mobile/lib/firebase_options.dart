// File generated manually as fallback
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // We are passing the same config across all platforms for the hackathon demo.
    // This allows Auth and Firestore to work out of the box in the Android emulator
    // without needing to fight with the Firebase CLI.
    return const FirebaseOptions(
      apiKey: 'AIzaSyDH89thE4JWwkrbjinEknp3BYalXnOdrQ0',
      appId: '1:124362139239:web:27639faaa318a895db16c2',
      messagingSenderId: '124362139239',
      projectId: 'auditgemma-ca1bb',
      authDomain: 'auditgemma-ca1bb.firebaseapp.com',
      storageBucket: 'auditgemma-ca1bb.firebasestorage.app',
      measurementId: 'G-60Z4SLL262',
    );
  }
}
