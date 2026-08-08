// lib/widgets/custom_avatar.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String username;

  const CustomAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 18,
    this.username = 'User',
  });

  @override
  Widget build(BuildContext context) {
    // 1. Tạo link avatar tự động theo tên nếu link bị hỏng hoặc chứa toppng
    String defaultAvatar = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=random&color=fff';
    
    String finalUrl = (avatarUrl == null || avatarUrl!.isEmpty || avatarUrl!.contains('toppng.com'))
        ? defaultAvatar
        : avatarUrl!;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: finalUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
              ),
            ),
          ),
          // Nếu link ảnh bị lỗi 403 -> Tự động chuyển sang Avatar chữ viết tắt
          errorWidget: (context, url, error) => Image.network(
            defaultAvatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius, color: Colors.white),
          ),
        ),
      ),
    );
  }
}