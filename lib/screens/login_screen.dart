import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instagram_clone/resources/login_methods.dart';
import 'package:instagram_clone/screens/signup_screen.dart';
import 'package:instagram_clone/widgets/text_field_input.dart';
import 'package:instagram_clone/screens/home_screen.dart';
import 'package:instagram_clone/screens/forgot_password_screen.dart'; // Đã thêm import màn hình Quên mật khẩu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Khởi tạo các bộ điều khiển dữ liệu cho ô nhập văn bản
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Trạng thái hiển thị vòng xoay tải dữ liệu
  bool _isRememberMe = false; // Trạng thái tích chọn ghi nhớ đăng nhập
  List<Map<String, String>> _savedAccounts = []; // Danh sách chứa các tài khoản đã lưu cục bộ

  // Hàm khởi tạo trạng thái mặc định của Widget
  @override
  void initState() {
    super.initState();
    _loadSavedAccounts(); // Tự động quét và lấy danh sách tài khoản đã lưu ngay khi mở màn hình
  }

  // Hàm giải phóng bộ nhớ khi hủy Widget
  @override
  void dispose() {
    _emailController.dispose(); // Giải phóng bộ nhớ ô nhập email
    _passwordController.dispose(); // Giải phóng bộ nhớ ô nhập mật khẩu
    super.dispose();
  }

  // HÀM ĐỌC DỮ LIỆU CỤC BỘ: Lấy danh sách chuỗi JSON tài khoản đã lưu dưới máy và chuyển thành List
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

  // HÀM GHI DỮ LIỆU CỤC BỘ: Mã hóa thông tin và lưu tài khoản xuống máy khi tick chọn Remember Me
  Future<void> _saveAccountLocally(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accountsJson = prefs.getStringList('saved_accounts') ?? [];

    List<Map<String, String>> accounts = accountsJson
        .map((item) => Map<String, String>.from(json.decode(item)))
        .toList();

    // Xóa tài khoản cũ nếu trùng email để tránh ghi đè lặp lại
    accounts.removeWhere((element) => element['email'] == email);

    // Thêm thông tin tài khoản mới vào danh sách
    accounts.add({
      'email': email,
      'password': password,
      'username': email.split('@')[0],
      'photoUrl': 'https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083t7199g30u7.png',
    });

    // Chuyển List thành danh sách chuỗi JSON và lưu lại vào SharedPreferences
    List<String> updatedJsonList = accounts.map((item) => json.encode(item)).toList();
    await prefs.setStringList('saved_accounts', updatedJsonList);
    _loadSavedAccounts(); // Cập nhật lại danh sách trên màn hình giao diện
  }

  // HÀM XỬ LÝ ĐĂNG NHẬP: Gọi Firebase xác thực (hỗ trợ cả nhập thủ công và bấm đăng nhập nhanh)
  void loginUser({String? customEmail, String? customPassword}) async {
    setState(() {
      _isLoading = true; // Bật hiệu ứng xoay tải dữ liệu
    });

    // Xác định nguồn dữ liệu đầu vào (từ danh sách nhanh hoặc từ ô nhập)
    final targetEmail = customEmail ?? _emailController.text;
    final targetPassword = customPassword ?? _passwordController.text;

    // Gọi hàm đăng nhập từ tầng dịch vụ LoginMethods
    String res = await LoginMethods().logInUser(
      email: targetEmail,
      password: targetPassword,
    );

    // Nếu đăng nhập thành công và có tích chọn Remember Me thì tiến hành lưu lại
    if (res == "Thành công" && _isRememberMe && customEmail == null) {
      await _saveAccountLocally(targetEmail, targetPassword);
    }

    setState(() {
      _isLoading = false; // Tắt hiệu ứng xoay tải dữ liệu
    });

    if (!mounted) return;

    if (res == "Thành công") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công!')),
      );
      
      // Điều hướng sang màn hình HomeScreen và hủy bỏ màn hình Login hiện tại
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)), // Hiển thị thông báo lỗi chi tiết
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: SingleChildScrollView( // Thay thế CustomScrollView cũ để chống tràn màn hình mượt mà hơn
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                // Logo Instagram
                const Text(
                  'Instagram',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oriel',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // VÙNG HIỂN THỊ DANH SÁCH TÀI KHOẢN ĐĂNG NHẬP NHANH (Nếu có)
                if (_savedAccounts.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tài khoản đã lưu:',
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn độc lập để ăn theo SingleChildScrollView cha
                    itemCount: _savedAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _savedAccounts[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: ListTile(
                          dense: true,
                          onTap: () => loginUser(
                            customEmail: account['email'],
                            customPassword: account['password'],
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(account['photoUrl']!),
                          ),
                          title: Text(
                            account['username']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.red, size: 6),
                              SizedBox(width: 4),
                              Text('Đăng nhập nhanh', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Hoặc đăng nhập tài khoản khác', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Các ô nhập dữ liệu thủ công
                TextFieldInput(
                  hintText: 'Email or Mobile Number',
                  textInputType: TextInputType.emailAddress,
                  textEditingController: _emailController,
                ),
                const SizedBox(height: 12),
                TextFieldInput(
                  hintText: 'Password',
                  textInputType: TextInputType.text,
                  textEditingController: _passwordController,
                  isPass: true,
                ),
                const SizedBox(height: 8),
                
                // Khung chọn Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: _isRememberMe,
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.grey),
                      onChanged: (value) {
                        setState(() {
                          _isRememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Remember me', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),

                // Nút bấm đăng nhập
                InkWell(
                  onTap: () => loginUser(),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      color: Colors.blue,
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : const Text(
                            'Log in',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24), // Khoảng cách từ nút Log in xuống khối phía dưới

                // KHỐI GỘP: Quên mật khẩu và Đăng ký
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Khoảng cách bằng với khoảng cách phía trên
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            // Thêm màn hình Đăng ký vào Stack điều hướng
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            ).then((_) => _loadSavedAccounts()); // Làm mới lại danh sách tài khoản cục bộ sau khi từ trang đăng ký lùi về
                          },
                          child: const Text('Sign up.', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}