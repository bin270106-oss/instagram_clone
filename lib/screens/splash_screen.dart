import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Chuyển trang sau 3 giây
    Timer(const Duration(seconds: 3), () {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo của ní đây
            ClipRRect(
              borderRadius: BorderRadius.circular(20), // Bo góc 20
              child: Image.asset(
                'assets/images/logoapp.png',
                height: 120, // Ní chỉnh kích thước ở đây
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 40), // Khoảng cách giữa logo và loading
            
            // Loading cho chuyên nghiệp
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF833AB4)),
            ),
          ],
        ),
      ),
    );
  }
}