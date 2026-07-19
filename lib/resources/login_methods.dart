import 'package:firebase_auth/firebase_auth.dart';

class LoginMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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