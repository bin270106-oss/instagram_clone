import 'package:flutter/material.dart';
// Lưu ý: Đổi đường dẫn import này thành file trung chuyển auth_methods.dart nếu bạn dùng cách 2
import 'package:instagram_clone/resources/forgot_password_methods.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    // Gọi hàm gửi email khôi phục
    String res = await ForgotPasswordMethods().resetPassword(
      email: _emailController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (res == "Thành công") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi liên kết khôi phục. Vui lòng kiểm tra email của bạn!')),
      );
      // Quay lại màn hình đăng nhập sau khi gửi thành công
      Navigator.of(context).pop(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền đen tiệp màu với trang Login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Nút back về màn hình đăng nhập
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Căn lề chuẩn
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Đưa toàn bộ nội dung sang trái
              children: [
                const SizedBox(height: 16),
                
                // Tiêu đề chính
                const Text(
                  'Tìm tài khoản',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Dòng mô tả
                const Text(
                  'Nhập email hoặc tên người dùng của bạn.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),

                // Link hỗ trợ hack tài khoản
                GestureDetector(
                  onTap: () {
                    // Xử lý chuyển hướng đến trang hỗ trợ tài khoản bị hack
                  },
                  child: const Text(
                    'Tôi cho rằng tài khoản của mình đã bị hack',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF3797EF), // Màu xanh dương của link
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ô nhập dữ liệu
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email hoặc tên người dùng',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E), // Màu nền ô nhập liệu tối
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Bo tròn góc
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

                // Nút Tiếp tục (Màu xanh)
                ElevatedButton(
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064E0),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), // Bo tròn dạng viên thuốc
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
                          'Tiếp tục',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Nút Tìm bằng số di động (Màu xám tối)
                ElevatedButton(
                  onPressed: () {
                    // Xử lý logic tìm bằng số điện thoại
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2E), // Màu nền nút phụ
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tìm bằng số di động',
                    style: TextStyle(
                      color: Colors.grey[300], 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}