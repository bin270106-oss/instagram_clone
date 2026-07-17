import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String bio;

  const User({
    required this.email,
    required this.uid,
    required this.photoUrl,
    required this.username,
    required this.bio,
  });

  // Chuyển đổi đối tượng User thành Map để lưu lên Firestore
  Map<String, dynamic> toJson() => {
    "username": username,
    "uid": uid,
    "email": email,
    "photoUrl": photoUrl,
    "bio": bio,
  };

  // Chuyển dữ liệu từ Firestore về lại đối tượng User trong App
  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      username: snapshot['username'] ?? '',
      uid: snapshot['uid'] ?? '',
      email: snapshot['email'] ?? '',
      photoUrl: snapshot['photoUrl'] ?? '',
      bio: snapshot['bio'] ?? '',
    );
  }
}
