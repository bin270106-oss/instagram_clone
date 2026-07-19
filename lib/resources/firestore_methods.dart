import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:instagram_clone/models/user.dart' as model;
import 'package:instagram_clone/resources/storage_methods.dart'; // Import StorageMethods vào đây

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; //[cite: 15]
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // HÀM LẤY THÔNG TIN USER TỪ DATABASE (Phục vụ cho việc chuẩn bị đăng bài)
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot snap = await _firestore.collection('users').doc(currentUser.uid).get();
    return model.User.fromSnap(snap);
  }

  // 2. HÀM ĐĂNG BÀI VIẾT LÊN FIREBASE FIRESTORE[cite: 15]
  Future<String> uploadPost(
    String description,
    Uint8List file, // Dùng Uint8List để tương thích tốt với mọi dòng máy[cite: 15]
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Đã xảy ra lỗi"; //[cite: 15]
    try {
      // Bước 2.1: Gọi StorageMethods để lấy link ảnh thay vì viết lại HTTP Request
      String photoUrl = await StorageMethods().uploadImageToImgBB(file);

      // Bước 2.2: Tạo ID duy nhất cho bài viết[cite: 15]
      String postId = const Uuid().v1(); //[cite: 15]

      // Bước 2.3: Đóng gói dữ liệu bài viết[cite: 15]
      Map<String, dynamic> postData = {
        'description': description, //[cite: 15]
        'uid': uid, //[cite: 15]
        'username': username, //[cite: 15]
        'postId': postId, //[cite: 15]
        'datePublished': DateTime.now(), // Thời gian thực[cite: 15]
        'postUrl': photoUrl, // Link ảnh ImgBB[cite: 15]
        'profImage': profImage, //[cite: 15]
        'likes': [], // Mảng chứa ID những người thả tim[cite: 15]
      };

      // Bước 2.4: Đẩy lên collection 'posts' trong Firestore[cite: 15]
      await _firestore.collection('posts').doc(postId).set(postData); //[cite: 15]

      res = "Thành công"; //[cite: 15]
    } catch (err) {
      res = err.toString(); //[cite: 15]
    }
    return res; //[cite: 15]
  }
}