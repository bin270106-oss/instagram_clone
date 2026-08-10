import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_avatar.dart';
import 'chat_detail_screen.dart';
import 'create_group_chat_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tin nhắn mới',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ô TÌM KIẾM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    hintText: 'Tìm kiếm',
                    hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _query = val.toLowerCase().trim()),
                ),
              ),
            ),

            // NÚT TẠO CHAT NHÓM (HÌNH 6) - BỎ AI THEO YÊU CẦU
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF262626), shape: BoxShape.circle),
                child: const Icon(Icons.group_add_outlined, color: Colors.white, size: 22),
              ),
              title: Text(
                'Tạo chat nhóm',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onTap: () {
                // CHUYỂN SANG HÌNH 6: TẠO NHÓM CHAT
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateGroupChatScreen()),
                );
              },
            ),

            const Divider(color: Colors.white12),

            // DANH SÁCH BẠN BÈ REALTIME FIRESTORE
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  var users = snapshot.data?.docs.where((doc) => doc.id != _currentUid).toList() ?? [];

                  if (_query.isNotEmpty) {
                    users = users.where((doc) {
                      String name = (doc.data()['username'] ?? '').toString().toLowerCase();
                      return name.contains(_query);
                    }).toList();
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var uData = users[index].data();
                      String peerUid = users[index].id;

                      return ListTile(
                        leading: CustomAvatar(radius: 22, avatarUrl: uData['photoUrl'] ?? ''),
                        title: Text(
                          uData['name'] ?? uData['username'] ?? 'User',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '@${uData['username'] ?? ''}',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                receiverUserUid: peerUid,
                                receiverUsername: uData['username'] ?? 'User',
                                receiverProfileImg: uData['photoUrl'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}