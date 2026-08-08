import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_clone/resources/storage_methods.dart';

class UserMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Lấy thông tin chi tiết của User theo UID
  Future<DocumentSnapshot> getUserDetails(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // 2. Hàm Follow / Unfollow người dùng
  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'] ?? [];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 3. Cập nhật thông tin profile (Upload Avatar lên ImgBB)
  Future<String> updateUserProfile({
    required String username,
    required String bio,
    Uint8List? file,
    required String currentPhotoUrl,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      String photoUrl = currentPhotoUrl;

      // Nếu người dùng chọn ảnh đại diện mới -> Upload lên ImgBB
      if (file != null) {
        photoUrl = await StorageMethods().uploadImageToImgBB(file);
      }

      // Cập nhật dữ liệu link ImgBB lên Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'username': username,
        'bio': bio,
        'photoUrl': photoUrl,
      });

      res = "Thành công";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}