import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Thêm Firestore

  Future<String> resetPassword({
    required String email,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      if (email.isNotEmpty) {
        // Loại bỏ khoảng trắng thừa ở đầu và cuối email
        String formattedEmail = email.trim().toLowerCase();

        // 1. Kiểm tra định dạng bắt buộc phải là @gmail.com
        if (!formattedEmail.endsWith('@gmail.com')) {
          return "Vui lòng nhập email đúng định dạng @gmail.com";
        }

        // 2. Truy vấn vào Firestore xem có document nào chứa email này không
        var userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: formattedEmail)
            .get();
        
        // Nếu danh sách trả về rỗng, nghĩa là email chưa được đăng ký
        if (userQuery.docs.isEmpty) {
          return "Không tìm thấy tài khoản nào liên kết với email này!";
        }

        // 3. Gửi liên kết đặt lại mật khẩu về email nếu qua được 2 bước trên
        await _auth.sendPasswordResetEmail(email: formattedEmail);
        res = "Thành công";
      } else {
        res = "Vui lòng nhập địa chỉ email của bạn";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'invalid-email') {
        res = "Định dạng email không hợp lệ!";
      } else {
        res = err.message ?? "Lỗi xảy ra trong quá trình gửi email khôi phục.";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}