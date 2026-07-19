import 'package:flutter/material.dart';
// Lưu ý: Đổi lại import này cho đúng đường dẫn file chứa SignUpMethods của ông nha
import 'package:instagram_clone/resources/signup_methods.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();

  // Dữ liệu trống, lấy từ người dùng nhập vào
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  // Thêm các controller để khớp với hàm signUpUser của ông
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_pageController.page == 0) {
      Navigator.of(context).pop(); 
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Hàm hiển thị Lịch để chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue, 
              onPrimary: Colors.white, 
              surface: Color(0xFF262626), 
              onSurface: Colors.white, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      int age = DateTime.now().year - picked.year;
      setState(() {
        _birthdayController.text = "Ngày sinh ($age tuổi)\n${picked.day} tháng ${picked.month}, ${picked.year}";
      });
    }
  }

  // HÀM GỌI API ĐĂNG KÝ
  void _signUpUserFinal() async {
    setState(() {
      _isLoading = true;
    });

    String res = await SignUpMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      username: _usernameController.text,
      bio: _bioController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (res == "Thành công") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng xác thực email.')),
      );
      Navigator.of(context).pop(); // Về trang đăng nhập
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  void _showNoCodeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                title: const Text('Gửi lại mã xác nhận', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(color: Colors.grey, height: 1),
              ListTile(
                title: const Text('Thay đổi email', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(color: Colors.grey, height: 1),
              ListTile(
                title: const Text('Xác nhận bằng số di động', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), 
          children: [
            _buildEmailStep(),
            _buildVerificationStep(),
            _buildBirthdayStep(),
            _buildNameStep(),
            _buildUsernameStep(),
            _buildFinalPasswordStep(), // Bước cuối để chốt hạ API
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  // ================= CÁC BƯỚC ĐĂNG KÝ (PAGES) =================

  // BƯỚC 1: NHẬP EMAIL
  Widget _buildEmailStep() {
    return _buildStepLayout(
      title: 'Email của bạn là gì?',
      subtitle: 'Nhập email có thể dùng để liên hệ với bạn. Sẽ không ai nhìn thấy thông tin này trên trang cá nhân của bạn.',
      content: Column(
        children: [
          _buildInputField(controller: _emailController, hintText: 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          const Text(
            'Bạn cũng sẽ nhận được email của chúng tôi và có thể chọn không nhận bất cứ lúc nào. Tìm hiểu thêm',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton(text: 'Tiếp', onPressed: _nextStep),
          const SizedBox(height: 12),
          _buildSecondaryButton(text: 'Đăng ký bằng số di động', onPressed: () {}),
        ],
      ),
    );
  }

  // BƯỚC 2: XÁC NHẬN MÃ OTP (Giao diện UI)
  Widget _buildVerificationStep() {
    return _buildStepLayout(
      title: 'Nhập mã xác nhận',
      subtitle: 'Để xác nhận trang cá nhân, hãy nhập mã gồm 6 chữ số mà chúng tôi đã gửi đến email của bạn.',
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: index == 0 ? Colors.white : Colors.grey[800]!),
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Tiếp', onPressed: _nextStep),
          const SizedBox(height: 12),
          _buildSecondaryButton(text: 'Tôi không nhận được mã', onPressed: _showNoCodeModal),
        ],
      ),
    );
  }

  // BƯỚC 3: NGÀY SINH (Đã gắn DatePicker)
  Widget _buildBirthdayStep() {
    return _buildStepLayout(
      title: 'Ngày sinh của bạn là khi nào?',
      subtitleWidget: RichText(
        text: const TextSpan(
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
          children: [
            TextSpan(text: 'Hãy sử dụng ngày sinh của chính bạn, ngay cả khi tài khoản này dành cho doanh nghiệp, thú cưng hay gì đó khác. Thông tin này sẽ không hiển thị với bất kỳ ai trừ khi bạn chọn chia sẻ. '),
            TextSpan(text: 'Tại sao tôi cần cung cấp ngày sinh của mình?', style: TextStyle(color: Color(0xFF3797EF))),
          ],
        ),
      ),
      content: Column(
        children: [
          GestureDetector(
            onTap: () => _selectDate(context), // Mở lịch khi bấm vào
            child: AbsorbPointer( // Chặn bàn phím hiện lên
              child: TextField(
                controller: _birthdayController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Ngày sinh (0 tuổi)",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Tiếp', onPressed: _nextStep),
        ],
      ),
    );
  }

  // BƯỚC 4: TÊN ĐẦY ĐỦ
  Widget _buildNameStep() {
    return _buildStepLayout(
      title: 'Bạn tên gì?',
      content: Column(
        children: [
          _buildInputField(controller: _nameController, hintText: 'Tên đầy đủ'),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Tiếp', onPressed: _nextStep),
        ],
      ),
    );
  }

  // BƯỚC 5: TẠO TÊN NGƯỜI DÙNG (USERNAME)
  Widget _buildUsernameStep() {
    return _buildStepLayout(
      title: 'Tạo tên người dùng',
      subtitle: 'Thêm tên người dùng hoặc sử dụng gợi ý của chúng tôi. Bạn có thể đổi tên này bất kỳ lúc nào.',
      content: Column(
        children: [
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Tên người dùng',
              labelStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
              suffixIcon: const Icon(Icons.check_circle_outline, color: Colors.green), 
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Tiếp', onPressed: _nextStep),
        ],
      ),
    );
  }

  // BƯỚC 6: MẬT KHẨU & BIO (ĐỂ KHỚP VỚI HÀM SIGN UP CỦA ÔNG)
  Widget _buildFinalPasswordStep() {
    return _buildStepLayout(
      title: 'Tạo mật khẩu',
      subtitle: 'Tạo mật khẩu gồm ít nhất 6 chữ cái hoặc chữ số. Bạn nên chọn mật khẩu khó đoán.',
      content: Column(
        children: [
          _buildInputField(controller: _passwordController, hintText: 'Mật khẩu', isObscure: true),
          const SizedBox(height: 12),
          _buildInputField(controller: _confirmPasswordController, hintText: 'Xác nhận mật khẩu', isObscure: true),
          const SizedBox(height: 12),
          _buildInputField(controller: _bioController, hintText: 'Tiểu sử (Bio)'),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _signUpUserFinal, // GỌI API FIREBASE Ở ĐÂY
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0064E0),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Hoàn tất đăng ký', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ================= CÁC WIDGET DÙNG CHUNG =================

  Widget _buildStepLayout({required String title, String? subtitle, Widget? subtitleWidget, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (subtitleWidget != null) subtitleWidget,
          if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4)),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hintText, bool isObscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0064E0),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSecondaryButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2E),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      child: Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(), 
            child: const Text('Tôi có tài khoản rồi', style: TextStyle(color: Color(0xFF3797EF), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}