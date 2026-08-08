import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/resources/posts_methods.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Xử lý an toàn cho likes (phòng trường hợp dữ liệu cũ là int hoặc null)
    List likes = [];
    if (widget.snap['likes'] is List) {
      likes = widget.snap['likes'];
    }
    final bool isLiked = likes.contains(currentUserUid);
    final String postId = widget.snap['postId'] ?? '';
    final bool isMyPost = widget.snap['uid'] == currentUserUid;

    return Container(
      color: Colors.black, // Nền đen chuẩn Dark Mode
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar + Tên User + Nút More (3 chấm)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(right: 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    widget.snap['profImage'] ?? 'https://images.unsplash.com/photo-1682687220742-aba13b6e50ba',
                  ), 
                  backgroundColor: Colors.grey,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      widget.snap['username'] ?? 'username',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Tùy chọn', style: TextStyle(color: Colors.white)),
                        children: [
                          if (isMyPost)
                            SimpleDialogOption(
                              padding: const EdgeInsets.all(20),
                              child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                Navigator.pop(context);
                                TextEditingController descController = TextEditingController(text: widget.snap['description']);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text('Sửa bài viết', style: TextStyle(color: Colors.white)),
                                    content: TextField(
                                      controller: descController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        hintText: 'Nhập nội dung...', 
                                        hintStyle: TextStyle(color: Colors.grey)
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                      TextButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                                            'description': descController.text,
                                          });
                                          if (context.mounted) Navigator.pop(context);
                                        }, 
                                        child: const Text('Lưu')
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          if (isMyPost)
                            SimpleDialogOption(
                              padding: const EdgeInsets.all(20),
                              child: const Text('Xóa bài viết', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          if (!isMyPost)
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
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                )
              ],
            ),
          ),

          // 2. Image: Khung ảnh bài đăng (Hỗ trợ Double Tap thả tim)
          GestureDetector(
            onDoubleTap: () async {
              await PostsMethods().likePost(postId, currentUserUid, likes);
            },
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: Image.network(
                widget.snap['postUrl'] ?? 'https://images.unsplash.com/photo-1682687220742-aba13b6e50ba', 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.grey),
              ),
            ),
          ),

          // 3. Actions: Dải nút Tim, Comment, Share, Save
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await PostsMethods().likePost(postId, currentUserUid, likes);
                },
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: () => _showCommentsBottomSheet(context, postId),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép liên kết chia sẻ bài viết!')),
                  );
                },
                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 26),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await PostsMethods().savePost(currentUserUid, postId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật bộ sưu tập!')),
                    );
                  }
                },
                icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
              ),
            ],
          ),

          // 4. Details: Lượt like, Caption, Xem bình luận
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${likes.length} lượt thích',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '${widget.snap['username'] ?? 'username'} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.snap['description'] ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showCommentsBottomSheet(context, postId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Xem tất cả bình luận',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'Vừa xong', 
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm mở BottomSheet bình luận tương tự FeedView
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