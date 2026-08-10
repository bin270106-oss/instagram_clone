import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_avatar.dart';
import '../screens/add_story_screen.dart';
import '../screens/story_view_screen.dart';

class StoryBar extends StatelessWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      // Lắng nghe đồng thời cả users và stories trên Firestore
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('stories').snapshots(),
        builder: (context, storySnapshot) {
          if (!storySnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          var allStories = storySnapshot.data!.docs;
          // Lọc các story trong vòng 24h (hoặc lấy tất cả tùy ní)
          // Lấy danh sách các UID có đăng story
          List<String> uidsWithStory = allStories
              .map((doc) => doc.data()['uid'].toString())
              .toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return Container();

              var users = userSnapshot.data!.docs;
              var myDoc = users.where((doc) => doc.id == currentUid).toList();
              var otherDocs = users
                  .where((doc) => doc.id != currentUid)
                  .toList();

              bool iHaveStory = uidsWithStory.contains(currentUid);

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 1 + otherDocs.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // --- STORY CỦA CHÍNH BẠN ---
                    String myPic = myDoc.isNotEmpty
                        ? (myDoc.first.data()['photoUrl'] ?? '')
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (iHaveStory) {
                            var userStories = allStories.where((doc) => doc.data()['uid'] == currentUid).toList();
                            List<Map<String, dynamic>> listStories = userStories.map((doc) {
                              var data = Map<String, dynamic>.from(doc.data() as Map);
                              data['storyId'] = doc.id;
                              return data;
                            }).toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoryViewScreen(
                                  stories: listStories, // Truyền danh sách tin
                                  initialIndex: 0,      // Xem từ tin đầu tiên
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddStoryScreen()),
                            );
                          }
                        },
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                iHaveStory
                                    ? Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFBAA47),
                                              Color(0xFFD91A46),
                                              Color(0xFFA60F92),
                                            ],
                                            begin: Alignment.bottomLeft,
                                            end: Alignment.topRight,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CustomAvatar(
                                            radius: 26,
                                            avatarUrl: myPic,
                                          ),
                                        ),
                                      )
                                    : CustomAvatar(
                                        radius: 28,
                                        avatarUrl: myPic,
                                      ),

                                // Hiện dấu cộng nếu chưa có story
                                if (!iHaveStory)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0095F6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tin của bạn',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // --- STORY CỦA BẠN BÈ ---
                  var friendDoc = otherDocs[index - 1];
                  var friendData = friendDoc.data();
                  String friendUid = friendDoc.id;
                  bool friendHasStory = uidsWithStory.contains(friendUid);

                  // Nếu bạn bè không có story thì có thể ẩn đi hoặc hiển thị mờ tùy ní,
                  // nhưng chuẩn Instagram là chỉ hiện những ai có story hoặc hiện hết nhưng đổi viền.
                  // Ở đây tui làm theo kiểu hiện viền Gradient nếu có story:
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      // KHI BẤM VÀO TIN CỦA BẠN BÈ
                      onTap: friendHasStory ? () {
                        // Khai báo đúng biến fStoryData
                        var userStories = allStories.where((doc) => doc.data()['uid'] == friendUid).toList();
                        List<Map<String, dynamic>> listStories = userStories.map((doc) {
                          var data = Map<String, dynamic>.from(doc.data() as Map);
                          data['storyId'] = doc.id;
                          return data;
                        }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryViewScreen(
                              stories: listStories,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      } : null,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: friendHasStory
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFBAA47),
                                        Color(0xFFD91A46),
                                        Color(0xFFA60F92),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                    )
                                  : null,
                              color: friendHasStory ? null : Colors.grey[800],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: CustomAvatar(
                                radius: 26,
                                avatarUrl: friendData['photoUrl'] ?? '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 68,
                            child: Text(
                              friendData['username'] ?? 'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
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
