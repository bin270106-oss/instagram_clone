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
    appId: '1:184865998954:android:0f4ffd5d89151f7a052213',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
  );

  // Cấu hình Web (Dự phòng)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChhy2rDlfhKMvU5tMndW-nAMM5dKUSfC0',
    appId: '1:184865998954:web:7f6d2f33f8e5f2e82b7941',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    authDomain: 'tkct-1723e.firebaseapp.com',
    storageBucket: 'tkct-1723e.firebasestorage.app',
  );

  // Cấu hình iOS (Dự phòng)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChhy2rDlfhKMvU5tMndW-nAMM5dKUSfC0',
    appId: '1:184865998954:ios:VUI_LONG_THAY_MA_CUA_ONG_VAO_DAY', 
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    iosBundleId: 'com.example.tkct',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChhy2rDlfhKMvU5tMndW-nAMM5dKUSfC0',
    appId: '1:184865998954:ios:VUI_LONG_THAY_MA_CUA_ONG_VAO_DAY',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    storageBucket: 'tkct-1723e.firebasestorage.app',
    iosBundleId: 'com.example.tkct',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyChhy2rDlfhKMvU5tMndW-nAMM5dKUSfC0',
    appId: '1:184865998954:web:7f6d2f33f8e5f2e82b7941',
    messagingSenderId: '184865998954',
    projectId: 'tkct-1723e',
    authDomain: 'tkct-1723e.firebaseapp.com',
    storageBucket: 'tkct-1723e.firebasestorage.app',
  );
}