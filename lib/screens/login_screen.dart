import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instagram_clone/resources/login_methods.dart';
import 'package:instagram_clone/screens/signup_screen.dart';
import 'package:instagram_clone/screens/home_screen.dart';
import 'package:instagram_clone/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  
  List<Map<String, String>> _savedAccounts = []; 

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> accountsJson = prefs.getStringList('saved_accounts') ?? [];
    if (!mounted) return;
    setState(() {
      _savedAccounts = accountsJson
          .map((item) => Map<String, String>.from(json.decode(item)))
          .toList();
    });
  }

  Future<void> _saveAccountLocally(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accountsJson = prefs.getStringList('saved_accounts') ?? [];

    List<Map<String, String>> accounts = accountsJson
        .map((item) => Map<String, String>.from(json.decode(item)))
        .toList();

    accounts.removeWhere((element) => element['email'] == email);

    accounts.add({
      'email': email,
      'password': password,
      'username': email.split('@')[0],
      'photoUrl': 'https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083t7199g30u7.png',
    });

    List<String> updatedJsonList = accounts.map((item) => json.encode(item)).toList();
    await prefs.setStringList('saved_accounts', updatedJsonList);
    _loadSavedAccounts(); 
  }

  void loginUser({String? customEmail, String? customPassword}) async {
    setState(() {
      _isLoading = true;
    });

    final targetEmail = customEmail ?? _emailController.text;
    final targetPassword = customPassword ?? _passwordController.text;

    String res = await LoginMethods().logInUser(
      email: targetEmail,
      password: targetPassword,
    );

    // Lưu tự động nếu đăng nhập thành công (Đã bỏ checkbox UI để giống ảnh)
    if (res == "Thành công" && customEmail == null) {
      await _saveAccountLocally(targetEmail, targetPassword);
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (res == "Thành công") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền đen chuẩn giao diện mới
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // --- PHẦN 1: HEADER (NGÔN NGỮ) ---
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Tiếng Việt',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 18),
                          ],
                        ),
                      ),
                      
                      const Spacer(), // Đẩy phần giữa ra giữa màn hình

                      // --- PHẦN 2: THÂN (LOGO & FORM ĐĂNG NHẬP) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Instagram (Thay bằng ảnh thật nếu bạn có trong assets)
                            Image.asset('assets/images/logo.png', height: 100),
                            Container(
                              height: 70,
                              width: 70,
                            ),
                            const SizedBox(height: 40),

                            // Ô nhập Email / Tên người dùng
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Tên người dùng, email/số di động',
                                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[800]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[800]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Ô nhập Mật khẩu
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[800]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[800]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nút Đăng nhập
                            ElevatedButton(
                              onPressed: loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0064E0), // Xanh dương đậm chuẩn Meta
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24), // Bo góc dạng viên thuốc
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Đăng nhập',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // Nút Quên mật khẩu
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(), // Đẩy phần footer xuống kịch sàn

                      // --- PHẦN 3: FOOTER (TẠO TÀI KHOẢN & META) ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0064E0), width: 1),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Tạo tài khoản mới',
                                style: TextStyle(color: Color(0xFF0064E0), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Biểu tượng Meta
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.all_inclusive, color: Colors.grey, size: 20), // Dùng icon vô cực tạm thay logo Meta
                                SizedBox(width: 4),
                                Text(
                                  'Meta',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}