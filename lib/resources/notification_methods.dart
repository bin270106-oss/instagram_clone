import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NotificationMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm bắn thông báo lên Firebase
  Future<void> sendNotification({
    required String targetUid, // Người nhận thông báo (Chủ bài viết / Chủ tài khoản)
    required String fromUid,   // Người vừa bấm tim/follow/comment
    required String type,      // Loại: 'like_post', 'comment_post', 'follow'
    String? postId,            // (Tùy chọn) ID bài viết để hiển thị ảnh bìa
    String? commentText,       // (Tùy chọn) Nội dung comment để hiển thị
  }) async {
    try {
      // 1. NGĂN CHẶN TỰ SƯỚNG: Tự thả tim bài mình thì không gửi thông báo
      if (targetUid == fromUid) return; 

      // 2. TẠO ID ĐỘC NHẤT CHO THÔNG BÁO
      String notificationId = const Uuid().v1();

      // 3. ĐẨY LÊN FIRESTORE
      // Đường dẫn: users -> [UID người nhận] -> notifications -> [ID thông báo]
      await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .doc(notificationId)
          .set({
        'notificationId': notificationId,
        'type': type,
        'fromUid': fromUid,
        'postId': postId ?? '',
        'commentText': commentText ?? '',
        'time': FieldValue.serverTimestamp(), // Giờ máy chủ Firebase
        'isRead': false,
      });
    } catch (e) {
      print('Lỗi gửi thông báo: $e');
    }
  }
}