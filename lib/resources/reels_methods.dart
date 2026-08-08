import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/mock_reels.dart';

class ReelsMethods {
  Future<String?> uploadVideoToCatbox(String videoPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );

      // Định dạng tham số upload cho Catbox API
      request.fields['reqtype'] = 'fileupload';
      request.files.add(await http.MultipartFile.fromPath('fileToUpload', videoPath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        String videoUrl = response.body.trim();
        print("Upload Video thành công: $videoUrl");
        return videoUrl;
      } else {
        print("Lỗi Catbox Server: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi upload video: $e");
      return null;
    }
  }

  // 1. Hàm Upload Reel (Dùng tệp Video chọn từ máy)
  Future<String> uploadReel(
    String description,
    String videoPath,
    String uid,
    String username,
    String profImage,
  ) async {
    try {
      String finalVideoUrl = videoPath;

      // Nếu video là file nằm trong máy (chụp/quay từ camera hoặc chọn từ thư viện)
      if (!videoPath.startsWith('http')) {
        String? uploadedUrl = await uploadVideoToCatbox(videoPath);
        if (uploadedUrl != null) {
          finalVideoUrl = uploadedUrl; // Gán link .mp4 online nhận được từ server
        }
      }

      // Tạo một ID chung để dùng cho cả mockReel và Firebase
      String reelId = DateTime.now().millisecondsSinceEpoch.toString();

      // === 1. LƯU VÀO MOCK REELS (Để UI hiển thị ngay lập tức) ===
      mockReels.insert(0, {
        'id': reelId,
        'thumbnail': finalVideoUrl, // Link video .mp4 online
        'videoUrl': finalVideoUrl,  // Link video dùng để phát
        'username': username.isNotEmpty ? username : 'user_cua_tui',
        'avatar': (profImage.isNotEmpty && !profImage.contains('toppng.com'))
            ? profImage
            : 'https://i.pravatar.cc/150?img=12',
        'caption': description.isNotEmpty ? description : 'Reel video mới vừa đăng! 🎥🔥',
        'likes': 0,
        'comments': 0,
        'isLiked': false,
        'isFollowing': false,
        'isLocalFile': false,
      });

      // === 2. LƯU LÊN FIREBASE FIRESTORE (Để lưu trữ vĩnh viễn trên server) ===
      await FirebaseFirestore.instance.collection('reels').doc(reelId).set({
        'reelId': reelId,
        'uid': uid,
        'username': username.isNotEmpty ? username : 'user_cua_tui',
        'profImage': (profImage.isNotEmpty && !profImage.contains('toppng.com'))
            ? profImage
            : 'https://i.pravatar.cc/150?img=12',
        'videoUrl': finalVideoUrl,
        'thumbnailUrl': finalVideoUrl, // Dùng tạm link video làm thumbnail
        'caption': description.isNotEmpty ? description : 'Reel video mới vừa đăng! 🎥🔥',
        'likes': [], // Để mảng trống để lưu danh sách người dùng thả tim sau này
        'views': 0,
        'datePublished': DateTime.now(),
      });

      return "Thành công";
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Logic Thả tim
  void toggleLike(Map<String, dynamic> reel) {
    bool isLiked = reel['isLiked'] ?? false;
    reel['isLiked'] = !isLiked;

    int currentLikes = reel['likes'] is int ? reel['likes'] : 0;
    reel['likes'] = reel['isLiked'] ? currentLikes + 1 : currentLikes - 1;
  }

  // 3. Logic Theo dõi
  void toggleFollow(Map<String, dynamic> reel) {
    bool isFollowing = reel['isFollowing'] ?? false;
    reel['isFollowing'] = !isFollowing;
  }
}