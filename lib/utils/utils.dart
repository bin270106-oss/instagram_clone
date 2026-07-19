import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Hàm chọn ảnh dùng chung
Future<dynamic> pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);
  
  if (file != null) {
    return await file.readAsBytes(); // Trả về dạng byte để up lên ImgBB
  }
  print("Chưa chọn được ảnh");
}

// Hàm show thông báo dùng chung (để sau này báo Đăng bài thành công/thất bại)
showSnackBar(String content, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(content)),
  );
}