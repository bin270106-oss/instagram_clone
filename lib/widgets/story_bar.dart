import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_avatar.dart';

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
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          var users = snapshot.data!.docs;
          // Tách user hiện tại lên đầu
          var myDoc = users.where((doc) => doc.id == currentUid).toList();
          var otherDocs = users.where((doc) => doc.id != currentUid).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 1 + otherDocs.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                // STORY CỦA BẠN (CÓ DẤU CONG PLUS)
                String myPic = myDoc.isNotEmpty ? (myDoc.first.data()['photoUrl'] ?? '') : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CustomAvatar(radius: 28, avatarUrl: myPic),
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
                                child: const Icon(Icons.add, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tin của bạn',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }

              // STORY CỦA BẠN BÈ (VIỀN GRADIENT CAM-HỒNG INSTAGRAM)
              var uData = otherDocs[index - 1].data();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFBAA47), // Cam sáng
                            Color(0xFFD91A46), // Hồng cam
                            Color(0xFFA60F92), // Tím hồng
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
                        child: CustomAvatar(radius: 26, avatarUrl: uData['photoUrl'] ?? ''),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        uData['username'] ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}