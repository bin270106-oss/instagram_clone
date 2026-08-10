import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi tin nhắn text
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    required String chatRoomId,
  }) async {
    try {
      if (text.trim().isEmpty) return;

      String messageId = const Uuid().v1();

      // 1. Lưu tin nhắn chi tiết vào sub-collection 'messages'
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Cập nhật thông tin đoạn chat bên ngoài (để hiển thị danh sách Chat List)
      await _firestore.collection('chats').doc(chatRoomId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'users': [senderId, receiverId], // Phục vụ cho việc query lấy danh sách chat
      }, SetOptions(merge: true));

    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
    }
  }

  // Gửi tin nhắn hình ảnh/âm thanh (Tạm thời để khung, code tính năng này sau)
  Future<void> sendMediaMessage(String senderId, String receiverId, var file, String type) async {
    // Code up file lên Storage và gửi tin nhắn
  }
}