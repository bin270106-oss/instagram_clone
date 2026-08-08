import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class StorageMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    bool isPost,
  ) async {
    Reference ref = _storage.ref().child(childName).child(_auth.currentUser!.uid);

    if (isPost) {
      String id = const Uuid().v1();
      ref = ref.child(id);
    }

    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadImageToImgBB(Uint8List file) async {
    try {
      String base64Image = base64Encode(file);
      String apiKey = "848356f9c5214572f89c23e305b8cc8f";

      // 3. Gửi request POST lên ImgBB
      var url = Uri.parse('https://api.imgbb.com/1/upload');
      var response = await http.post(url, body: {
        'key': apiKey,
        'image': base64Image,
      });
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String imageUrl = jsonResponse['data']['url'];
        return imageUrl;
      } else {
        throw Exception("Lỗi khi tải ảnh lên ImgBB: ${response.body}");
      }
    } catch (e) {
      print(e.toString());
      throw Exception("Không thể kết nối đến ImgBB");
    }
  }
}