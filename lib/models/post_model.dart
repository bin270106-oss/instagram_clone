import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String description;
  final String uid;
  final String username;
  final String postId;
  final DateTime datePublished;
  final String postUrl;
  final String profImage;
  final List likes;
  final DateTime? unlockDate; // <--- ĐÃ THÊM BIẾN NÀY

  Post({
    required this.description,
    required this.uid,
    required this.username,
    required this.postId,
    required this.datePublished,
    required this.postUrl,
    required this.profImage,
    required this.likes,
    this.unlockDate, // <--- ĐÃ THÊM VÀO CONSTRUCTOR
  });

  // Chuyển Object thành dạng Map để up lên Firebase
  Map<String, dynamic> toJson() => {
        'description': description,
        'uid': uid,
        'username': username,
        'postId': postId,
        'datePublished': datePublished,
        'postUrl': postUrl,
        'profImage': profImage,
        'likes': likes,
        'unlockDate': unlockDate, // <--- ĐÃ THÊM VÀO JSON
      };

  // Lấy dữ liệu từ Firebase ép kiểu về dạng Object Post
  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return Post(
      description: snapshot['description'],
      uid: snapshot['uid'],
      username: snapshot['username'],
      postId: snapshot['postId'],
      datePublished: (snapshot['datePublished'] as Timestamp).toDate(),
      postUrl: snapshot['postUrl'],
      profImage: snapshot['profImage'],
      likes: snapshot['likes'],
      // <--- ĐÃ THÊM LOGIC LẤY NGÀY MỞ KHÓA TỪ FIREBASE
      unlockDate: snapshot['unlockDate'] != null 
          ? (snapshot['unlockDate'] as Timestamp).toDate() 
          : null,
    );
  }
}