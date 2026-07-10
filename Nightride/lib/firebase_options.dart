import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDIN1rVjMgw6r80hYuTRrpSpsV8BH0WEn0',
    authDomain: 'nightride-a9173.firebaseapp.com',
    projectId: 'nightride-a9173',
    storageBucket: 'nightride-a9173.firebasestorage.app',
    messagingSenderId: '218660887469',
    appId: '1:218660887469:web:f58ff04ccc90108522df24',
    measurementId: 'G-4Y7N497G5C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAU9psJRDieD_hhluJEDYKEey6efWn3X-8',
    authDomain: 'nightride-a9173.firebaseapp.com',
    projectId: 'nightride-a9173',
    storageBucket: 'nightride-a9173.firebasestorage.app',
    messagingSenderId: '218660887469',
    appId: '1:218660887469:android:28c38d7a349bc81922df24',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCEVJd4jHrz5TFxHTdLsrJ3c8GaFqtzY8w',
    projectId: 'nightride-a9173',
    storageBucket: 'nightride-a9173.firebasestorage.app',
    messagingSenderId: '218660887469',
    appId: '1:218660887469:ios:b8f01140e713450822df24',
    iosBundleId: 'com.therisetechvillage.nightride',
  );
}
