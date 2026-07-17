import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/screens/login_screen.dart';
import 'package:instagram_clone/widgets/post_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex = 0;
  bool _isLoadingStory = false;

  String _currentUsername = 'User';
  String _currentUserAvatar = 'assets/images/default_avatar.png';

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
  }

  void _getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUsername = userDoc.get('username') ?? 'User';
            _currentUserAvatar = userDoc.get('photoUrl') ?? _currentUserAvatar;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy thông tin user: $e');
    }
  }

  void _uploadStory() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoadingStory = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        String fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(
          'stories/$fileName',
        );

        String downloadUrl = '';

        // Kiểm tra nếu chạy trên Web thì upload bằng bytes, trên Mobile thì dùng File bình thường hoặc bytes luôn cũng được
        if (kIsWeb) {
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          UploadTask uploadTask = storageRef.putData(
            imageBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          TaskSnapshot snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        } else {
          // Nếu chạy trên Mobile, bạn có thể dùng readAsBytes() tương tự hoặc giữ putFile nhưng phải import 'dart:io' đúng cách.
          // Cách tốt nhất và đồng bộ nhất cho cả 2 là dùng luôn readAsBytes():
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          UploadTask uploadTask = storageRef.putData(imageBytes);
          TaskSnapshot snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }

        await FirebaseFirestore.instance.collection('stories').add({
          'uid': user.uid,
          'username': _currentUsername,
          'avatar': _currentUserAvatar,
          'storyUrl': downloadUrl,
          'timeCreated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng story thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi đăng story: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingStory = false;
          });
        }
      }
    }
  }

  void _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'swe.vn',
      'isVerified': true,
      'userHeaderImage':
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
      'postUrl':
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=800',
      'likes': 1240,
      'description':
          'Mẫu áo thun phiên bản giới hạn dưới nước vừa ra mắt ngày hôm nay.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Text(
              'Instagram',
              style: TextStyle(
                fontFamily: 'Oriel',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOutUser,
          ),
        ],
      ),
      body: _pageIndex == 0
          ? RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      height: 110,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF1C1C1E),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Phần nút thêm Story của chính user hiện tại
                          GestureDetector(
                            onTap: _isLoadingStory ? null : _uploadStory,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.black,
                                          child: CircleAvatar(
                                            radius: 27,
                                            backgroundColor: Colors.grey[800],
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(27),
                                              child: Image.network(
                                                _currentUserAvatar,
                                                width: 54,
                                                height: 54,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Image.asset(
                                                        'assets/images/default_avatar.png',
                                                        width: 54,
                                                        height: 54,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.blue,
                                          child: _isLoadingStory
                                              ? const Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tin của bạn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Container(
                            width: 0.5,
                            height: 60,
                            color: Colors.grey.withOpacity(0.2),
                          ),

                          // Phần danh sách Story của người khác (Đã sửa để bọc cố định chiều cao và tối ưu stream)
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('stories')
                                  .orderBy('timeCreated', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }

                                final allStories = snapshot.data?.docs ?? [];
                                final otherStories = allStories.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return data['uid'] != currentUserId;
                                }).toList();

                                if (otherStories.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Chưa có tin nổi bật',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics:
                                      const BouncingScrollPhysics(), // Giúp cuộn mượt hơn
                                  itemCount: otherStories.length,
                                  itemBuilder: (context, sIndex) {
                                    final story =
                                        otherStories[sIndex].data()
                                            as Map<String, dynamic>;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.purple,
                                                  Colors.orange,
                                                  Colors.yellow,
                                                ],
                                                begin: Alignment.topRight,
                                                end: Alignment.bottomLeft,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Colors.black,
                                              child: CircleAvatar(
                                                radius: 27,
                                                backgroundColor:
                                                    Colors.grey[800],
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(27),
                                                  child: Image.network(
                                                    story['avatar'] ??
                                                        'https://placeholder.co/150',
                                                    width: 54,
                                                    height: 54,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Image.network(
                                                            'https://placeholder.co/150',
                                                            width: 54,
                                                            height: 54,
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              story['username'] ?? 'User',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              key: ValueKey(
                                                otherStories[sIndex].id,
                                              ), // Định danh tránh re-render nhầm widget
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return PostCard(snap: _posts[index - 1]);
                },
              ),
            )
          : Center(
              child: Text(
                'Màn hình chức năng số $_pageIndex',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _pageIndex,
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection_outlined),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
