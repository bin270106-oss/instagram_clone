import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:instagram_clone/models/user.dart' as model;
import 'package:instagram_clone/resources/storage_methods.dart';

class PostsMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // HÀM LẤY THÔNG TIN USER TỪ DATABASE (Phục vụ cho việc chuẩn bị đăng bài)
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot snap = await _firestore.collection('users').doc(currentUser.uid).get();
    return model.User.fromSnap(snap);
  }

  // 2. HÀM ĐĂNG BÀI VIẾT LÊN FIREBASE FIRESTORE
  Future<String> uploadPost(
    String description,
    Uint8List file, // Dùng Uint8List để tương thích tốt với mọi dòng máy
    String uid,
    String username,
    String profImage,
    {DateTime? unlockDate}
  ) async {
    String res = "Đã xảy ra lỗi";
    try {
      // Bước 2.1: Gọi StorageMethods để lấy link ảnh thay vì viết lại HTTP Request
      String photoUrl = await StorageMethods().uploadImageToImgBB(file);

      // Bước 2.2: Tạo ID duy nhất cho bài viết
      String postId = const Uuid().v1();

      // Bước 2.3: Đóng gói dữ liệu bài viết
      Map<String, dynamic> postData = {
        'description': description,
        'uid': uid,
        'username': username,
        'postId': postId,
        'datePublished': DateTime.now(), // Thời gian thực
        'postUrl': photoUrl, // Link ảnh ImgBB
        'profImage': profImage,
        'likes': [], // Mảng chứa ID những người thả tim
        'unlockDate': unlockDate,
      };

      // Bước 2.4: Đẩy lên collection 'posts' trong Firestore
      await _firestore.collection('posts').doc(postId).set(postData);

      res = "Thành công";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // 1. HÀM THẢ TIM / BỎ TIM BÀI VIẾT
  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        // Nếu đã thích rồi thì xóa uid khỏi mảng likes (Bỏ tim)
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        // Nếu chưa thích thì thêm uid vào mảng likes (Thả tim)
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 2. HÀM ĐĂNG BÌNH LUẬN
  Future<void> postComment(String postId, String text, String uid, String name, String profilePic) async {
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // 3. HÀM LƯU BÀI VIẾT VÀO BỘ SƯU TẬP (SAVED POSTS)
  Future<void> savePost(String uid, String postId) async {
    try {
      DocumentSnapshot userSnap = await _firestore.collection('users').doc(uid).get();
      List savedPosts = (userSnap.data() as dynamic)['saved'] ?? [];

      if (savedPosts.contains(postId)) {
        await _firestore.collection('users').doc(uid).update({
          'saved': FieldValue.arrayRemove([postId]),
        });
      } else {
        await _firestore.collection('users').doc(uid).update({
          'saved': FieldValue.arrayUnion([postId]),
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // HÀM LẤY DANH SÁCH BÀI VIẾT ĐÃ LƯU DỰA TRÊN MẢNG 'saved' CỦA USER
  Future<List<Map<String, dynamic>>> getSavedPosts(String uid) async {
    try {
      // 1. Lấy thông tin user để đọc mảng saved (chứa các postId)
      DocumentSnapshot userSnap = await _firestore.collection('users').doc(uid).get();
      List savedPostIds = (userSnap.data() as dynamic)['saved'] ?? [];

      if (savedPostIds.isEmpty) {
        return [];
      }

      // 2. Query lấy các bài viết có postId nằm trong mảng saved
      // Firestore giới hạn `whereIn` tối đa 10 phần tử một lần, nhưng nếu lưu ít thì dùng tạm. 
      // Nếu sau này lưu nhiều, ta có thể fetch từng cái hoặc tối ưu sau.
      QuerySnapshot postSnap = await _firestore
          .collection('posts')
          .where('postId', whereIn: savedPostIds)
          .get();

      return postSnap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  // =========================================================================
  // BỔ SUNG CÁC HÀM PHỤC VỤ CHO TRANG PROFILE (KHÔNG CHỈNH SỬA CODE CŨ Ở TRÊN)
  // =========================================================================

  // 3. Lấy DocumentSnapshot của User theo UID (Phục vụ cho ProfileScreen)
  Future<DocumentSnapshot> getUserSnap(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // 4. Lấy danh sách bài viết của User theo UID (Phục vụ tính số bài & hiện GridView)
  Future<QuerySnapshot> getPostSnapshots(String uid) async {
    return await _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .get();
  }
}