import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../resources/user_methods.dart';
import 'add_post_screen.dart';
import 'add_reel_screen.dart';
import 'chat_list_screen.dart';
import 'edit_profile_screen.dart';
import 'liked_posts_screen.dart';
import 'login_screen.dart';
import 'saved_posts_screen.dart';
import '../widgets/custom_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final String uid; 
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  bool isLoading = true;
  bool isFollowing = false;
  bool _showSuggestions = true; // Biến trạng thái ẩn/hiện danh sách gợi ý kết bạn
  List<Map<String, dynamic>> _suggestedUsers = []; // Danh sách gộp chung thật từ DB và mock
  
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    getData();
    fetchSuggestedUsers();
  }

  getData() async {
    print('=== Đang tải profile của UID: ${widget.uid} ===');
    setState(() => isLoading = true);
    try {
      var userSnap = await UserMethods().getUserDetails(widget.uid);
      print('=== Đã lấy xong user details ===');
      
      if (!mounted) return;
      if (userSnap.exists && userSnap.data() != null) {
        userData = userSnap.data()! as Map<String, dynamic>;
      }

      print('=== Đang gọi Firestore kiểm tra followers... ===');
      
      // Thêm timeout 4 giây để chống đứng app nếu kết nối bị kẹt
      var followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('followers')
          .doc(currentUserId)
          .get()
          .timeout(const Duration(seconds: 4), onTimeout: () {
            print('=== Quá thời gian (Timeout) lấy followers! ===');
            throw Exception('Timeout connection');
          });
      
      print('=== Đã lấy xong followers! ===');
      if (!mounted) return;
      isFollowing = followingSnap.exists;
    } catch (e) {
      print('=== LỖI TRONG getData: $e ===');
    }
    
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // Lấy người dùng thật từ DB gộp chung với mock users
  Future<void> fetchSuggestedUsers() async {
    // Danh sách mock dự phòng luôn có sẵn
    List<Map<String, dynamic>> mockUsers = [
      {
        'name': 'Kim Ngân',
        'subtitle': 'Gợi ý cho bạn',
        'avatar': 'https://i.pravatar.cc/150?img=40',
      },
      {
        'name': 'Kiên Thiều',
        'subtitle': '36 người theo dõi chung',
        'avatar': 'https://i.pravatar.cc/150?img=45',
      },
      {
        'name': 'Tín LoveTrg',
        'subtitle': '3 người theo dõi chung',
        'avatar': 'https://i.pravatar.cc/150?img=48',
      },
    ];

    try {
      var userSnap = await FirebaseFirestore.instance.collection('users').get();
      print('=== Số lượng document trong users: ${userSnap.docs.length} ===');

      List<Map<String, dynamic>> realUsers = userSnap.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
            var data = doc.data();
            return {
              'name': data['username'] ?? 'User',
              'subtitle': 'Gợi ý cho bạn',
              'avatar': data['photoUrl'] ?? 'https://i.pravatar.cc/150?img=1',
              'uid': doc.id,
            };
          }).toList();

      if (mounted) {
        setState(() {
          _suggestedUsers = [...realUsers, ...mockUsers];
        });
      }
    } catch (e) {
      print('=== Lỗi tải danh sách gợi ý từ DB: $e ===');
      if (mounted) {
        setState(() {
          _suggestedUsers = mockUsers;
        });
      }
    }
  }

  // ===== HÀM HIỂN THỊ MENU SỬA/XÓA BÀI VIẾT (KHI NHẤN GIỮ BÀI VIẾT) =====
  void _showActionDialog(BuildContext context, String docId, String type, String currentDesc) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Tùy chọn', style: TextStyle(color: Colors.white)),
          children: [
            if (type == 'post') // Chỉ hỗ trợ sửa nội dung (description) cho Bài viết
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Chỉnh sửa bài viết', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditDialog(context, docId, currentDesc);
                },
              ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(type == 'post' ? 'posts' : 'reels')
                    .doc(docId)
                    .delete();
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa thành công!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ===== HÀM HIỂN THỊ HỘP THOẠI CHỈNH SỬA BÀI VIẾT =====
  void _showEditDialog(BuildContext context, String docId, String currentDesc) {
    TextEditingController descController = TextEditingController(text: currentDesc);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Chỉnh sửa bài viết', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: descController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Nhập nội dung mới...",
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('posts').doc(docId).update({
                  'description': descController.text,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMyProfile = currentUserId == widget.uid;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(userData['username'] ?? '', style: const TextStyle(color: Colors.white)),
              actions: [
                if (isMyProfile)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    color: Colors.grey[900], 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (String value) async {
                      switch (value) {
                        case 'create_post':
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen()));
                          break;
                        case 'create_reel':
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReelScreen()));
                          break;
                        case 'saved_posts':
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPostsScreen()));
                          break;
                        case 'liked_posts':
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LikedPostsScreen()));
                          break;
                        case 'chat_list':
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen()));
                          break;
                        case 'logout':
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      // --- Nút Tạo bài viết ---
                      const PopupMenuItem<String>(
                        value: 'create_post',
                        child: Row(
                          children: [
                            Icon(Icons.add_box_outlined, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Tạo bài viết', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      // --- Nút Tạo Reel ---
                      const PopupMenuItem<String>(
                        value: 'create_reel',
                        child: Row(
                          children: [
                            Icon(Icons.video_call_outlined, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Tạo Reel', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem<String>(
                        value: 'saved_posts',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Bài viết đã lưu', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'liked_posts',
                        child: Row(
                          children: [
                            Icon(Icons.favorite_border, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Bài viết đã tim', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'chat_list',
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Tin nhắn', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent),
                            SizedBox(width: 12),
                            Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: DefaultTabController(
              length: 2, 
              child: NestedScrollView(
                headerSliverBuilder: (context, _) {
                  return [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {},
                                    child: CustomAvatar(
                                      avatarUrl: userData['photoUrl'], 
                                      username: userData['username'] ?? 'My Profile',
                                      radius: 40,
                                    )
                                  ),
                                  _buildStatColumn(userData['followersCount'] ?? 0, "Người theo dõi"),
                                  _buildStatColumn(userData['followingCount'] ?? 0, "Đang theo dõi"),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(userData['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(userData['bio'] ?? '', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: isMyProfile
                                        ? ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                              );
                                            },
                                            child: const Text('Chỉnh sửa trang cá nhân', style: TextStyle(color: Colors.white)),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey[900] : Colors.blue),
                                            onPressed: () async {
                                              await UserMethods().followUser(widget.uid, currentUserId);
                                              setState(() {
                                                isFollowing = !isFollowing;
                                                userData['followersCount'] += isFollowing ? 1 : -1;
                                              });
                                            },
                                            child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi', style: const TextStyle(color: Colors.white)),
                                          ),
                                  ),
                                  if (isMyProfile) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(4)),
                                      child: IconButton(
                                        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _showSuggestions = !_showSuggestions; // Bấm vào để ẩn/hiện danh sách gợi ý
                                          });
                                        },
                                      ),
                                    )
                                  ]
                                ],
                              ),
                              
                              // ==========================================
                              // PHẦN GỢI Ý KẾT BẠN "KHÁM PHÁ MỌI NGƯỜI"
                              // ==========================================
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Khám phá mọi người',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text(
                                            'Xem tất cả',
                                            style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 210,
                                      child: _suggestedUsers.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'Không có gợi ý nào',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _suggestedUsers.length,
                                              itemBuilder: (context, index) {
                                                final user = _suggestedUsers[index];

                                                return Container(
                                                  width: 150,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1E1E1E),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 36,
                                                            backgroundImage: NetworkImage(user['avatar'] ?? ''),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            user['name'] ?? '',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            user['subtitle'] ?? '',
                                                            style: TextStyle(
                                                              color: Colors.grey[400],
                                                              fontSize: 11,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 10),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 32,
                                                            child: ElevatedButton(
                                                              onPressed: () {},
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.blueAccent,
                                                                foregroundColor: Colors.white,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                padding: EdgeInsets.zero,
                                                              ),
                                                              child: const Text(
                                                                'Theo dõi',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Positioned(
                                                        top: 0,
                                                        right: 0,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _suggestedUsers.removeAt(index);
                                                            });
                                                          },
                                                          child: Icon(
                                                            Icons.close,
                                                            size: 16,
                                                            color: Colors.grey[400],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                                crossFadeState: _showSuggestions
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 300),
                              ),
                            ],
                          ),
                        ),
                        const TabBar(
                          indicatorColor: Colors.white,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on, color: Colors.white)),
                            Tab(icon: Icon(Icons.video_collection_outlined, color: Colors.white)),
                          ],
                        ),
                      ]),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    // ==========================================
                    // TAB 1: BÀI VIẾT (POSTS)
                    // ==========================================
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('posts')
                          .where('uid', isEqualTo: widget.uid)
                          .orderBy('datePublished', descending: true)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }

                        if (!snapshot.hasData || (snapshot.data! as QuerySnapshot).docs.isEmpty) {
                          return Center(
                            child: isMyProfile
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen()));
                                    },
                                    child: const Text('Tạo bài viết mới', style: TextStyle(color: Colors.white)),
                                  )
                                : const Text('Chưa có bài viết nào', style: TextStyle(color: Colors.white)),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          itemCount: (snapshot.data! as QuerySnapshot).docs.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            DocumentSnapshot snap = (snapshot.data! as QuerySnapshot).docs[index];
                            return GestureDetector(
                              onLongPress: () {
                                if (isMyProfile) {
                                  // NHẤN GIỮ BÀI VIẾT ĐỂ HIỆN SỬA/XÓA
                                  _showActionDialog(context, snap['postId'], 'post', snap['description'] ?? '');
                                }
                              },
                              child: Image.network(
                                snap['postUrl'],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // ==========================================
                    // TAB 2: VIDEO NGẮN (REELS)
                    // ==========================================
                    FutureBuilder(
                      // Gọi collection 'reels' của user này
                      future: FirebaseFirestore.instance
                          .collection('reels') 
                          .where('uid', isEqualTo: widget.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        
                        if (!snapshot.hasData || (snapshot.data! as dynamic).docs.isEmpty) {
                          return const Center(
                            child: Text('Chưa có thước phim nào', style: TextStyle(color: Colors.white)),
                          );
                        }

                        return GridView.builder(
                          itemCount: (snapshot.data! as dynamic).docs.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          // Nhỏ hơn 600px (Điện thoại) thì 3 cột, bự hơn (Tablet/Web) thì 5 hoặc 6 cột
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3, 
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1, // Đảm bảo ảnh luôn vuông vức
                        ),
                          itemBuilder: (context, index) {
                            DocumentSnapshot snap = (snapshot.data! as dynamic).docs[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 30),
                                  ),
                                ),// Icon lượt xem (tùy chọn)
                                Positioned(
                                  bottom: 5,
                                  left: 5,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                      Text(
                                        ' ${snap.data().toString().contains('views') ? snap['views'] : 0}', 
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        );
                      },
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
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }
}