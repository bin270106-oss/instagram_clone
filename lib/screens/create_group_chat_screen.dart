import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_avatar.dart';

class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<String> _selectedUids = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // Tạo nhóm chat trên Firestore
  void _createGroup() async {
    if (_selectedUids.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 2 thành viên để tạo nhóm!')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      List<String> members = [_currentUid, ..._selectedUids];
      String groupName = _groupNameController.text.trim().isEmpty
          ? 'Nhóm ${_selectedUids.length + 1} người'
          : _groupNameController.text.trim();

      await FirebaseFirestore.instance.collection('chats').add({
        'isGroup': true,
        'groupName': groupName,
        'groupImage': '',
        'users': members,
        'lastMessage': 'Đã tạo nhóm chat',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo nhóm "$groupName" thành công!')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi tạo nhóm: $e');
    }

    if (mounted) setState(() => _isCreating = false);
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
          'Tạo nhóm chat',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _selectedUids.length >= 2 && !_isCreating ? _createGroup : null,
            child: Text(
              'Tạo',
              style: GoogleFonts.inter(
                color: _selectedUids.length >= 2 ? const Color(0xFF0095F6) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ô NHẬP TÊN NHÓM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _groupNameController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Đặt tên nhóm (không bắt buộc)',
                  hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0095F6))),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // DANH SÁCH BẠN BÈ ĐỂ TÍCH CHỌN
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  var users = snapshot.data?.docs.where((doc) => doc.id != _currentUid).toList() ?? [];

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var uData = users[index].data();
                      String uId = users[index].id;
                      bool isSelected = _selectedUids.contains(uId);

                      return CheckboxListTile(
                        activeColor: const Color(0xFF0095F6),
                        checkColor: Colors.white,
                        value: isSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedUids.add(uId);
                            } else {
                              _selectedUids.remove(uId);
                            }
                          });
                        },
                        secondary: CustomAvatar(radius: 20, avatarUrl: uData['photoUrl'] ?? ''),
                        title: Text(
                          uData['name'] ?? uData['username'] ?? 'User',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '@${uData['username'] ?? ''}',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
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