// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'Nền tảng này chưa được cấu hình thủ công!',
        );
    }
  }

  // Cấu hình Android (Lấy chuẩn 100% từ file JSON của ông)

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChhy2rDlfhKMvU5tMndW-nAMM5dKUSfC0',
    appId: '1:184865998954:android:f42522f9af38d4b5052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
  );
  // Cấu hình Web (Dự phòng)

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5IUJSpIs0d5O2lwkfz2wsSouHpDehPwA',
    appId: '1:184865998954:web:113ec02d06f99df3052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    authDomain: 'tkct-1723e.firebaseapp.com',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    measurementId: 'G-DDWK4SKHEG',
  );
  // Cấu hình iOS (Dự phòng)

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9CxvpdSbj7gjS6FJjuTW183wZgQ9F-DA',
    appId: '1:184865998954:ios:6875bd9636aeb4e7052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    iosBundleId: 'com.example.instagramClone',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB9CxvpdSbj7gjS6FJjuTW183wZgQ9F-DA',
    appId: '1:184865998954:ios:6875bd9636aeb4e7052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    iosBundleId: 'com.example.instagramClone',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC5IUJSpIs0d5O2lwkfz2wsSouHpDehPwA',
    appId: '1:184865998954:web:113ec02d06f99df3052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    authDomain: 'tkct-1723e.firebaseapp.com',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    measurementId: 'G-DDWK4SKHEG',
  );
}
