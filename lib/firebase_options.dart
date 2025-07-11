// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDlckX0gISZNM2gyaLs18baBQHaZq_cXY',
    appId: '1:934555936127:web:d641a56c88afe6141a664a',
    messagingSenderId: '934555936127',
    projectId: 'vyaparhub-e9e74',
    authDomain: 'vyaparhub-e9e74.firebaseapp.com',
    storageBucket: 'vyaparhub-e9e74.firebasestorage.app',
    measurementId: 'G-1MZMR4HV6V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7E42reGt3hET-4fnpJWR5UgJdknkZoDM',
    appId: '1:934555936127:android:f6b39a01c958d2791a664a',
    messagingSenderId: '934555936127',
    projectId: 'vyaparhub-e9e74',
    storageBucket: 'vyaparhub-e9e74.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtGgBR-pGbN_q2eoJC_vxqi3AwUgaW4mQ',
    appId: '1:934555936127:ios:e0fad4a7d604d2bc1a664a',
    messagingSenderId: '934555936127',
    projectId: 'vyaparhub-e9e74',
    storageBucket: 'vyaparhub-e9e74.firebasestorage.app',
    iosBundleId: 'com.example.vyaparhub',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCtGgBR-pGbN_q2eoJC_vxqi3AwUgaW4mQ',
    appId: '1:934555936127:ios:e0fad4a7d604d2bc1a664a',
    messagingSenderId: '934555936127',
    projectId: 'vyaparhub-e9e74',
    storageBucket: 'vyaparhub-e9e74.firebasestorage.app',
    iosBundleId: 'com.example.vyaparhub',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDDlckX0gISZNM2gyaLs18baBQHaZq_cXY',
    appId: '1:934555936127:web:16e93c7603247de81a664a',
    messagingSenderId: '934555936127',
    projectId: 'vyaparhub-e9e74',
    authDomain: 'vyaparhub-e9e74.firebaseapp.com',
    storageBucket: 'vyaparhub-e9e74.firebasestorage.app',
    measurementId: 'G-V5N9W7S9X2',
  );
}
