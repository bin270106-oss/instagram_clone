import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../widgets/custom_avatar.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories; // Nhận danh sách tin
  final int initialIndex; // Vị trí tin bắt đầu xem

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadMediaForCurrentIndex();
  }

  // Hàm tải lại video/ảnh khi chuyển đổi giữa các tin
  void _loadMediaForCurrentIndex() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    if (widget.stories.isEmpty) return;

    var currentStory = widget.stories[currentIndex];
    String type = currentStory['type'] ?? 'image';
    String url = currentStory['url'] ?? '';

    if (type == 'video' && url.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
              _videoController?.play();
              _videoController?.setLooping(true);
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Chuyển sang tin tiếp theo
  void _nextStory() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _loadMediaForCurrentIndex();
    } else {
      Navigator.pop(context); // Xem hết danh sách thì thoát màn hình
    }
  }

  // Quay lại tin trước đó
  void _prevStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _loadMediaForCurrentIndex();
    }
  }

  // Popup "Xem thêm" cho chủ nhân tin
  void _showMoreOptionsModal(BuildContext parentContext) {
    if (widget.stories.isEmpty) return;
    final String storyId = widget.stories[currentIndex]['storyId']?.toString() ?? '';

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Text(
                        'Giới thiệu về tin này',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                    title: Text(
                      'Xóa tin',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(modalContext);

                      if (storyId.isEmpty) {
                        if (!mounted) return;
                        Navigator.pop(parentContext);
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('stories')
                            .doc(storyId)
                            .delete();

                        if (!mounted) return;
                        
                        // Nếu xóa hết sạch tin trong list thì thoát luôn, còn không thì chuyển sang tin kế tiếp
                        if (widget.stories.length <= 1) {
                          Navigator.pop(parentContext);
                        } else {
                          setState(() {
                            widget.stories.removeAt(currentIndex);
                            if (currentIndex >= widget.stories.length) {
                              currentIndex = widget.stories.length - 1;
                            }
                          });
                          _loadMediaForCurrentIndex();
                        }

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Đã xóa tin thành công!')),
                        );
                      } catch (e) {
                        debugPrint('Lỗi xóa tin: $e');
                        if (!mounted) return;
                        Navigator.pop(parentContext);
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text('Xóa thất bại, đã thoát trang: $e')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.white, size: 24),
                    title: Text('Lưu trữ', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_border, color: Colors.white, size: 24),
                    title: Text('Nêu bật', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download, color: Colors.white, size: 24),
                    title: Text('Lưu...', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
                    title: Text('Chia sẻ dưới dạng bài viết...', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
                    title: Text('Chỉnh sửa nhãn AI', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                    title: Text('Cài đặt tin', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.do_not_disturb_alt, color: Colors.white, size: 24),
                    title: Text('Tắt tính năng bình luận', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    onTap: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
    }

    var currentStory = widget.stories[currentIndex];
    String ownerUid = currentStory['uid'] ?? '';
    String url = currentStory['url'] ?? '';
    String type = currentStory['type'] ?? 'image';
    bool isOwner = (ownerUid == currentUid);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. NỘI DUNG MEDIA (ẢNH / VIDEO) VÀ BẮT SỰ KIỆN CHẠM TRÁI / PHẢI ĐỂ CHUYỂN TIN
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  double screenWidth = MediaQuery.of(context).size.width;
                  if (details.localPosition.dx < screenWidth / 3) {
                    _prevStory(); // Chạm bên trái màn hình -> Quay lại tin trước
                  } else {
                    _nextStory(); // Chạm bên phải màn hình -> Sang tin tiếp theo
                  }
                },
                onVerticalDragEnd: (details) => Navigator.pop(context),
                child: type == 'video'
                    ? (_isVideoInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator(color: Colors.white)))
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text('Không thể tải tệp tin', style: TextStyle(color: Colors.white)),
                        ),
                      ),
              ),
            ),

            // 2. THANH PROGRESS BAR (TỰ ĐỘNG CHIA THEO SỐ LƯỢNG TIN)
            Positioned(
              top: 6,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 3. HEADER (AVATAR + TÊN + NGÔI SAO + NÚT ĐÓNG)
            Positioned(
              top: 16,
              left: 12,
              right: 12,
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(ownerUid).get(),
                builder: (context, snapshot) {
                  String username = isOwner ? 'Tin của bạn' : 'User';
                  String photoUrl = '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var userData = snapshot.data!.data();
                    if (!isOwner) {
                      username = userData?['username'] ?? 'User';
                    }
                    photoUrl = userData?['photoUrl'] ?? '';
                  }

                  return Row(
                    children: [
                      CustomAvatar(radius: 18, avatarUrl: photoUrl),
                      const SizedBox(width: 10),
                      Text(
                        username,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vừa xong',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      if (isOwner)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 14),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 4. FOOTER DƯỚI CÙNG
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: isOwner ? _buildOwnerFooter() : _buildViewerFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerFooter() {
    return Row(
      children: [
        _buildOwnerAction(Icons.people_outline, 'Hoạt động', () {}),
        const Spacer(),
        _buildOwnerAction(Icons.favorite_border, 'Tin nổi bật', () {}),
        const SizedBox(width: 20),
        _buildOwnerAction(Icons.alternate_email, 'Nhắc đến', () {}),
        const SizedBox(width: 20),
        _buildOwnerAction(Icons.menu, 'Xem thêm', () => _showMoreOptionsModal(context)),
      ],
    );
  }

  Widget _buildOwnerAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildViewerFooter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Gửi tin nhắn...',
                hintStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.send_outlined, color: Colors.white, size: 26),
          onPressed: () {},
        ),
      ],
    );
  }
}