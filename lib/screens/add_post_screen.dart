import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/resources/posts_methods.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

DateTime? _selectedUnlockDate; // Biến lưu giờ khóa

class _AddPostScreenState extends State<AddPostScreen> {
  List<Uint8List> _selectedImages = [];
  bool _isLoading = false;
  final TextEditingController _captionController = TextEditingController();

  // Hàm chọn nhiều ảnh
  Future<void> _selectMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      List<Uint8List> byteImages = [];
      for (var img in images) {
        byteImages.add(await img.readAsBytes());
      }
      setState(() {
        _selectedImages = byteImages;
      });
    }
  }

  void _postImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ảnh')));
      return;
    }
    
    setState(() => _isLoading = true);
  
    try {
      // 1. Lấy thông tin user hiện tại từ Firebase để gắn vào bài viết
      var user = await PostsMethods().getUserDetails();

      // 2. Truyền đúng dữ liệu vào hàm uploadPost
      String res = await PostsMethods().uploadPost(
        _captionController.text,
        _selectedImages[0],      
        user.uid,                
        user.username,           
        user.photoUrl,
        unlockDate: _selectedUnlockDate,           
      );

      setState(() => _isLoading = false);

      if (res == "Thành công") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng bài viết!')));
          Navigator.pop(context); // Đóng trang sau khi đăng
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $res')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Hàm chọn thời gian mở khóa
  Future<void> _pickUnlockDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)), // Đăng tối đa 1 tháng
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedUnlockDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Dấu X để tắt màn hình
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bài viết mới', style: TextStyle(color: Colors.white)),
        actions: [
          // Nút Đăng thay cho nút Tiếp
          TextButton(
            onPressed: _isLoading ? null : _postImages,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2))
              : const Text('Đăng', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // Phần hiển thị ảnh ở giữa
          Container(
            height: MediaQuery.of(context).size.width, // Tạo khung vuông
            width: double.infinity,
            color: Colors.grey[900],
            child: _selectedImages.isEmpty
                ? const Center(child: Icon(Icons.photo_library, color: Colors.grey, size: 50))
                : PageView.builder( // Dùng PageView để lướt xem nếu chọn nhiều ảnh
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Image.memory(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
          
          // Thanh công cụ (Đã bỏ Zoom và Gần đây)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _pickUnlockDate,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10), // Khoảng cách với nút Chọn nhiều
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedUnlockDate != null ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _selectedUnlockDate != null 
                              ? '${_selectedUnlockDate!.hour}:${_selectedUnlockDate!.minute.toString().padLeft(2, '0')}' 
                              : 'Hẹn giờ',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút "Chọn nhiều" ảnh
                GestureDetector(
                  onTap: _selectMultipleImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.layers, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Chọn nhiều', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ô nhập caption
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Viết chú thích...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}