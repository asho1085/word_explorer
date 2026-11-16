import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for the `word-explorer-8ca65` project.
///
/// Values come from `android/app/google-services.json` and the web config in
/// `js/firebase-config.js`. These are public client identifiers, not secrets.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // No iOS/macOS Firebase app is registered for this project yet.
        throw UnsupportedError(
          'Firebase is not configured for this platform. Add GoogleService-Info.plist first.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApbKbxKefSsXJNiBOXB-XEgkzGNifbhpE',
    appId: '1:462304291385:android:bf3a7b7b0f94517c357be8',
    messagingSenderId: '462304291385',
    projectId: 'word-explorer-8ca65',
    storageBucket: 'word-explorer-8ca65.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbBd5w9rUQ8iu78ufUNeJmvIT0yNNMp28',
    appId: '1:462304291385:web:d1fdf5f8c6cb9d14357be8',
    messagingSenderId: '462304291385',
    projectId: 'word-explorer-8ca65',
    authDomain: 'word-explorer-8ca65.firebaseapp.com',
    storageBucket: 'word-explorer-8ca65.firebasestorage.app',
    measurementId: 'G-JBRXT1L1TQ',
  );
}
