import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/resources/posts_methods.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Bài viết đã lưu', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: PostsMethods().getSavedPosts(currentUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài viết nào được lưu.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final savedPosts = snapshot.data!;

          // Hiển thị dạng lưới (Grid View) 3 cột giống Instagram
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // Nhỏ hơn 600px (Điện thoại) thì 3 cột, bự hơn (Tablet/Web) thì 5 hoặc 6 cột
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3, 
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1, // Đảm bảo ảnh luôn vuông vức
          ),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final post = savedPosts[index];
              return Image.network(
                post['postUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey, child: const Icon(Icons.error)),
              );
            },
          );
        },
      ),
    );
  }
}