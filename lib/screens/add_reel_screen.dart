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
        userData = snap.data();
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Chọn video và khởi tạo trình phát video
  Future<void> _selectVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      _videoController?.dispose();

      setState(() {
        _selectedVideo = File(video.path);
      });

      _videoController = VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play(); // Tự động phát khi chọn xong
          _videoController!.setLooping(true); // Lặp lại video
        });
    }
  }

  // Hàm xử lý đăng Reels
  void _postReel() async {
    if (_selectedVideo == null || userData == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      String res = await ReelsMethods().uploadReel(
        _captionController.text,
        _selectedVideo!.path,
        userData!['uid'],
        userData!['username'],
        userData!['photoUrl'] ?? '', 
      );

      if (res == "Thành công") {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng Reels thành công!')),
        );
        Navigator.pop(context); // Quay lại trang trước
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thước phim mới', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _postReel,
            child: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                )
              : const Text(
                  'Đăng', 
                  style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
          )
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          
          // KHU VỰC HIỂN THỊ VIDEO Ở GIỮA
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _selectedVideo == null || _videoController == null
                  ? Center(
                      child: GestureDetector(
                        onTap: _selectVideo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.video_collection, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Chọn video', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _videoController!.value.isInitialized
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
          
          // NÚT CHỌN LẠI VIDEO
          if (_selectedVideo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
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
                ],
              ),
            ),

          // KHUNG NHẬP CHÚ THÍCH DƯỚI CÙNG
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