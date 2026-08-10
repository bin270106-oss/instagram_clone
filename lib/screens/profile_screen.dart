import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../resources/user_methods.dart';
import 'add_post_screen.dart';
import 'add_reel_screen.dart';
import 'discover_people_screen.dart';
import 'edit_profile_screen.dart';
import 'liked_posts_screen.dart';
import 'login_screen.dart';
import 'saved_posts_screen.dart';
import '../widgets/custom_avatar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_story_screen.dart';
import 'story_view_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid; 
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  int postLen = 0;
  int followersLen = 0;
  int followingLen = 0;
  bool isFollowing = false;
  bool isLoading = true;
  bool _showSuggestions = true; // MẶC ĐỊNH HIỂN THỊ GỢI Ý KẾT BẠN
  List<Map<String, dynamic>> _suggestedUsers = [];

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    getData();
    fetchSuggestedUsers();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      var postSnap = await FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: widget.uid).get();

      if (userSnap.exists) {
        userData = userSnap.data()!;
        postLen = postSnap.docs.length;
        followersLen = userSnap.data()?['followers'] != null ? (userSnap.data()!['followers'] as List).length : 0;
        followingLen = userSnap.data()?['following'] != null ? (userSnap.data()!['following'] as List).length : 0;
        isFollowing = (userSnap.data()?['followers'] as List?)?.contains(currentUserId) ?? false;
      }
    } catch (e) {
      debugPrint('Lỗi getData Profile: $e');
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSuggestedUsers() async {
    try {
      var snap = await FirebaseFirestore.instance.collection('users').limit(10).get();
      List<Map<String, dynamic>> users = [];
      for (var doc in snap.docs) {
        if (doc.id != currentUserId && doc.id != widget.uid) {
          var data = doc.data(); 
          data['uid'] = doc.id; 
          users.add(data);
        }
      }
      if (mounted) setState(() => _suggestedUsers = users);
    } catch (e) { debugPrint('Lỗi: $e'); }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: const Text('Cài đặt và quyền riêng tư', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.white),
                title: const Text('Bài viết đã thích', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LikedPostsScreen()));
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: Colors.white),
                title: const Text('Đã lưu', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPostsScreen()));
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text('Kho lưu trữ', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentUser = (widget.uid == currentUserId);

    return isLoading
        ? const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)))
        : DefaultTabController(
            length: 4, 
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: isCurrentUser
                    ? IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 26),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey[900],
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  leading: const Icon(Icons.auto_stories, color: Colors.white),
                                  title: const Text('Tạo tin', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(context); // Đóng bảng chọn
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddStoryScreen()),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.grid_on, color: Colors.white),
                                  title: const Text('Tạo bài viết', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(context); // Đóng bảng chọn
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddPostScreen()),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.video_collection_outlined, color: Colors.white),
                                  title: const Text('Tạo thước phim', style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    Navigator.pop(context); // Đóng bảng chọn
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddReelScreen()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const BackButton(color: Colors.white),
                title: Text(
                  userData['username'] ?? 'Tài khoản',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => _showSettingsMenu(context),
                  ),
                ],
              ),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TÊN HIỂN THỊ CĂN TRÊN THỐNG KÊ (BÊN PHẢI AVATAR)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('stories')
                                    .where('uid', isEqualTo: widget.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  bool hasStory = false;
                                  Map<String, dynamic>? storyData;

                                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                    hasStory = true;
                                    var doc = snapshot.data!.docs.first;
                                    storyData = Map<String, dynamic>.from(doc.data());
                                    storyData['storyId'] = doc.id; // Gắn ID để xử lý xóa tin nếu là chủ nhân
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (hasStory && snapshot.hasData) {
                                        // THAY ĐOẠN NÀY VÀO: Lấy toàn bộ danh sách docs từ snapshot của StreamBuilder
                                        var docs = snapshot.data!.docs;
                                        List<Map<String, dynamic>> listStories = docs.map((doc) {
                                          var data = Map<String, dynamic>.from(doc.data());
                                          data['storyId'] = doc.id;
                                          return data;
                                        }).toList();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StoryViewScreen(
                                              stories: listStories,
                                              initialIndex: 0,
                                            ),
                                          ),
                                        );
                                      } else if (isCurrentUser) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AddStoryScreen(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(hasStory ? 3.0 : 0.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: hasStory
                                            ? const LinearGradient(
                                                colors: [Color(0xFFfd1d1d), Color(0xFFfcb045), Color(0xFF833ab4)],
                                                begin: Alignment.topRight,
                                                end: Alignment.bottomLeft,
                                              )
                                            : null,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(hasStory ? 2.0 : 0.0),
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Stack(
                                          children: [
                                            CustomAvatar(radius: 40, avatarUrl: userData['photoUrl'] ?? ''),
                                            // Nếu là trang của mình và chưa có tin thì hiện dấu cộng nhỏ góc phải
                                            if (isCurrentUser && !hasStory)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF0095F6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData['name'] ?? userData['username'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildStatColumn(postLen, 'Bài viết'),
                                          _buildStatColumn(followersLen, 'Người theo dõi'),
                                          _buildStatColumn(followingLen, 'Đang theo dõi'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (userData['bio'] != null && userData['bio'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(userData['bio'].toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            
                            // NÚT CHỈNH SỬA / CHIA SẺ
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (isCurrentUser) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => getData());
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF262626),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      ),
                                      child: const Text(
                                        'Chỉnh sửa trang cá nhân',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF262626),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      ),
                                      child: const Text(
                                        'Chia sẻ trang cá nhân',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(8)),
                                    child: IconButton(
                                      icon: Icon(_showSuggestions ? Icons.person_add : Icons.person_add_outlined, color: Colors.white, size: 18),
                                      onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await UserMethods().followUser(currentUserId, widget.uid);
                                        setState(() {
                                          isFollowing = !isFollowing;
                                          isFollowing ? followersLen++ : followersLen--;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? const Color(0xFF262626) : const Color(0xFF0095F6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: Text(
                                        isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF262626),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: const Text(
                                        'Nhắn tin',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Gợi ý bạn bè (Mặc định hiển thị)
                            if (_showSuggestions && _suggestedUsers.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Khám phá mọi người', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DiscoverPeopleScreen()));
                                    },
                                    child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 170,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _suggestedUsers.length,
                                  itemBuilder: (context, index) {
                                    var user = _suggestedUsers[index];
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(uid: user['uid']))),
                                      child: Container(
                                        width: 130, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[900]!)),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CustomAvatar(radius: 28, avatarUrl: user['photoUrl'] ?? ''),
                                            const SizedBox(height: 8),
                                            Text(user['username'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity, height: 28,
                                              child: ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095F6), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                child: const Text('Theo dõi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ];
                },

                body: Column(
                  children: [
                    const TabBar(
                      indicatorColor: Colors.white,
                      indicatorWeight: 1,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on, size: 24)),
                        Tab(icon: Icon(Icons.movie_outlined, size: 26)),
                        Tab(icon: Icon(Icons.repeat, size: 26)),
                        Tab(icon: Icon(Icons.person_pin_outlined, size: 26)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: BÀI VIẾT GỐC
                          FutureBuilder(
                            future: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: widget.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                              var docs = (snapshot.data as dynamic)?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 36),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Tạo bài viết đầu tiên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      if (isCurrentUser)
                                        TextButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen())),
                                          child: const Text('Chia sẻ ảnh đầu tiên', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true, itemCount: docs.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1),
                                itemBuilder: (context, index) => Image.network(docs[index]['postUrl'], fit: BoxFit.cover),
                              );
                            },
                          ),

                          // TAB 2: REELS / THƯỚC PHIM (ĐÃ BỔ SUNG NÚT TẠO THƯỚC PHIM)
                          FutureBuilder(
                            future: FirebaseFirestore.instance.collection('reels').where('uid', isEqualTo: widget.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                              var docs = (snapshot.data as dynamic)?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        child: const Icon(Icons.movie_outlined, color: Colors.white, size: 36),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Chưa có thước phim nào', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      if (isCurrentUser)
                                        TextButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReelScreen())),
                                          child: const Text('Tạo thước phim', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true, itemCount: docs.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1),
                                itemBuilder: (context, index) {
                                  var snap = docs[index];
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(snap['thumbnailUrl'] ?? snap['postUrl'], fit: BoxFit.cover),
                                      Positioned(
                                        bottom: 5, left: 5,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                            Text(' ${snap.data().toString().contains('views') ? snap['views'] : 0}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          // TAB 3: BÀI ĐĂNG LẠI
                          FutureBuilder(
                            future: FirebaseFirestore.instance.collection('posts').where('repostedBy', arrayContains: widget.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                              var docs = (snapshot.data as dynamic)?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        child: const Icon(Icons.repeat, color: Colors.white, size: 36),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Chưa có bài đăng lại nào', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 6),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 32),
                                        child: Text('Khi bạn đăng lại bài viết, bài viết đó sẽ xuất hiện ở đây.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true, itemCount: docs.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1),
                                itemBuilder: (context, index) {
                                  var snap = docs[index];
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(snap['postUrl'], fit: BoxFit.cover),
                                      const Positioned(top: 5, right: 5, child: Icon(Icons.repeat, color: Colors.white, size: 16)),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          // TAB 4: ĐƯỢC GẮN THẺ
                          FutureBuilder(
                            future: FirebaseFirestore.instance.collection('posts').where('taggedUsers', arrayContains: widget.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                              var docs = (snapshot.data as dynamic)?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                        child: const Icon(Icons.person_pin_outlined, color: Colors.white, size: 36),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Ảnh và video có mặt bạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 6),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 32),
                                        child: Text('Khi mọi người gắn thẻ bạn trong ảnh và video, những file đó sẽ xuất hiện ở đây.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true, itemCount: docs.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1),
                                itemBuilder: (context, index) => Image.network(docs[index]['postUrl'], fit: BoxFit.cover),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Column _buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(num.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Container(margin: const EdgeInsets.only(top: 4), child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white))),
      ],
    );
  }
}