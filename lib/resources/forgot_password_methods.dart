import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> resetPassword({
    required String email,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      if (email.isNotEmpty) {
        // Gửi liên kết đặt lại mật khẩu về email
        await _auth.sendPasswordResetEmail(email: email);
        res = "Thành công";
      } else {
        res = "Vui lòng nhập địa chỉ email của bạn";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'invalid-email') {
        res = "Định dạng email không hợp lệ!";
      } else if (err.code == 'user-not-found') {
        res = "Không tìm thấy tài khoản nào liên kết với email này!";
      } else {
        res = err.message ?? "Lỗi xảy ra trong quá trình gửi email khôi phục.";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}