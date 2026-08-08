import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../models/mock_reels.dart';
import '../resources/reels_methods.dart';
import '../widgets/custom_avatar.dart';
import 'add_reel_screen.dart';

// 1. CHUYỂN BIẾN LÊN CLASS CHÍNH
class ReelsScreen extends StatefulWidget {
  final int initialIndex;
  final List<Map<String, dynamic>>? reelsList; // Thêm tham số nhận danh sách reels

  const ReelsScreen({super.key, this.initialIndex = 0, this.reelsList});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final ReelsMethods _reelsMethods = ReelsMethods();
  late PageController _pageController;
  List<Map<String, dynamic>> _currentReels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadReelsData();
  }

  // Tải danh sách reels từ Firestore và gộp chung với mockReels
  Future<void> _loadReelsData() async {
    if (widget.reelsList != null && widget.reelsList!.isNotEmpty) {
      setState(() {
        _currentReels = widget.reelsList!;
        _isLoading = false;
      });
    } else {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('reels')
            .get();
        
        List<Map<String, dynamic>> firestoreReels = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['reelId'] = doc.id;
          return data;
        }).toList();

        setState(() {
          // Gộp chung video từ Firestore lên đầu, sau đó đến mockReels để không bị mất cái nào hết
          _currentReels = [...firestoreReels, ...mockReels];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _currentReels = mockReels;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 💬 BẢNG BÌNH LUẬN (Mở BottomSheet)
  void _showCommentSheet(BuildContext context, Map<String, dynamic> reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ReelCommentSheet(
          reel: reel,
          onCommentAdded: () {
            setState(() {});
          },
        );
      },
    );
  }

  // 🚀 BẢNG CHIA SẺ
  void _showShareSheet(BuildContext context) {
    final List<String> titles = ['Tin của bạn', 'Tin nhắn', 'Sao chép', 'Khác'];
    final List<IconData> icons = [
      Icons.add_a_photo,
      Icons.send,
      Icons.copy,
      Icons.more_horiz,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Chia sẻ lên',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          child: Icon(icons[index], color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          titles[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 32),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReelScreen()),
            );
            _loadReelsData(); // Tải lại danh sách sau khi đăng thêm reel mới
          },
        ),
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _currentReels.length,
        itemBuilder: (context, index) {
          final reel = _currentReels[index];
          String videoUrl = reel['videoUrl'] ?? reel['thumbnailUrl'] ?? reel['thumbnail'] ?? '';
          bool isVideo = videoUrl.contains('.mp4') || videoUrl.contains('catbox') || videoUrl.contains('firebasestorage');

          String thumbnailUrl = reel['thumbnailUrl'] ?? reel['thumbnail'] ?? '';
          String profileImg = reel['profImage'] ?? reel['profileImage'] ?? reel['avatar'] ?? '';
          String username = reel['username'] ?? 'User';

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. PHÁT VIDEO HOẶC HIỂN THỊ ẢNH
              isVideo
                  ? _ReelVideoPlayer(videoUrl: videoUrl)
                  : (thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                        )),

              // 2. LỚP MỜ ĐEN PHỦ PHÍA DƯỚI
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),

              // 3. CỘT NÚT TƯƠNG TÁC
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // THẢ TIM
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _reelsMethods.toggleLike(reel);
                        });
                      },
                      child: Column(
                        children: [
                          Icon(
                            reel['isLiked'] == true
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: reel['isLiked'] == true
                                ? Colors.red
                                : Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${reel['likes'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BÌNH LUẬN
                    GestureDetector(
                      onTap: () => _showCommentSheet(context, reel),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${reel['comments'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CHIA SẺ
                    GestureDetector(
                      onTap: () => _showShareSheet(context),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.send_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Chia sẻ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Icon(Icons.more_vert, color: Colors.white),
                    const SizedBox(height: 20),

                    // ĐĨA NHẠC GÓC DƯỚI
                    CustomAvatar(
                      avatarUrl: profileImg,
                      username: username,
                      radius: 16,
                    ),
                  ],
                ),
              ),

              // 4. THÔNG TIN USER
              Positioned(
                left: 16,
                bottom: 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomAvatar(
                          avatarUrl: profileImg,
                          username: username,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _reelsMethods.toggleFollow(reel);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: reel['isFollowing'] == true
                                  ? Border.all(color: Colors.transparent)
                                  : Border.all(color: Colors.white, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                              color: reel['isFollowing'] == true
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              reel['isFollowing'] == true
                                  ? 'Đã theo dõi'
                                  : 'Theo dõi',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reel['caption'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.music_note, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Âm thanh gốc - Nhạc nền hot trend',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// WIDGET BẢNG BÌNH LUẬN TƯƠNG TÁC
// ==========================================
class _ReelCommentSheet extends StatefulWidget {
  final Map<String, dynamic> reel;
  final VoidCallback onCommentAdded;

  const _ReelCommentSheet({required this.reel, required this.onCommentAdded});

  @override
  State<_ReelCommentSheet> createState() => _ReelCommentSheetState();
}

class _ReelCommentSheetState extends State<_ReelCommentSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.reel['commentList'] == null) {
      widget.reel['commentList'] = <Map<String, dynamic>>[
        {
          'username': 'thanh_dev',
          'avatar': 'https://i.pravatar.cc/150?img=5',
          'text': 'Video đỉnh quá ní ơi! 🔥',
          'timeAgo': '2 giờ trước',
        },
        {
          'username': 'linh_flutter',
          'avatar': 'https://i.pravatar.cc/150?img=9',
          'text': 'Xịn xò quá, mượt mà lắm luôn!',
          'timeAgo': '1 giờ trước',
        },
      ];
    }
  }

  void _addComment() {
    String text = _commentController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        List<Map<String, dynamic>> commentList =
            List<Map<String, dynamic>>.from(widget.reel['commentList']);

        commentList.insert(0, {
          'username': 'user_cua_tui',
          'avatar': 'https://i.pravatar.cc/150?img=12',
          'text': text,
          'timeAgo': 'Vừa xong',
        });

        widget.reel['commentList'] = commentList;

        int currentComments = widget.reel['comments'] is int
            ? widget.reel['comments']
            : 0;
        widget.reel['comments'] = currentComments + 1;
      });

      _commentController.clear();
      widget.onCommentAdded();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List commentList = widget.reel['commentList'] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Bình luận (${widget.reel['comments'] ?? 0})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: commentList.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có bình luận nào. Hãy là người đầu tiên!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: commentList.length,
                      itemBuilder: (context, index) {
                        final comment = commentList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomAvatar(
                                avatarUrl: comment['avatar'],
                                username: comment['username'] ?? 'User',
                                radius: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment['username'] ?? 'User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          comment['timeAgo'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['text'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    const CustomAvatar(
                      avatarUrl: 'https://i.pravatar.cc/150?img=12',
                      username: 'user_cua_tui',
                      radius: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Thêm bình luận...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.blue),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET XỬ LÝ PHÁT VIDEO CHO MỖI REEL
// ==========================================
class _ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _ReelVideoPlayer({required this.videoUrl});

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}