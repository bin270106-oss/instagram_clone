import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_avatar.dart';
import 'chat_detail_screen.dart';
import 'create_note_screen.dart';
import 'message_requests_screen.dart';
import 'new_message_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm tạo ID phòng chat để lấy tin nhắn gần nhất
  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // BỎ MŨI TÊN QUAY LẠI
        centerTitle: true, // TÊN NGƯỜI DÙNG Ở CHÍNH GIỮA
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(_currentUid).get(),
          builder: (context, snapshot) {
            String username = 'Tin nhắn';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              username = data['username'] ?? 'Tin nhắn';
            }
            return Row(
              mainAxisSize: MainAxisSize.min, // Giữ cụm text ở giữa
              children: [
                Text(
                  username,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewMessageScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // THANH TÌM KIẾM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // THANH GHI CHÚ
                    _buildNotesBar(),

                    // ĐÃ LÀM KHÍT LẠI (GIẢM SIZEDBOX VÀ PADDING)
                    const SizedBox(height: 0),

                    // TIÊU ĐỀ "TIN NHẮN" VÀ "YÊU CẦU"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tin nhắn',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MessageRequestsScreen()),
                              );
                            },
                            child: Text(
                              'Yêu cầu',
                              style: GoogleFonts.inter(color: const Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // DANH SÁCH CÁC CUỘC TRÒ CHUYỆN
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          );
                        }

                        var users = snapshot.data?.docs.where((doc) => doc.id != _currentUid).toList() ?? [];

                        if (_searchQuery.isNotEmpty) {
                          users = users.where((doc) {
                            String name = (doc.data()['username'] ?? '').toString().toLowerCase();
                            return name.contains(_searchQuery);
                          }).toList();
                        }

                        if (users.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('Không tìm thấy cuộc trò chuyện nào', style: GoogleFonts.inter(color: Colors.grey)),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var uData = users[index].data();
                            String peerUid = users[index].id;
                            String chatRoomId = _getChatRoomId(_currentUid, peerUid);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: CustomAvatar(radius: 26, avatarUrl: uData['photoUrl'] ?? ''),
                              title: Text(
                                uData['name'] ?? uData['username'] ?? 'User',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              // HIỂN THỊ TIN NHẮN GẦN NHẤT REAL-TIME
                              subtitle: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).snapshots(),
                                builder: (context, chatSnap) {
                                  String lastMsg = 'Nhấn để bắt đầu trò chuyện';
                                  if (chatSnap.hasData && chatSnap.data!.exists) {
                                    var chatData = chatSnap.data!.data() as Map<String, dynamic>;
                                    lastMsg = chatData['lastMessage'] ?? lastMsg;
                                  }
                                  return Text(
                                    lastMsg,
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              trailing: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 22),
                              onTap: () {
                                Navigator.push(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET DỰNG THANH GHI CHÚ (NOTES)
  Widget _buildNotesBar() {
    return SizedBox(
      height: 115,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('notes').snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> myNoteData = {};
          List<DocumentSnapshot<Map<String, dynamic>>> friendNotes = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              if (doc.id == _currentUid) {
                myNoteData = doc.data();
              } else {
                friendNotes.add(doc);
              }
            }
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 1 + friendNotes.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                String myNoteText = myNoteData['text'] ?? '';
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(_currentUid).get(),
                  builder: (context, uSnap) {
                    String myPic = '';
                    if (uSnap.hasData && uSnap.data?.data() != null) {
                      myPic = (uSnap.data!.data() as Map<String, dynamic>)['photoUrl'] ?? '';
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateNoteScreen(currentNote: myNoteText)),
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                CustomAvatar(radius: 30, avatarUrl: myPic),
                                Positioned(
                                  top: -12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black, width: 1.5),
                                    ),
                                    child: Text(
                                      myNoteText.isNotEmpty ? myNoteText : 'Ghi chú...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ghi chú của bạn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              var nDoc = friendNotes[index - 1];
              var nData = nDoc.data()!;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(nDoc.id).get(),
                builder: (context, uSnap) {
                  if (!uSnap.hasData) return const SizedBox.shrink();
                  var uData = uSnap.data?.data() as Map<String, dynamic>? ?? {};

                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            CustomAvatar(radius: 30, avatarUrl: uData['photoUrl'] ?? ''),
                            Positioned(
                              top: -12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF262626),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Text(
                                  nData['text'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          uData['username'] ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}