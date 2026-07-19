import 'package:flutter/material.dart';
import 'package:instagram_clone/resources/signup_methods.dart';
import 'package:instagram_clone/widgets/text_field_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Khởi tạo bộ điều khiển dữ liệu văn bản cho các trường thông tin đăng ký[cite: 3]
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false; // Trạng thái vòng xoay chờ tải xử lý[cite: 3]

  // Hàm giải phóng bộ nhớ khi hủy trang đăng ký[cite: 3]
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // HÀM XỬ LÝ ĐĂNG KÝ: Kiểm tra cấu trúc hợp lệ, đối chiếu mật khẩu và gửi yêu cầu tạo tài khoản lên hệ thống Firebase[cite: 3]
  void signUpUser() async {
    // 1. Định thức Regex để kiểm tra cấu trúc email có đúng định dạng tiêu chuẩn không[cite: 3]
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

    // 2. Chặn tiến trình nếu cấu trúc chuỗi email nhập sai cấu trúc[cite: 3]
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa chỉ email không tồn tại hoặc sai định dạng! Vui lòng nhập lại.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Kích hoạt trạng thái xoay màn hình chờ[cite: 3]
    });

    // 3. Đẩy thông tin xác thực sang hàm đăng ký chính của AuthMethods[cite: 3]
    String res = await SignUpMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      username: _usernameController.text,
      bio: _bioController.text,
    );

    setState(() {
      _isLoading = false; // Tắt vòng xoay chờ[cite: 3]
    });

    if (!mounted) return;

    // 4. Kiểm tra phản hồi kết quả từ máy chủ trả về[cite: 3]
    if (res == "Thành công") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng kiểm tra hộp thư để xác thực tài khoản trước khi đăng nhập.'),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)), // Thông báo lỗi tương ứng nhận từ Firebase[cite: 3]
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: SingleChildScrollView( // Thay thế phần Column trần bằng SingleChildScrollView để cuộn trang an toàn, chống tràn pixel
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo tiêu đề[cite: 3]
                const Text(
                  'Instagram',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oriel',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign up to see photos and videos from your friends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Nút đăng nhập liên kết Facebook[cite: 3]
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.facebook),
                  label: const Text('Log in with Facebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),

                // Biểu mẫu điền thông tin đăng ký tài khoản[cite: 3]
                TextFieldInput(
                  hintText: 'Username',
                  textInputType: TextInputType.text,
                  textEditingController: _usernameController,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextFieldInput(
                  hintText: 'Confirm Password',
                  textInputType: TextInputType.text,
                  textEditingController: _confirmPasswordController,
                  isPass: true,
                ),
                const SizedBox(height: 12),
                TextFieldInput(
                  hintText: 'Bio',
                  textInputType: TextInputType.text,
                  textEditingController: _bioController,
                ),
                const SizedBox(height: 24),

                // Nút bấm kích hoạt đăng ký[cite: 3]
                InkWell(
                  onTap: signUpUser,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const ShapeDecoration(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      color: Colors.blue,
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Sign up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'By signing up, you agree to our Terms, Privacy Policy and Cookies Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // NÚT POP QUAY LẠI ĐĂNG NHẬP: Đóng màn hình hiện tại để lùi về màn hình cha LoginScreen bên dưới[cite: 3]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Have an account?', style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Gỡ bỏ an toàn lớp màn hình đăng ký ra khỏi ngăn xếp định tuyến[cite: 3]
                      },
                      child: const Text('Log in.', style: TextStyle(color: Colors.blue)),
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