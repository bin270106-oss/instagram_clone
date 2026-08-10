import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../resources/posts_methods.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/story_bar.dart'; // 
import '../screens/add_post_screen.dart';// Import màn hình tạo bài đăng
import '../screens/notifications_screen.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  // Hàm reload trang khi vuốt Refresh ở trên cùng
  Future<void> _refreshFeed() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        // APPBAR ẨN/HIỆN TỰ ĐỘNG KHI VUỐT BÀI
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.black,
              floating: true,  // Vuốt nhẹ ngược lên là AppBar xuất hiện lại ngay
              snap: true,      // Trượt nảy nhanh mượt mà
              elevation: 0,
              centerTitle: true,
              // GÓC TRÁI: NÚT DẤU + CHUYỂN QUA MÀN HÌNH TẠO BÀI ĐĂNG
              leading: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPostScreen()),
                  );
                },
              ),
              // GIỮA: TÊN APP TKCT FONT BILLABONG UỐN LƯỢN
              title: Text(
                'TKCT',
                style: GoogleFonts.grandHotel(
                  color: Colors.white,
                  fontSize: 34,
                  letterSpacing: 1.2,
                ),
              ),
              // GÓC PHẢI: ICON TRÁI TIM CHUYỂN SANG TRANG THÔNG BÁO (ĐÃ XÓA CHAT)
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            ),
          ];
        },

        // NỘI DUNG CHÍNH (STORY BAR + DANH SÁCH BÀI VIẾT)
        body: RefreshIndicator(
          onRefresh: _refreshFeed,
          color: const Color(0xFF0095F6),
          backgroundColor: const Color(0xFF262626),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('datePublished', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              var docs = snapshot.data?.docs ?? [];

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: 1 + (docs.isEmpty ? 1 : docs.length),
                itemBuilder: (context, index) {
                  // VỊ TRÍ ĐẦU TIÊN (INDEX 0): WIDGET STORY BAR DÍNH NẰM TRONG FEED
                  if (index == 0) {
                    return const StoryBar();
                  }

                  // NẾU CHƯA CÓ BÀI VIẾT NÀO
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 60),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có bài viết nào',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // DANH SÁCH BÀI VIẾT REALTIME (GỌI CLASS BÊN DƯỚI CÙNG FILE NÀY)
                  var snap = docs[index - 1].data();
                  return PostItem(snap: snap);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ================= WIDGET POST ITEM NẰM GỌN TRONG FILE NÀY ==================
// ============================================================================

class PostItem extends StatefulWidget {
  final Map<String, dynamic> snap;
  const PostItem({super.key, required this.snap});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Offset? _tapPosition;
  bool _isHeartAnimating = false;
  int _lastTapTime = 0;

  void _handleDoubleTapDown(TapDownDetails details) {
    _tapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    if (_tapPosition == null) return;
    setState(() {
      _isHeartAnimating = true;
      _lastTapTime = DateTime.now().millisecondsSinceEpoch;
    });

    List likes = widget.snap['likes'] ?? [];
    String postId = widget.snap['postId'] ?? '';

    if (!likes.contains(currentUid)) {
      PostsMethods().likePost(postId, currentUid, likes);
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isHeartAnimating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    List likes = widget.snap['likes'] ?? [];
    List reposts = widget.snap['repostedBy'] ?? [];
    bool isLiked = likes.contains(currentUid);
    bool isReposted = reposts.contains(currentUid);
    String postId = widget.snap['postId'] ?? '';

    String timeAgo = '';
    if (widget.snap['datePublished'] != null) {
      DateTime date = (widget.snap['datePublished'] as Timestamp).toDate();
      timeAgo = DateFormat('dd/MM/yyyy').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header (Avatar + Tên)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CustomAvatar(radius: 18, avatarUrl: widget.snap['profImage'] ?? ''),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.snap['username'] ?? 'User',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (widget.snap['location'] != null && widget.snap['location'].toString().isNotEmpty)
                      Text(widget.snap['location'].toString(), style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                onPressed: () => _showPostOptionsMenu(context, widget.snap),
              ),
            ],
          ),
        ),

        // 2. Ảnh bài viết + Double Tap Animation (MÀU TIM ĐỎ-CAM INSTAGRAM XỊN)
        GestureDetector(
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Image.network(
                  widget.snap['postUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.grey[900],
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                  ),
                ),
              ),
              if (_tapPosition != null)
                Positioned(
                  left: _tapPosition!.dx - 50,
                  top: _tapPosition!.dy - 50,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isHeartAnimating ? 1.0 : 0.0,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_lastTapTime),
                        tween: Tween<double>(begin: 0.5, end: 1.2),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        // TRÁI TIM TÔNG ĐỎ - CAM NỔI BẬT CHUẨN INSTAGRAM
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF3040), // Đỏ Cam Instagram
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 3. Thanh nút tương tác
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFFFF3040) : Colors.white, size: 26),
                onPressed: () => PostsMethods().likePost(postId, currentUid, likes),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                onPressed: () => _showCommentsModal(context, postId),
              ),
              IconButton(
                icon: Icon(Icons.repeat, color: isReposted ? Colors.green : Colors.white, size: 24),
                onPressed: () => _toggleRepost(postId, reposts),
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 24),
                onPressed: () => _showShareModal(context, widget.snap),
              ),
              const Spacer(),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
                builder: (context, userSnap) {
                  List savedPosts = [];
                  if (userSnap.hasData && userSnap.data?.data() != null) {
                    savedPosts = (userSnap.data!.data() as Map<String, dynamic>)['savedPosts'] ?? [];
                  }
                  bool isSaved = savedPosts.contains(postId);
                  return IconButton(
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 26),
                    onPressed: () => _toggleSavePost(postId, savedPosts),
                  );
                },
              ),
            ],
          ),
        ),

        // 4. Lượt thích & Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${likes.length} lượt thích', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(text: '${widget.snap['username'] ?? ''} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: widget.snap['description'] ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots(),
                builder: (context, commentSnap) {
                  int count = commentSnap.data?.docs.length ?? 0;
                  return GestureDetector(
                    onTap: () => _showCommentsModal(context, postId),
                    child: Text(count > 0 ? 'Xem tất cả $count bình luận' : 'Thêm bình luận...', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(timeAgo, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // --- POPUP BÌNH LUẬN ---
  void _showCommentsModal(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),
                Text('Bình luận', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(color: Colors.white12, height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').orderBy('datePublished', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      var comments = snapshot.data!.docs;
                      if (comments.isEmpty) return Center(child: Text('Chưa có bình luận nào.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)));

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var cSnap = comments[index].data();
                          return ListTile(
                            leading: CustomAvatar(radius: 18, avatarUrl: cSnap['profilePic'] ?? ''),
                            title: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                children: [
                                  TextSpan(text: '${cSnap['name'] ?? 'User'} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: cSnap['text'] ?? ''),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              cSnap['datePublished'] != null ? DateFormat('dd/MM HH:mm').format((cSnap['datePublished'] as Timestamp).toDate()) : '',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 10),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
                    child: Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(currentUid).get(),
                          builder: (context, uSnap) {
                            String myPic = '';
                            if (uSnap.hasData && uSnap.data?.data() != null) {
                              myPic = (uSnap.data!.data() as Map<String, dynamic>)['photoUrl'] ?? '';
                            }
                            return CustomAvatar(radius: 16, avatarUrl: myPic);
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Thêm bình luận...',
                              hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            String text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
                              var userData = userDoc.data() ?? {};
                              await PostsMethods().postComment(postId, text, currentUid, userData['username'] ?? 'User', userData['photoUrl'] ?? '');
                              commentController.clear();
                            }
                          },
                          child: Text('Đăng', style: GoogleFonts.inter(color: const Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- POPUP CHIA SẺ ---
  void _showShareModal(BuildContext context, Map<String, dynamic> postSnap) {
    TextEditingController searchController = TextEditingController();
    List<String> selectedUids = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: searchController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: 'Tìm kiếm...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setModalState(() {}),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        var users = snapshot.data!.docs.where((doc) => doc.id != currentUid).toList();
                        String query = searchController.text.toLowerCase().trim();
                        if (query.isNotEmpty) {
                          users = users.where((doc) => (doc.data()['username'] ?? '').toString().toLowerCase().contains(query)).toList();
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var uData = users[index].data();
                            String uId = users[index].id;
                            bool isSelected = selectedUids.contains(uId);

                            return GestureDetector(
                              onTap: () => setModalState(() => isSelected ? selectedUids.remove(uId) : selectedUids.add(uId)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      CustomAvatar(radius: 28, avatarUrl: uData['photoUrl'] ?? ''),
                                      if (isSelected)
                                        Positioned(
                                          bottom: 0, right: 0,
                                          child: Container(
                                            decoration: const BoxDecoration(color: Color(0xFF0095F6), shape: BoxShape.circle),
                                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(uData['username'] ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.link, label: 'Sao chép liên kết',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: postSnap['postUrl'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết!')));
                          Navigator.pop(context);
                        },
                      ),
                      _buildQuickActionButton(icon: Icons.share, label: 'Chia sẻ qua...', onTap: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity, height: 44,
                      child: ElevatedButton(
                        onPressed: selectedUids.isEmpty ? null : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi bài viết cho ${selectedUids.length} người!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                        child: Text('Gửi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _toggleRepost(String postId, List reposts) async {
    try {
      if (reposts.contains(currentUid)) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({'repostedBy': FieldValue.arrayRemove([currentUid])});
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({'repostedBy': FieldValue.arrayUnion([currentUid])});
      }
    } catch (e) { debugPrint('Lỗi Repost: $e'); }
  }

  Future<void> _toggleSavePost(String postId, List savedPosts) async {
    try {
      if (savedPosts.contains(postId)) {
        await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'savedPosts': FieldValue.arrayRemove([postId])});
      } else {
        await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'savedPosts': FieldValue.arrayUnion([postId])});
      }
    } catch (e) { debugPrint('Lỗi Save: $e'); }
  }

  void _showPostOptionsMenu(BuildContext context, Map<String, dynamic> snap) {
    bool isMyPost = (snap['uid'] == currentUid);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMyPost)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Xóa bài viết', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance.collection('posts').doc(snap['postId']).delete();
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.redAccent),
                  title: const Text('Báo cáo bài viết', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo!')));
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}