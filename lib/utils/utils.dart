import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

// Hàm mở thư viện ảnh hoặc camera
Future<Uint8List?> pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);

  if (file != null) {
    return await file.readAsBytes(); // Trả về dạng Uint8List để chuẩn với hàm uploadPost của ní
  }
  print('Không có hình ảnh nào được chọn');
  return null;
}
// Hàm chọn video từ thư viện
Future<File?> pickVideo() async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickVideo(source: ImageSource.gallery);

  if (file != null) {
    return File(file.path);
  }
  print('Không có video nào được chọn');
  return null;
}

// Hàm hiển thị thông báo SnackBar
void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}