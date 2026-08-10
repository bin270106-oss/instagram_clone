import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_clone/resources/storage_methods.dart';
import 'notification_methods.dart';

class UserMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Lấy thông tin chi tiết của User theo UID (Giữ nguyên)
  Future<DocumentSnapshot> getUserDetails(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // 2. Hàm Follow / Unfollow người dùng (Giữ nguyên + Bổ sung gửi thông báo)
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

        // Gửi thông báo Follow cho người được theo dõi
        await NotificationMethods().sendNotification(
          targetUid: followId,
          fromUid: uid,
          type: 'follow',
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 3. Cập nhật thông tin profile (Đã thêm Tên & Giới tính, dùng StorageMethods upload ImgBB)
  Future<String> updateUserProfile({
    String? uid,
    required String name,
    required String username,
    required String bio,
    required String gender,
    Uint8List? file,
    required String currentPhotoUrl,
  }) async {
    String res = "Đã xảy ra lỗi";
    try {
      String photoUrl = currentPhotoUrl;

      // Nếu người dùng chọn ảnh đại diện mới -> Upload lên ImgBB thông qua StorageMethods
      if (file != null) {
        photoUrl = await StorageMethods().uploadImageToImgBB(file);
      }

      String targetUid = uid ?? _auth.currentUser!.uid;

      // Cập nhật dữ liệu thật lên Firestore
      await _firestore.collection('users').doc(targetUid).update({
        'name': name.trim(),
        'username': username.trim(),
        'bio': bio.trim(),
        'gender': gender,
        'photoUrl': photoUrl,
      });

      res = "Thành công";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Alias hỗ trợ gọi tên hàm rút gọn updateProfile
  Future<String> updateProfile({
    String? uid,
    required String name,
    required String username,
    required String bio,
    required String gender,
    Uint8List? imageBytes,
    Uint8List? file,
    required String currentPhotoUrl,
  }) async {
    return await updateUserProfile(
      uid: uid,
      name: name,
      username: username,
      bio: bio,
      gender: gender,
      file: file ?? imageBytes,
      currentPhotoUrl: currentPhotoUrl,
    );
  }
}