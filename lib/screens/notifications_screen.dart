import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import '../widgets/custom_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Tính thời gian trôi qua (vd: 5ph, 2g, 3 ngày)
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime time = timestamp.toDate();
    Duration diff = DateTime.now().difference(time);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}ph';
    if (diff.inHours < 24) return '${diff.inHours}g';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông báo',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
      ),
      // BẮT ĐẦU KÉO DỮ LIỆU THẬT BẰNG STREAMBUILDER
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUid)
            .collection('notifications')
            .orderBy('time', descending: true) // Mới nhất lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Chưa có thông báo nào.',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var nData = notifications[index].data() as Map<String, dynamic>;

              // FUTUREBUILDER ĐỂ LẤY THÔNG TIN NGƯỜI GỬI THÔNG BÁO (Avatar, Tên)
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(nData['fromUid']).get(),
                builder: (context, uSnap) {
                  if (!uSnap.hasData) return const SizedBox.shrink(); // Đang load thì ẩn

                  var userData = uSnap.data!.data() as Map<String, dynamic>?;
                  if (userData == null) return const SizedBox.shrink();

                  String username = userData['username'] ?? 'User';
                  String photoUrl = userData['photoUrl'] ?? '';

                  // NẾU CÓ POST ID, LOAD THÊM ẢNH BÀI VIẾT
                  if (nData['postId'] != null && nData['postId'].toString().isNotEmpty) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('posts').doc(nData['postId']).get(),
                      builder: (context, pSnap) {
                        String postUrl = '';
                        if (pSnap.hasData && pSnap.data?.data() != null) {
                          postUrl = (pSnap.data!.data() as Map<String, dynamic>)['postUrl'] ?? '';
                        }
                        return _buildItem(nData, username, photoUrl, postUrl);
                      },
                    );
                  }

                  // NẾU KHÔNG CÓ POST (vd: Lượt Follow)
                  return _buildItem(nData, username, photoUrl, '');
                },
              );
            },
          );
        },
      ),
    );
  }

  // WIDGET UI TỪNG DÒNG THÔNG BÁO
  Widget _buildItem(Map<String, dynamic> nData, String username, String photoUrl, String postUrl) {
    String type = nData['type'] ?? '';
    String text = '';
    String? commentText;

    if (type == 'like_post') {
      text = 'đã thích ảnh của bạn.';
    } else if (type == 'comment_post') {
      text = 'đã bình luận vào ảnh của bạn:';
      commentText = '“${nData['commentText']}”'; 
    } else if (type == 'follow') {
      text = 'đã bắt đầu theo dõi bạn.';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CustomAvatar(radius: 22, avatarUrl: photoUrl),
      title: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          children: [
            TextSpan(text: '$username ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '$text '),
            if (commentText != null) TextSpan(text: '$commentText '),
            TextSpan(
              text: _getTimeAgo(nData['time']), 
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      trailing: _buildTrailing(type, postUrl),
      onTap: () {
        // Có thể code thêm: bấm vào bay sang bài viết hoặc trang cá nhân người đó
      },
    );
  }

  // WIDGET BÊN PHẢI (ẢNH BÀI ĐĂNG HOẶC NÚT THEO DÕI)
  Widget _buildTrailing(String type, String postUrl) {
    if ((type == 'like_post' || type == 'comment_post') && postUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.grey[900]),
        child: Image.network(postUrl, fit: BoxFit.cover),
      );
    } else if (type == 'follow') {
      return ElevatedButton(
        onPressed: () {}, // Nút tượng trưng
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0095F6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(0, 32),
        ),
        child: const Text('Theo dõi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }
    return const SizedBox.shrink();
  }
}