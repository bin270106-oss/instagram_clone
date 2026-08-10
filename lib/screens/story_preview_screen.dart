import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class StoryPreviewScreen extends StatefulWidget {
  final File file;
  final bool isVideo;

  const StoryPreviewScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  bool _isLoading = false;
  final TextEditingController _captionController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // 1. Upload ảnh lên ImgBB (Ní thay API Key của ní vào đây)
  Future<String> uploadImageToImgBB(File imageFile) async {
    const String apiKey = '848356f9c5214572f89c23e305b8cc8f'; 
    var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data']['url'];
    }
    throw Exception('Upload ảnh lên ImgBB thất bại');
  }

  // 2. Upload video lên Catbox.moe
  Future<String> uploadVideoToCatbox(File videoFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
    request.fields['reqtype'] = 'fileupload';
    request.files.add(await http.MultipartFile.fromPath('fileToUpload', videoFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.body.trim();
    }
    throw Exception('Upload video lên Catbox thất bại');
  }

  // 3. Lưu vào Firestore
  Future<void> _uploadStory({bool isCloseFriends = false}) async {
    setState(() => _isLoading = true);
    try {
      String mediaUrl = '';
      if (widget.isVideo) {
        mediaUrl = await uploadVideoToCatbox(widget.file);
      } else {
        mediaUrl = await uploadImageToImgBB(widget.file);
      }

      String storyId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance.collection('stories').doc(storyId).set({
        'storyId': storyId,
        'uid': currentUid,
        'url': mediaUrl,
        'type': widget.isVideo ? 'video' : 'image',
        'caption': _captionController.text.trim(),
        'isCloseFriends': isCloseFriends,
        'datePublished': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng Tin thành công!')),
      );
    } catch (e) {
      debugPrint('Lỗi đăng tin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Bấm ngoài để ẩn bàn phím
          child: Stack(
            children: [
              // 1. ẢNH HOẶC VIDEO PREVIEW
              Positioned.fill(
                child: Center(
                  child: widget.isVideo
                      ? const Icon(Icons.video_file, color: Colors.white, size: 80)
                      : Image.file(
                          widget.file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),

              // 2. NÚT ĐÓNG (X) Ở GÓC TRÊN BÊN TRÁI
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // 3. CỤM CÔNG CỤ BÊN GÓC TRÊN BÊN PHẢI (Aa, Sticker, Nhạc, AI...)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _buildToolButton(
                      child: Text(
                        'Aa',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildToolButton(
                      icon: Icons.sentiment_satisfied_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildToolButton(
                      icon: Icons.music_note_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildToolButton(
                      icon: Icons.auto_awesome,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildToolButton(
                      icon: Icons.keyboard_arrow_down,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // 4. THANH CHÚ THÍCH VÀ FOOTER DƯỚI CÙNG
              Positioned(
                bottom: 16,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ô nhập chú thích
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: _captionController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Thêm chú thích...',
                          hintStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // Hàng nút chia sẻ dưới cùng
                    Row(
                      children: [
                        // Nút Tin của bạn
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF262626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : () => _uploadStory(isCloseFriends: false),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, size: 12, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tin của bạn',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nút Bạn thân
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF262626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : () => _uploadStory(isCloseFriends: true),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.star, size: 12, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bạn thân',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nút gửi mũi tên xanh dương
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0095F6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Colors.white),
                            onPressed: _isLoading ? null : () => _uploadStory(isCloseFriends: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Hiệu ứng loading khi đang upload
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget phụ tạo khung tròn cho các icon công cụ bên phải
  Widget _buildToolButton({IconData? icon, Widget? child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: child ?? Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}