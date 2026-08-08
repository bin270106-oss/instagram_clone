import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi tin nhắn text
  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    // Code gom tin nhắn vào sub-collection 'messages' của đoạn chat
  }

  // Gửi tin nhắn hình ảnh/âm thanh
  Future<void> sendMediaMessage(String senderId, String receiverId, var file, String type) async {
    // Code up file lên Storage và gửi tin nhắn
  }
}