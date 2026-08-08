import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String reelId;
  final String uid;
  final String username;
  final String profImage;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final dynamic datePublished;
  final List<dynamic> likes;
  final int views;

  const Reel({
    required this.reelId,
    required this.uid,
    required this.username,
    required this.profImage,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.datePublished,
    required this.likes,
    required this.views,
  });

  // Chuyển đổi từ Firebase Document thành đối tượng Reel
  static Reel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Reel(
      reelId: snapshot['reelId'] ?? '',
      uid: snapshot['uid'] ?? '',
      username: snapshot['username'] ?? '',
      profImage: snapshot['profImage'] ?? '',
      videoUrl: snapshot['videoUrl'] ?? '',
      thumbnailUrl: snapshot['thumbnailUrl'] ?? '',
      caption: snapshot['caption'] ?? '',
      datePublished: snapshot['datePublished'],
      likes: snapshot['likes'] ?? [],
      views: snapshot['views'] ?? 0,
    );
  }

  // Chuyển đổi thành Map để đẩy lên Firestore
  Map<String, dynamic> toJson() => {
        "reelId": reelId,
        "uid": uid,
        "username": username,
        "profImage": profImage,
        "videoUrl": videoUrl,
        "thumbnailUrl": thumbnailUrl,
        "caption": caption,
        "datePublished": datePublished,
        "likes": likes,
        "views": views,
      };
}