import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/resources/posts_methods.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'TKCT', 
          // Dùng font Grand Hotel để fake font Billabong của Instagram gốc
          style: GoogleFonts.grandHotel(
            color: Colors.white, 
            fontSize: 36, 
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () {}),
        ],
      ),
      // KÉO DỮ LIỆU THẬT TỪ FIRESTORE
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('datePublished', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // XỬ LÝ KHI KHÔNG TÌM THẤY DỮ LIỆU
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài viết nào.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length + 1,
            itemBuilder: (context, index) {
              // Vị trí đầu tiên dành cho Story
              if (index == 0) {
                return _buildStoryBar();
              }
              
              // Map dữ liệu bài đăng (trừ đi 1 do index 0 là story)
              var post = snapshot.data!.docs[index - 1].data();
              return _buildPostItem(context, post);
            },
          );
        },
      ),
    );
  }

  // Khung giao diện thanh Story tạm thời
  Widget _buildStoryBar() {
    return Container(
      height: 105,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.orange],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  index == 0 ? 'Tin của bạn' : 'User $index',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Khung giao diện Bài đăng kết nối dữ liệu thật
  Widget _buildPostItem(BuildContext context, Map<String, dynamic> post) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likes = post['likes'] as List;
    final bool isLiked = likes.contains(currentUserUid);
    final String postId = post['postId'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header (Avatar + Tên)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(post['profImage']),
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // Sửa lỗi widget.snap thành post
                  final isMyPost = post['uid'] == FirebaseAuth.instance.currentUser!.uid;
                  
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Tùy chọn', style: TextStyle(color: Colors.white)),
                      children: [
                        if (isMyPost) // Nếu là bài của mình thì mới hiện Sửa/Xóa
                          SimpleDialogOption(
                            padding: const EdgeInsets.all(20),
                            child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.pop(context); // Đóng menu
                              
                              // Sửa _descController thành descController và dùng post['description']
                              TextEditingController descController = TextEditingController(text: post['description']);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text('Sửa bài viết', style: TextStyle(color: Colors.white)),
                                  content: TextField(
                                    controller: descController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(hintText: 'Nhập nội dung...', hintStyle: TextStyle(color: Colors.grey)),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                    TextButton(
                                      onPressed: () async {
                                        // Sử dụng biến postId đã khai báo ở trên
                                        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                                          'description': descController.text,
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      }, 
                                      child: const Text('Lưu')
                                    ),
                                  ],
                                )
                              );
                            },
                          ),
                        if (isMyPost)
                          SimpleDialogOption(
                            padding: const EdgeInsets.all(20),
                            child: const Text('Xóa bài viết', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              // Sử dụng biến postId đã khai báo
                              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        if (!isMyPost) // Nếu là bài của người khác thì hiện Báo cáo
                          SimpleDialogOption(
                            padding: const EdgeInsets.all(20),
                            child: const Text('Báo cáo bài viết', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),
        
        // 2. Ảnh bài đăng (Double tap để thả tim nhanh)
        GestureDetector(
          onDoubleTap: () async {
            await PostsMethods().likePost(postId, currentUserUid, likes);
          },
          child: SizedBox(
            height: 400,
            width: double.infinity,
            child: Image.network(
              post['postUrl'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.grey),
            ),
          ),
        ),

        // 3. Thanh tương tác
        Row(
          children: [
            // Nút Tim
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
              onPressed: () async {
                await PostsMethods().likePost(postId, currentUserUid, likes);
              },
            ),
            // Nút Bình luận
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () => _showCommentsBottomSheet(context, postId),
            ),
            // Nút Chia sẻ
            IconButton(
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết chia sẻ bài viết!')),
                );
              },
            ),
            const Spacer(),
            // Nút Lưu bài viết (Bookmark)
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.white),
              onPressed: () async {
                await PostsMethods().savePost(currentUserUid, postId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật bộ sưu tập!')),
                  );
                }
              },
            ),
          ],
        ),

        // 4. Số lượt thích & Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${likes.length} lượt thích',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: '${post['username']} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post['description']),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Nhấn vào đây cũng mở được phần bình luận
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context, postId),
                child: const Text(
                  'Xem tất cả bình luận',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Hàm hiển thị BottomSheet Bình luận
  void _showCommentsBottomSheet(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'Bình luận',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(color: Colors.grey),
                // Danh sách bình luận theo thời gian thực
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('datePublished', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Chưa có bình luận nào.', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var comment = snapshot.data!.docs[index].data();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(comment['profilePic'] ?? ''),
                            ),
                            title: Text(comment['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(comment['text'], style: const TextStyle(color: Colors.white70)),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Ô nhập bình luận
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Thêm bình luận...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () async {
                        if (commentController.text.trim().isNotEmpty) {
                          final userSnap = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get();
                          final userData = userSnap.data() as Map<String, dynamic>;

                          await PostsMethods().postComment(
                            postId,
                            commentController.text.trim(),
                            FirebaseAuth.instance.currentUser!.uid,
                            userData['username'] ?? 'User',
                            userData['photoUrl'] ?? '',
                          );
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}