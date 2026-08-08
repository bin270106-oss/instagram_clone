import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LikedPostsScreen extends StatelessWidget {
  const LikedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Bài viết đã tim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'Chưa đăng nhập',
                style: TextStyle(color: Colors.white),
              ),
            )
          : FutureBuilder(
              // Tìm các bài viết trong collection 'posts' có chứa UID của user trong mảng 'likes'
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .where('likes', arrayContains: currentUserId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // Nếu không có bài viết nào
                if (!snapshot.hasData ||
                    (snapshot.data! as QuerySnapshot).docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có bài viết nào được tim',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // Hiển thị lưới 3 cột bài viết đã tim
                return GridView.builder(
                  itemCount: (snapshot.data! as QuerySnapshot).docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    DocumentSnapshot snap =
                        (snapshot.data! as QuerySnapshot).docs[index];
                    return Image.network(
                      snap['postUrl'],
                      fit: BoxFit.cover,
                    );
                  },
                );
              },
            ),
    );
  }
}