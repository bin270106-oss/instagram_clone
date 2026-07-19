import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_clone/models/user.dart' as model;

class SignUpMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signUpUser({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    required String bio,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      if (email.isNotEmpty && password.isNotEmpty && confirmPassword.isNotEmpty && username.isNotEmpty) {
        
        // Xử lý chuỗi email: Cắt khoảng trắng 2 đầu và chuyển thành chữ thường
        String formattedEmail = email.trim().toLowerCase();

        // Kiểm tra định dạng bắt buộc phải là @gmail.com
        if (!formattedEmail.endsWith('@gmail.com')) {
          return "Vui lòng nhập email đúng định dạng @gmail.com";
        }
        
        // Kiểm tra xem mật khẩu nhập lại có trùng khớp không
        if (password != confirmPassword) {
          return "Mật khẩu xác nhận không trùng khớp!";
        }

        // 1. Tạo user trên Firebase Authentication
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: formattedEmail, // Truyền email đã được xử lý chuẩn
          password: password,
        );

        // GỬI EMAIL XÁC THỰC ĐẾN HỘP THƯ NGƯỜI DÙNG
        await cred.user!.sendEmailVerification();

        String defaultPhotoUrl = "https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083t7199g30u7.png";

        // 2. Tạo đối tượng User từ model dữ liệu
        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          email: formattedEmail, // Lưu email đã được xử lý chuẩn vào Database
          bio: bio,
          photoUrl: defaultPhotoUrl,
        );

        // 3. Lưu thông tin chi tiết vào Firestore Database
        await _firestore.collection('users').doc(cred.user!.uid).set(
          user.toJson(),
        );

        res = "Thành công";
      } else {
        res = "Vui lòng điền đầy đủ thông tin";
      }
    } on FirebaseAuthException catch (err) {
      // Bắt thêm lỗi trường hợp email bị trùng lặp đã tồn tại trên Firebase
      if (err.code == 'email-already-in-use') {
        res = "Email này đã được sử dụng cho một tài khoản khác!";
      } else {
        res = err.message ?? "Lỗi đăng ký xảy ra.";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}