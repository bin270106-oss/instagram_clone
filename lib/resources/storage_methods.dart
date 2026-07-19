import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class StorageMethods {
  // Hàm này trả về Link ảnh từ ImgBB
  Future<String> uploadImageToImgBB(Uint8List fileBytes) async {
    // Thay API_KEY của ông vào đây
    const String apiKey = '0f883d771c6a41c072a5fad059646708'; 
    final Uri url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    String base64Image = base64Encode(fileBytes);

    final response = await http.post(
      url,
      body: {
        'image': base64Image,
      }, 
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['data']['url']; 
    } else {
      throw Exception('Lỗi ImgBB: ${response.statusCode}');
    }
  }
}