import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_avatar.dart';

class CreateNoteScreen extends StatefulWidget {
  final String currentNote;
  const CreateNoteScreen({super.key, this.currentNote = ''});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final TextEditingController _noteController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.currentNote;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Lưu Ghi chú lên Firestore
  void _shareNote() async {
    String text = _noteController.text.trim();
    setState(() => _isSaving = true);

    try {
      if (text.isEmpty) {
        await FirebaseFirestore.instance.collection('notes').doc(_currentUid).delete();
      } else {
        await FirebaseFirestore.instance.collection('notes').doc(_currentUid).set({
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Lỗi lưu ghi chú: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // KÍCH HOẠT ĐỂ NÚT CHIA SẺ TRỒI LÊN THEO BÀN PHÍM
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ghi chú mới',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // Đã gỡ nút chia sẻ ở góc trên để dời xuống góc dưới
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // BỌT SUY NGHĨ TRÊN ĐẦU AVATAR
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(_currentUid).get(),
                      builder: (context, snapshot) {
                        String myPic = '';
                        if (snapshot.hasData && snapshot.data?.data() != null) {
                          myPic = (snapshot.data!.data() as Map<String, dynamic>)['photoUrl'] ?? '';
                        }

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              // KHUNG NHẬP TỰ ĐỘNG GIÃN NỞ THEO KÍ TỰ
                              child: TextField(
                                controller: _noteController,
                                maxLength: 100, // CHỈ ĐƯỢC NHẬP TỐI ĐA 100 KÝ TỰ
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Ẩn biến đếm đi
                                textAlign: TextAlign.center,
                                minLines: 1, // Mặc định thu nhỏ 1 dòng
                                maxLines: 5, // Dài tối đa 5 dòng mới cho cuộn
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Chia sẻ suy nghĩ...',
                                  hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(20, 10),
                              painter: TrianglePainter(),
                            ),
                            const SizedBox(height: 8),
                            CustomAvatar(radius: 45, avatarUrl: myPic),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // KHỐI CHIA SẺ NẰM BÊN DƯỚI (TỰ NHẢY LÊN KHI MỞ BÀN PHÍM)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
                color: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cụm trái: Icon bạn bè + Chữ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF262626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chia sẻ với bạn bè',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),

                  // Cụm phải: Nút Chia sẻ bo góc xanh dương đẹp
                  GestureDetector(
                    onTap: _isSaving ? null : _shareNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Chia sẻ',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vẽ đuôi nhọn cho bọt suy nghĩ
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = const Color(0xFF262626);
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}