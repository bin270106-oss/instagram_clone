import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'story_preview_screen.dart';
import 'package:flutter/cupertino.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  File? _file;
  bool _isVideo = false;

  // Hàm chọn file từ Thư viện (Hỗ trợ cả Ảnh và Video)
  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    // Cho phép chọn cả ảnh hoặc video
    final pickedFile = await picker.pickMedia();

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
        // Kiểm tra xem đuôi file có phải video không
        String path = pickedFile.path.toLowerCase();
        if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi')) {
          _isVideo = true;
        } else {
          _isVideo = false;
        }
      });

      // Chọn xong chuyển ngay sang màn hình Preview kèm file và phân loại
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryPreviewScreen(
            file: _file!,
            isVideo: _isVideo,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Tự động mở bộ sưu tập ngay khi vào màn hình này cho tiện
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickMedia(ImageSource.gallery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              color: Colors.white,
              radius: 14,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang chuyển tới thư viện...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _pickMedia(ImageSource.gallery),
              child: Text('Mở Thư Viện Ngay', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}