import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpamRequestsScreen extends StatelessWidget {
  const SpamRequestsScreen({super.key});

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
          'Spam',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Các tin nhắn bị nghi ngờ là tin nhắn rác hoặc lừa đảo sẽ xuất hiện ở đây.',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.5, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Text('Không có tin nhắn spam nào', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}