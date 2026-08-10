import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../resources/chat_methods.dart';
import '../widgets/custom_avatar.dart';
import 'profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverUserUid;
  final String receiverUsername;
  final String receiverProfileImg;

  const ChatDetailScreen({
    super.key,
    required this.receiverUserUid,
    required this.receiverUsername,
    required this.receiverProfileImg,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  Map<String, dynamic> _receiverData = {};
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchReceiverInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Tải thông tin chi tiết người nhận từ Firestore
  Future<void> _fetchReceiverInfo() async {
    try {
      var snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUserUid)
          .get();
      if (snap.exists && mounted) {
        setState(() {
          _receiverData = snap.data() ?? {};
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  // Tạo Chat Room ID duy nhất cho 2 người
  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // Gửi tin nhắn
  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final String chatRoomId = _getChatRoomId(_currentUid, widget.receiverUserUid);

    await ChatMethods().sendMessage(
      senderId: _currentUid,
      receiverId: widget.receiverUserUid,
      text: text,
      chatRoomId: chatRoomId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String chatRoomId = _getChatRoomId(_currentUid, widget.receiverUserUid);
    final String displayName = _receiverData['name'] ?? widget.receiverUsername;
    final String avatarUrl = _receiverData['photoUrl'] ?? widget.receiverProfileImg;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(uid: widget.receiverUserUid),
              ),
            );
          },
          child: Row(
            children: [
              CustomAvatar(radius: 16, avatarUrl: avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${widget.receiverUsername}',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // CỤM NÚT GỌI THƯỜNG & GỌI VIDEO (BỎ NÚT THỪA)
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng gọi thoại')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng gọi video')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // NỘI DUNG CHAT + ĐẦU TRANG CÁ NHÂN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true, // Cuộn từ dưới lên
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length + 1, // +1 cho Header đầu đoạn chat
                  itemBuilder: (context, index) {
                    // PHẦN HEADER THÔNG TIN NGƯỜI DÙNG Ở ĐẦU TRANG CHAT
                    if (index == docs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            CustomAvatar(radius: 42, avatarUrl: avatarUrl),
                            const SizedBox(height: 12),
                            Text(
                              displayName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.receiverUsername} • Instagram',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(uid: widget.receiverUserUid),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF262626),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                'Xem trang cá nhân',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // DANH SÁCH BONG BÓNG TIN NHẮN REALTIME
                    var msgData = docs[index].data() as Map<String, dynamic>;
                    bool isMe = msgData['senderId'] == _currentUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF3797EF) : const Color(0xFF262626),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                        ),
                        child: Text(
                          msgData['text'] ?? '',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // KHUNG NHẬP TIN NHẮN ĐÁY MÀN HÌNH
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    // NÚT CAMERA XANH TRÒN
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng chụp ảnh chat')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3797EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ô NHẬP VĂN BẢN
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhắn tin...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (val) => setState(() {}),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),

                    // NÚT GỬI HOẶC CÁC ICON TƯƠNG TÁC
                    if (_messageController.text.trim().isNotEmpty)
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Gửi',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3797EF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.mic_none, color: Colors.white, size: 22),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: Colors.white, size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}