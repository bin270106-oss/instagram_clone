import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_avatar.dart';
import 'profile_screen.dart';

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({super.key});

  @override
  State<DiscoverPeopleScreen> createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _suggestedUsers = [];
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // Lấy danh sách user từ Firebase (Giới hạn 30 người)
      var snap = await FirebaseFirestore.instance.collection('users').limit(30).get();
      List<Map<String, dynamic>> users = [];
      for (var doc in snap.docs) {
        if (doc.id != currentUserId) {
          var data = doc.data();
          data['uid'] = doc.id; // Lưu lại UID để bấm vào là chuyển trang được
          users.add(data);
        }
      }
      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Khám phá mọi người', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                var user = _suggestedUsers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // BẤM VÀO AVATAR CHUYỂN QUA PROFILE (HÌNH 2)
                  leading: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(uid: user['uid']))),
                    child: CustomAvatar(radius: 26, avatarUrl: user['photoUrl'] ?? ''),
                  ),
                  // BẤM VÀO TÊN CŨNG CHUYỂN QUA PROFILE
                  title: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(uid: user['uid']))),
                    child: Text(user['username'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  subtitle: Text(user['name'] ?? 'Gợi ý cho bạn', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Xử lý Follow người này
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Theo dõi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      // NÚT XÓA KHỎI DANH SÁCH GỢI Ý
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          setState(() {
                            _suggestedUsers.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}