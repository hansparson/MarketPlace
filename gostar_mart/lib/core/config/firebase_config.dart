import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS || Platform.isMacOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBv0zPL7by1c1ORiZHhN_eX7emEHXcS2zU',
        appId: '1:190489486829:ios:7682e114d5ef93ee5f33e4',
        messagingSenderId: '190489486829',
        projectId: 'gostar-mart',
        storageBucket: 'gostar-mart.firebasestorage.app',
        iosBundleId: 'com.gostar.gostarMart',
      );
    }
    
    // Default to Android
    return const FirebaseOptions(
      apiKey: 'AIzaSyBMZeaFJ5kfu6_FCT2q0WNOC2A9aa6ZKK4',
      appId: '1:190489486829:android:a310ab4bd6f9732c5f33e4',
      messagingSenderId: '190489486829',
      projectId: 'gostar-mart',
      storageBucket: 'gostar-mart.firebasestorage.app',
    );
  }
}
