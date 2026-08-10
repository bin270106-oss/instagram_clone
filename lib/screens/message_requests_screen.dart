import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'spam_requests_screen.dart';

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yêu cầu tin nhắn',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // MỤC SPAM CHUYỂN SANG HÌNH 4
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.white, size: 26),
              title: Text('Spam', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('0', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              onTap: () {
                // CHUYỂN SANG HÌNH 4: SPAM REQUESTS
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpamRequestsScreen()),
                );
              },
            ),
            const Divider(color: Colors.white12),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Mở cuộc trò chuyện để xem thêm thông tin về người gửi. Họ sẽ không biết bạn đã xem cho đến khi bạn chấp nhận yêu cầu.',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.5, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              child: Center(
                child: Text('Không có yêu cầu tin nhắn nào', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}