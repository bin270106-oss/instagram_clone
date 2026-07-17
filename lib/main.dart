import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:instagram_clone/screens/login_screen.dart';
import 'firebase_options.dart';
void main() async {
  // Bắt buộc phải gọi hàm này khi có xử lý bất đồng bộ (async/await) trong main
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase cho đa nền tảng
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        // Cấu hình màu nền tối chủ đạo giống hệt Instagram
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

