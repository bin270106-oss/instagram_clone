import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_clone/models/user.dart' as model;

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm Đăng ký tài khoản (Đã thêm confirmPassword)
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
        
        // Kiểm tra xem mật khẩu nhập lại có trùng khớp không
        if (password != confirmPassword) {
          return "Mật khẩu xác nhận không trùng khớp!";
        }

        // 1. Tạo user trên Firebase Authentication
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // GỬI EMAIL XÁC THỰC ĐẾN HỘP THƯ NGƯỜI DÙNG
        await cred.user!.sendEmailVerification();

        String defaultPhotoUrl = "https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083t7199g30u7.png";

        // 2. Tạo đối tượng User từ model dữ liệu
        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          email: email,
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
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hàm Đăng nhập tài khoản
  Future<String> logInUser({
    required String email,
    required String password,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // 1. Thực hiện đăng nhập bằng email và password
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. KIỂM TRA XEM EMAIL ĐÃ ĐƯỢC XÁC THỰC CHƯA
        if (!cred.user!.emailVerified) {
          await _auth.signOut(); // Đăng xuất ngay lập tức nếu chưa kích hoạt
          return "Tài khoản chưa được xác thực! Vui lòng kiểm tra email của bạn.";
        }

        res = "Thành công";
      } else {
        res = "Vui lòng điền đầy đủ email và mật khẩu";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'user-not-found' || err.code == 'wrong-password' || err.code == 'invalid-credential') {
        res = "Email hoặc mật khẩu không chính xác!";
      } else if (err.code == 'invalid-email') {
        res = "Định dạng email không hợp lệ!";
      } else {
        res = err.message ?? "Lỗi đăng nhập xảy ra.";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}