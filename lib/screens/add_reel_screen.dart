import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../resources/reels_methods.dart';

class AddReelScreen extends StatefulWidget {
  const AddReelScreen({super.key});

  @override
  State<AddReelScreen> createState() => _AddReelScreenState();
}

class _AddReelScreenState extends State<AddReelScreen> {
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  final TextEditingController _captionController = TextEditingController();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    try {
      var snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      setState(() {
        userData = snap.data() as Map<String, dynamic>?;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Chọn video và khởi tạo trình phát video
  Future<void> _selectVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      File file = File(video.path);
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();

      setState(() {
        _selectedVideo = file;
      });
    }
  }

  // Hàm bắn video lên máy chủ và lưu vào Firestore
  void _postReel() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn video trước khi đăng!')),
      );
      return;
    }
    if (userData == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      String res = await ReelsMethods().uploadReel(
        _captionController.text,
        _selectedVideo!.path,
        userData!['uid'],
        userData!['username'] ?? 'User',
        userData!['photoUrl'] ?? '',
      );

      if (res == "Thành công") {
        setState(() {
          _isLoading = false;
          _selectedVideo = null;
          _captionController.clear();
          _videoController?.pause();
          _videoController = null;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng Thước phim thành công!')),
          );
        }
      } else {
        setState(() { _isLoading = false; });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $res')));
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Thước phim mới', style: TextStyle(color: Colors.white)),
        actions: [
          // NÚT CHIA SẺ ĐÃ ĐƯỢC GẮN HÀM
          TextButton(
            onPressed: _isLoading ? null : _postReel, 
            child: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2)
                  )
                : const Text('Chia sẻ', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedVideo == null)
            Expanded(
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.upload_file, size: 80, color: Colors.white54),
                  onPressed: _selectVideo,
                ),
              ),
            )
          else
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _selectVideo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.video_collection, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Chọn video khác', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // KHUNG NHẬP CHÚ THÍCH DƯỚI CÙNG (Giữ nguyên của ông)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Viết chú thích cho thước phim...',
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