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
}