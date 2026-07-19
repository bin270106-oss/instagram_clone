import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. HÀM UPLOAD ẢNH LÊN IMGBB LẤY LINK
  Future<String> uploadImageToImgBB(Uint8List fileBytes) async {
    try {
      // ĐIỀN API KEY IMGBB CỦA ÔNG VÀO ĐÂY NHÉ 👇
      const String apiKey = '0f883d771c6a41c072a5fad059646708'; 
      final Uri url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      // Chuyển ảnh thành chuỗi base64 để ném qua ImgBB
      String base64Image = base64Encode(fileBytes);

      final response = await http.post(
        url,
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['data']['url']; // Trả về cái link xịn sò
      } else {
        throw Exception('Lỗi khi up ảnh lên ImgBB: ${response.body}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 2. HÀM ĐĂNG BÀI VIẾT LÊN FIREBASE FIRESTORE
  Future<String> uploadPost(
    String description,
    Uint8List file, // Dùng Uint8List để tương thích tốt với mọi dòng máy
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Đã xảy ra lỗi";
    try {
      // Bước 2.1: Lấy link ảnh từ ImgBB
      String photoUrl = await uploadImageToImgBB(file);

      // Bước 2.2: Tạo ID duy nhất cho bài viết
      String postId = const Uuid().v1();

      // Bước 2.3: Đóng gói dữ liệu bài viết
      Map<String, dynamic> postData = {
        'description': description,
        'uid': uid,
        'username': username,
        'postId': postId,
        'datePublished': DateTime.now(), // Thời gian thực
        'postUrl': photoUrl,             // Link ảnh ImgBB
        'profImage': profImage,
        'likes': [],                     // Mảng chứa ID những người thả tim
      };

      // Bước 2.4: Đẩy lên collection 'posts' trong Firestore
      await _firestore.collection('posts').doc(postId).set(postData);

      res = "Thành công";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}